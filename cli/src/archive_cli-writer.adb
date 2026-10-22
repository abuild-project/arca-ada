-- SPDX-License-Identifier: LGPL-2.1-or-later

with Ada.Calendar;
with Ada.Calendar.Conversions;
with Ada.Containers.Indefinite_Ordered_Maps;
with Ada.Containers.Indefinite_Ordered_Sets;
with Ada.Containers.Ordered_Maps;
with Ada.Directories;
with Ada.IO_Exceptions;
with Ada.Strings.Unbounded;
with Arca.CPIO;
with Arca.TAR;
with Archive_CLI.Filesystem;
with GNAT.Directory_Operations;
with Interfaces.C;

package body Archive_CLI.Writer is
   package FS renames Archive_CLI.Filesystem;
   use Ada.Strings.Unbounded;
   use type Interfaces.Unsigned_32;
   use type Interfaces.Unsigned_64;
   use type Interfaces.Integer_64;
   use type FS.Entry_Kind;
   use type Options.Format_Kind;

   type Entry_Info is record
      Info   : FS.Metadata;
      Target : Unbounded_String;
   end record;

   package Entry_Maps is new Ada.Containers.Indefinite_Ordered_Maps
     (String, Entry_Info);
   package Directory_Sets is new Ada.Containers.Indefinite_Ordered_Sets
     (String);

   type File_Key is record
      Device, Inode : Interfaces.Unsigned_64;
   end record;

   function "<" (Left, Right : File_Key) return Boolean;
   --  Compare physical identities only for lookup, never for output order.

   function "<" (Left, Right : File_Key) return Boolean is
   begin
      return Left.Device < Right.Device or else
        (Left.Device = Right.Device and then Left.Inode < Right.Inode);
   end "<";

   -------------------------------------------------------------------------

   type Link_Group is record
      Count, Seen : Interfaces.Unsigned_32 := 0;
      Inode       : Arca.CPIO.Inode_Type := 0;
      First       : Unbounded_String;
      Info        : FS.Metadata;
   end record;

   package Group_Maps is new Ada.Containers.Ordered_Maps
     (File_Key, Link_Group);

   function Join (Parent, Name : String) return String;
   --  Join archive or absolute paths without adding duplicate root slashes.

   function Same (Left, Right : FS.Metadata) return Boolean;
   --  Compare identity and stored metadata; directory timestamps may change.

   procedure Validate
     (Info : FS.Metadata; Name : String; Config : Options.Settings);
   --  Reject unsupported nodes and format bounds before opening output.

   procedure Inventory
     (Root, Output : String; Config : Options.Settings;
      Entries : out Entry_Maps.Map; Groups : out Group_Maps.Map);
   --  Walk iteratively; all maps are owned by this sequential invocation.

   -------------------------------------------------------------------------

   function Join (Parent, Name : String) return String is
   begin
      if Parent = "" then
         return Name;
      elsif Name = "" then
         return Parent;
      elsif Parent (Parent'Last) = '/' then
         return Parent & Name;
      else
         return Parent & "/" & Name;
      end if;
   end Join;

   -------------------------------------------------------------------------

   function Same (Left, Right : FS.Metadata) return Boolean is
   begin
      if Left.Device /= Right.Device or else Left.Inode /= Right.Inode
        or else Left.Kind /= Right.Kind or else Left.Mode /= Right.Mode
        or else Left.UID /= Right.UID or else Left.GID /= Right.GID
      then
         return False;
      end if;
      if FS.Kind (Left) = FS.Directory then
         --  Private output staging can change an inventoried parent's mtime.
         return True;
      end if;
      return Left.Size = Right.Size and then Left.MTime = Right.MTime
        and then Left.MTime_NS = Right.MTime_NS
        and then Left.Major = Right.Major and then Left.Minor = Right.Minor;
   end Same;

   -------------------------------------------------------------------------

   procedure Validate
     (Info : FS.Metadata; Name : String; Config : Options.Settings)
   is
      Max_Time : constant Long_Long_Integer :=
        (if Config.Format = Options.CPIO_Format then 2 ** 32 - 1
         else 2 ** 33 - 1);
      Stamp : constant Long_Long_Integer :=
        (if Config.MTime.Present then Config.MTime.Value
         else Long_Long_Integer (Info.MTime));
      UID : constant Interfaces.Unsigned_32 :=
        (if Config.UID.Present then Config.UID.Value else Info.UID);
      GID : constant Interfaces.Unsigned_32 :=
        (if Config.GID.Present then Config.GID.Value else Info.GID);
   begin
      if FS.Kind (Info) = FS.Unsupported then
         raise Command_Error with "unsupported filesystem node: '" & Name & "'";
      end if;
      if Config.Format = Options.CPIO_Format and then Name = "TRAILER!!!" then
         --  newc readers stop at this exact name, irrespective of its type.
         raise Command_Error with "reserved CPIO name: '" & Name & "'";
      end if;
      if Stamp < 0 or else Stamp > Max_Time then
         raise Command_Error with "mtime outside format limits: '" & Name & "'";
      end if;
      if FS.Kind (Info) = FS.Regular
        and then Info.Size > Interfaces.Unsigned_64 (Max_Time)
      then
         raise Command_Error with
           "file exceeds format size limit: '" & Name & "'";
      end if;
      if Config.Format = Options.TAR_Format then
         if UID > 2 ** 21 - 1 or else GID > 2 ** 21 - 1
           or else Info.Major > 2 ** 21 - 1 or else Info.Minor > 2 ** 21 - 1
         then
            raise Command_Error with
              "owner/device metadata outside TAR limits: '" & Name & "'";
         end if;
      end if;
   end Validate;

   -------------------------------------------------------------------------

   procedure Inventory
     (Root, Output : String; Config : Options.Settings;
      Entries : out Entry_Maps.Map; Groups : out Group_Maps.Map)
   is
      Pending : Directory_Sets.Set;
      Search : GNAT.Directory_Operations.Dir_Type;
      Buffer : String (1 .. 4096);
      Last : Natural;
   begin
      Pending.Insert ("");
      while not Pending.Is_Empty loop
         declare
            Directory : constant String := Pending.First_Element;
         begin
            Pending.Delete_First;
            FS.Check_Interrupted;
            --  Ada.Directories' iterator fetches modification times through a
            --  regular-file/directory-only API. Read names, then lstat every
            --  entry ourselves so FIFOs and dangling links remain supported.
            begin
               GNAT.Directory_Operations.Open (Search, Join (Root, Directory));
            exception
               when GNAT.Directory_Operations.Directory_Error =>
                  raise Command_Error with
                    "cannot open directory: '" & Join (Root, Directory) & "'";
            end;
            loop
               FS.Check_Interrupted;
               GNAT.Directory_Operations.Read (Search, Buffer, Last);
               exit when Last = 0;
               if Last = Buffer'Last then
                  raise Command_Error with "directory entry name is too long";
               end if;
               declare
                  Base : constant String := Buffer (1 .. Last);
                  Name : constant String := Join (Directory, Base);
                  Source : constant String := Join (Root, Name);
                  Value : Entry_Info;
               begin
                  if Base /= "." and then Base /= ".." and then
                    Source /= Output
                  then
                     Value.Info := FS.Stat (Source);
                     Validate (Value.Info, Name, Config);
                     if FS.Kind (Value.Info) = FS.Directory then
                        Pending.Insert (Name);
                     elsif FS.Kind (Value.Info) = FS.Symlink then
                        Value.Target := To_Unbounded_String
                          (FS.Link_Target (Source));
                     end if;
                     Entries.Insert (Name, Value);
                  end if;
               end;
            end loop;
            GNAT.Directory_Operations.Close (Search);
         end;
      end loop;
      for Position in Entries.Iterate loop
         declare
            Name : constant String := Entry_Maps.Key (Position);
            Info : constant FS.Metadata := Entry_Maps.Element (Position).Info;
            Key : constant File_Key := (Info.Device, Info.Inode);
            Group : Link_Group;
         begin
            if FS.Kind (Info) = FS.Regular then
               if Groups.Contains (Key) then
                  Group := Groups.Element (Key);
                  if not Same (Info, Group.Info) then
                     raise Command_Error with
                       "source changed during inventory: '" & Name & "'";
                  end if;
                  if Group.Count = Interfaces.Unsigned_32'Last then
                     raise Command_Error with "too many archive hardlinks";
                  end if;
               else
                  Group.First := To_Unbounded_String (Name);
                  Group.Info := Info;
               end if;
               Group.Count := Group.Count + 1;
               Groups.Include (Key, Group);
            end if;
         end;
      end loop;
   exception
      when others =>
         if GNAT.Directory_Operations.Is_Open (Search) then
            GNAT.Directory_Operations.Close (Search);
         end if;
         raise;
   end Inventory;

   -------------------------------------------------------------------------

   procedure Create (Config : Options.Settings) is
      Root : constant String := FS.Canonical (To_String (Config.Directory));
      Output_Name : constant String := To_String (Config.Output);
      Base : constant String := Ada.Directories.Simple_Name (Output_Name);
      Parent : constant String := FS.Canonical
        (Ada.Directories.Containing_Directory (Output_Name));
      Output : constant String := Join (Parent, Base);
      Existing : FS.Metadata;
      Entries : Entry_Maps.Map;
      Groups : Group_Maps.Map;
   begin
      if Output_Name (Output_Name'Last) = '/' then
         raise Command_Error with "output must name a file, not end in '/'";
      end if;
      if FS.Kind (FS.Stat (Root)) /= FS.Directory then
         raise Command_Error with "input is not a directory: '" & Root & "'";
      end if;
      if Base = "" or else Base = "." or else Base = ".." or else
        FS.Kind (FS.Stat (Parent)) /= FS.Directory
      then
         raise Command_Error with "output needs an existing parent directory";
      end if;
      if FS.Exists (Output, Existing) then
         if not Config.Force then
            raise Command_Error with "output already exists; use --force";
         elsif FS.Kind (Existing) /= FS.Regular and then
           FS.Kind (Existing) /= FS.Symlink
         then
            raise Command_Error with "output is not a regular file or symlink";
         end if;
      end if;
      Inventory (Root, Output, Config, Entries, Groups);
      declare
         Guard : constant FS.Transaction := FS.Begin_Output (Parent);
         CPIO : Arca.CPIO.CPIO_Archive_Type;
         TAR : Arca.TAR.TAR_Archive_Type;

         procedure Emit (Name : String; Value : Entry_Info);
         --  Recheck identity and emit one explicit entry through the library.

         procedure Emit (Name : String; Value : Entry_Info) is
            Info : constant FS.Metadata := Value.Info;
            Source : constant String := Join (Root, Name);
            UID : constant Interfaces.Unsigned_32 :=
              (if Config.UID.Present then Config.UID.Value else Info.UID);
            GID : constant Interfaces.Unsigned_32 :=
              (if Config.GID.Present then Config.GID.Value else Info.GID);
            Stamp : constant Ada.Calendar.Time :=
              Ada.Calendar.Conversions.To_Ada_Time
                (Interfaces.C.long
                   (if Config.MTime.Present then Config.MTime.Value
                    else Long_Long_Integer (Info.MTime)));
            Key : constant File_Key := (Info.Device, Info.Inode);
            Group : Link_Group;
         begin
            FS.Check_Interrupted;
            if not Same (Info, FS.Stat (Source)) then
               raise Command_Error with "source changed: '" & Name & "'";
            end if;
            if FS.Kind (Info) = FS.Regular then
               Group := Groups.Element (Key);
               if Config.Format = Options.CPIO_Format and then Group.Seen = 0
               then
                  Group.Inode := Arca.CPIO.CPIO_Get_Next_Inode (CPIO);
               end if;
               Group.Seen := Group.Seen + 1;
               if Config.Format = Options.CPIO_Format then
                  if Group.Seen = Group.Count then
                     Arca.CPIO.CPIO_Make_File
                       (CPIO, Name, Source, Info.Mode, UID, GID,
                        Group.Count, Group.Inode, Stamp);
                  else
                     Arca.CPIO.CPIO_Make_Link
                       (CPIO, Name, Info.Mode, UID, GID,
                        Group.Count, Group.Inode, Stamp);
                  end if;
               elsif Group.Seen = 1 then
                  Arca.TAR.TAR_Make_File
                    (TAR, Name, Source, Info.Mode, UID, GID, Stamp);
               else
                  Arca.TAR.TAR_Make_Hardlink
                    (TAR, Name, To_String (Group.First), Info.Mode,
                     UID, GID, Stamp);
               end if;
               Groups.Replace (Key, Group);
            elsif Config.Format = Options.CPIO_Format then
               case FS.Kind (Info) is
                  when FS.Directory =>
                     Arca.CPIO.CPIO_Make_Directory
                       (CPIO, Name, Info.Mode, UID, GID, Stamp);
                  when FS.Symlink =>
                     Arca.CPIO.CPIO_Make_Symlink
                       (CPIO, Name, To_String (Value.Target), Info.Mode,
                        UID, GID, Stamp);
                  when FS.FIFO =>
                     Arca.CPIO.CPIO_Make_FIFO
                       (CPIO, Name, Info.Mode, UID, GID, Stamp);
                  when FS.Block_Device =>
                     Arca.CPIO.CPIO_Make_Blockdevice
                       (CPIO, Name, Info.Mode, UID, GID,
                        Info.Major, Info.Minor, Stamp);
                  when FS.Char_Device =>
                     Arca.CPIO.CPIO_Make_Chardevice
                       (CPIO, Name, Info.Mode, UID, GID,
                        Info.Major, Info.Minor, Stamp);
                  when others => raise Command_Error with "unsupported node";
               end case;
            else
               case FS.Kind (Info) is
                  when FS.Directory =>
                     Arca.TAR.TAR_Make_Directory
                       (TAR, Name, Info.Mode, UID, GID, Stamp);
                  when FS.Symlink =>
                     Arca.TAR.TAR_Make_Symlink
                       (TAR, Name, To_String (Value.Target), Info.Mode,
                        UID, GID, Stamp);
                  when FS.FIFO =>
                     Arca.TAR.TAR_Make_FIFO
                       (TAR, Name, Info.Mode, UID, GID, Stamp);
                  when FS.Block_Device =>
                     Arca.TAR.TAR_Make_Block_Device
                       (TAR, Name, Info.Mode, UID, GID,
                        Info.Major, Info.Minor, Stamp);
                  when FS.Char_Device =>
                     Arca.TAR.TAR_Make_Char_Device
                       (TAR, Name, Info.Mode, UID, GID,
                        Info.Major, Info.Minor, Stamp);
                  when others => raise Command_Error with "unsupported node";
               end case;
            end if;
         exception
            when Arca.CPIO.File_Not_Found | Arca.TAR.File_Not_Found =>
               raise Command_Error with "source disappeared: '" & Name & "'";
            when Arca.CPIO.File_Read_Error | Arca.TAR.File_Read_Error =>
               raise Command_Error with
                 "source changed or could not be read: '" & Name & "'";
            when Ada.IO_Exceptions.Name_Error | Ada.IO_Exceptions.Use_Error |
                 Ada.IO_Exceptions.Device_Error | Ada.IO_Exceptions.End_Error =>
               raise Command_Error with
                 "cannot read or emit entry: '" & Name & "'";
         end Emit;
      begin
         FS.Check_Interrupted;
         if Config.Format = Options.CPIO_Format then
            Arca.CPIO.CPIO_Create (CPIO, FS.Staging_Name (Guard));
         else
            Arca.TAR.TAR_Create (TAR, FS.Staging_Name (Guard));
         end if;
         for Position in Entries.Iterate loop
            Emit (Entry_Maps.Key (Position), Entry_Maps.Element (Position));
         end loop;
         FS.Check_Interrupted;
         if Config.Format = Options.CPIO_Format then
            Arca.CPIO.CPIO_Close (CPIO);
         else
            Arca.TAR.TAR_Close (TAR);
         end if;
         FS.Publish (Guard, Output, Config.Force);
      end;
   end Create;
end Archive_CLI.Writer;
