-- SPDX-License-Identifier: LGPL-2.1-or-later

with Ada.Calendar;
with Ada.Calendar.Formatting;
with Ada.Command_Line;
with Ada.Directories;
with Ada.Exceptions;
with Ada.IO_Exceptions;
with Ada.Strings.Unbounded;
with Arca.CPIO;
with Interfaces;
with Test_Support;

--  Emit deterministic test archives and check the writer's error contracts.
procedure CPIO_Driver is

   use Arca.CPIO;
   use Interfaces;
   use Test_Support;

   Mode : constant String := Ada.Command_Line.Argument (1);
   Work : constant String := Ada.Command_Line.Argument (2);
   Fixed_Time : constant Ada.Calendar.Time :=
     Ada.Calendar.Formatting.Time_Of
       (2000, 1, 1, Seconds => 0.0, Time_Zone => 0);

   procedure Write_Entries (Name : String);
   --  Emit every supported entry kind, hardlinks and a multi-buffer payload.

   procedure Check_Errors;
   --  Pin unopened, source, size and timestamp failures before continuing.

   procedure Check_Parallel;
   --  Emit independent archives from tasks with bounded worker stacks.

   procedure Check_Lifetime;
   --  Check descriptor cleanup when callers omit Close or leave by exception.

   -------------------------------------------------------------------------

   procedure Write_Entries (Name : String) is
      Archive : CPIO_Archive_Type;
      Link_Inode : Inode_Type;
      Max_Time : constant Ada.Calendar.Time :=
        Ada.Calendar.Formatting.Time_Of
          (2106, 2, 7, Seconds => 23_295.0, Time_Zone => 0);
   begin
      CPIO_Create (Archive, Name);
      CPIO_Make_Directory (Archive, "dir", 8#750#, 17, 23, Fixed_Time);
      CPIO_Make_File
        (Archive, "dir/payload", Work & "/payload.bin", 8#640#, 17, 23,
         1, CPIO_Get_Next_Inode (Archive), Fixed_Time);
      CPIO_Make_File
        (Archive, "empty", Work & "/empty.bin", 8#600#, 17, 23,
         1, CPIO_Get_Next_Inode (Archive), Fixed_Time);
      Link_Inode := CPIO_Get_Next_Inode (Archive);
      CPIO_Make_Link
        (Archive, "hard-first", 8#640#, 17, 23, 2, Link_Inode, Fixed_Time);
      CPIO_Make_File
        (Archive, "hard-last", Work & "/payload.bin", 8#640#, 17, 23,
         2, Link_Inode, Fixed_Time);
      CPIO_Make_Symlink
        (Archive, "symlink", "dir/payload", 8#777#, 17, 23, Fixed_Time);
      CPIO_Make_Symlink
        (Archive, "long-symlink", (1 .. 300 => 'x'), 8#777#, 17, 23,
         Fixed_Time);
      CPIO_Make_FIFO (Archive, "fifo", 8#640#, 17, 23, Fixed_Time);
      CPIO_Make_Blockdevice
        (Archive, "block", 8#006#, 17, 23, 21, 5, Fixed_Time);
      CPIO_Make_Chardevice
        (Archive, "character", 8#772#, 17, 23, 5, 12, Fixed_Time);
      CPIO_Make_Directory
        (Archive, "max-metadata", 8#700#, Unsigned_32'Last,
         Unsigned_32'Last, Max_Time);
      CPIO_Make_Directory
        (Archive, "epoch", 8#700#, 17, 23,
         Ada.Calendar.Formatting.Time_Of
           (1970, 1, 1, Seconds => 0.0, Time_Zone => 0));
      CPIO_Close (Archive);
   end Write_Entries;

   -------------------------------------------------------------------------

   procedure Check_Errors is
      Archive : CPIO_Archive_Type;
      Stamp : Ada.Calendar.Time := Fixed_Time;
      Source : constant String := Work & "/missing.bin";
      Operation : Positive := 1;

      procedure Close_Unopened;
      --  Attempt to close the unopened or already closed writer.

      procedure Add_Directory;
      --  Exercise timestamp validation using the selected Stamp.

      procedure Missing_Source;
      --  Attempt to add a nonexistent regular source file.

      procedure Oversized_Source;
      --  Reject the first payload size that does not fit a newc header.

      procedure Recreate_Open;
      --  Reject a second Create without corrupting existing archive state.

      procedure Add_Unopened;
      --  Verify that every remaining entry operation requires an open writer.

      procedure Close_Unopened is
      begin
         CPIO_Close (Archive);
      end Close_Unopened;

      ----------------------------------------------------------------------

      procedure Add_Directory is
      begin
         CPIO_Make_Directory (Archive, "rejected", 8#700#, 0, 0, Stamp);
      end Add_Directory;

      ----------------------------------------------------------------------

      procedure Missing_Source is
      begin
         CPIO_Make_File
           (Archive, "missing", Source, 8#600#, 0, 0, 1, 900, Fixed_Time);
      end Missing_Source;

      ----------------------------------------------------------------------

      procedure Oversized_Source is
      begin
         CPIO_Make_File
           (Archive, "oversized", Work & "/oversized.bin", 8#600#,
            0, 0, 1, 900, Fixed_Time);
      end Oversized_Source;

      ----------------------------------------------------------------------

      procedure Recreate_Open is
      begin
         CPIO_Create (Archive, Work & "/replacement.cpio");
      end Recreate_Open;

      ----------------------------------------------------------------------

      procedure Add_Unopened is
      begin
         case Operation is
            when 1 =>
               CPIO_Make_File
                 (Archive, "file", Work & "/payload.bin", 0, 0, 0,
                  1, 721, Fixed_Time);
            when 2 =>
               CPIO_Make_Link (Archive, "link", 0, 0, 0, 2, 721, Fixed_Time);
            when 3 =>
               CPIO_Make_Symlink
                 (Archive, "symlink", "target", 0, 0, 0, Fixed_Time);
            when 4 =>
               CPIO_Make_FIFO (Archive, "fifo", 0, 0, 0, Fixed_Time);
            when 5 =>
               CPIO_Make_Blockdevice
                 (Archive, "block", 0, 0, 0, 1, 2, Fixed_Time);
            when others =>
               CPIO_Make_Chardevice
                 (Archive, "character", 0, 0, 0, 1, 2, Fixed_Time);
         end case;
      end Add_Unopened;
   begin
      Expect_Failure
        (Close_Unopened'Access, CPIO_Not_Initialized'Identity,
         "CPIO_Close called on uninitialized archive");
      Expect_Failure
        (Add_Directory'Access, CPIO_Not_Initialized'Identity,
         "CPIO_Make_Directory called on uninitialized archive");
      for Index in 1 .. 6 loop
         Operation := Index;
         Expect_Failure
           (Add_Unopened'Access, CPIO_Not_Initialized'Identity,
            "called on uninitialized archive");
      end loop;

      CPIO_Create (Archive, Work & "/errors.cpio");
      if Mode = "state" then
         CPIO_Make_Directory
           (Archive, "before-recreate", 8#700#, 0, 0, Fixed_Time);
         Expect_Failure
           (Recreate_Open'Access, Ada.IO_Exceptions.Status_Error'Identity,
            "CPIO_Create called on an open archive");
      end if;
      Expect_Failure
        (Missing_Source'Access, File_Not_Found'Identity,
         "Could not locate source file '");
      Expect_Failure
        (Oversized_Source'Access, File_Too_Big'Identity,
         "newc CPIO supports payloads up to 4 GiB - 1 byte");
      Stamp := Ada.Calendar.Formatting.Time_Of
        (1969, 12, 31, Seconds => 86_399.0, Time_Zone => 0);
      Expect_Failure
        (Add_Directory'Access, Unsupported_Metadata'Identity,
         "CPIO mtime outside supported UNIX timestamp range");
      Stamp := Ada.Calendar.Formatting.Time_Of
        (2106, 2, 7, Seconds => 23_296.0, Time_Zone => 0);
      Expect_Failure
        (Add_Directory'Access, Unsupported_Metadata'Identity,
         "CPIO mtime outside supported UNIX timestamp range");
      CPIO_Make_Directory (Archive, "after-errors", 8#700#, 0, 0, Fixed_Time);
      CPIO_Close (Archive);
      Expect_Failure
        (Close_Unopened'Access, CPIO_Not_Initialized'Identity,
         "CPIO_Close called on uninitialized archive");
   end Check_Errors;

   -------------------------------------------------------------------------

   procedure Check_Parallel is
      task type Writer is
         pragma Storage_Size (131_072);
         entry Start (Number : Positive);
         entry Finish
           (Success : out Boolean;
            Detail : out Ada.Strings.Unbounded.Unbounded_String);
      end Writer;

      task body Writer is
         Index : Positive;
         OK : Boolean := True;
         Error_Info : Ada.Strings.Unbounded.Unbounded_String;
      begin
         accept Start (Number : Positive) do
            Index := Number;
         end Start;
         begin
            Write_Entries (Work & "/parallel" & Index'Image & ".cpio");
         exception
            when Error : others =>
               Error_Info := Ada.Strings.Unbounded.To_Unbounded_String
                 (Ada.Exceptions.Exception_Information (Error));
               OK := False;
         end;
         accept Finish
           (Success : out Boolean;
            Detail : out Ada.Strings.Unbounded.Unbounded_String)
         do
            Success := OK;
            Detail := Error_Info;
         end Finish;
      end Writer;

      Writers : array (1 .. 8) of Writer;
      All_OK : Boolean := True;
      Last_Error : Ada.Strings.Unbounded.Unbounded_String;
   begin
      for Index in Writers'Range loop
         Writers (Index).Start (Index);
      end loop;
      for Index in Writers'Range loop
         declare
            OK : Boolean;
            Detail : Ada.Strings.Unbounded.Unbounded_String;
         begin
            Writers (Index).Finish (OK, Detail);
            All_OK := All_OK and OK;
            if not OK then
               Last_Error := Detail;
            end if;
         end;
      end loop;
      Check
        (All_OK, "Parallel writer failed: " &
         Ada.Strings.Unbounded.To_String (Last_Error));
   end Check_Parallel;

   -------------------------------------------------------------------------

   procedure Check_Lifetime is
      Before : constant Natural := Open_Descriptor_Count;
      Caller_Abort : exception;
   begin
      for Index in 1 .. 40 loop
         begin
            declare
               Archive : CPIO_Archive_Type;
            begin
               CPIO_Create
                 (Archive, Work & "/unfinished" & Index'Image & ".cpio");
               if Index mod 3 = 0 then
                  CPIO_Make_File
                    (Archive, "missing", Work & "/missing.bin", 0, 0, 0,
                     1, 721, Fixed_Time);
               elsif Index mod 3 = 1 then
                  raise Caller_Abort;
               end if;
            end;
         exception
            when Caller_Abort | File_Not_Found => null;
         end;
      end loop;
      Check
        (Open_Descriptor_Count = Before,
         "Omitted Close leaked archive descriptors");
      declare
         task type Owned_Writer (Number : Positive) is
            entry Ready;
            entry Complete;
         end Owned_Writer;

         task body Owned_Writer is
            Archive : CPIO_Archive_Type;
         begin
            CPIO_Create
              (Archive, Work & "/task-output" & Number'Image & ".cpio");
            accept Ready;
            accept Complete;
         end Owned_Writer;

         Normal_Exit : Owned_Writer (1);
         Abandoned : Owned_Writer (2);
      begin
         --  A normal task exit is the positive control for the same owner.
         Normal_Exit.Ready;
         Normal_Exit.Complete;
         Abandoned.Ready;
         abort Abandoned;
      end;
      for Index in 1 .. 2 loop
         Check
           (not Ada.Directories.Exists
              (Work & "/task-output" & Index'Image & ".cpio"),
            "Task exit retained an unfinished archive");
      end loop;
      Check
        (Open_Descriptor_Count = Before,
         "Task abort leaked archive descriptors");
      for Index in 1 .. 40 loop
         Check
           (not Ada.Directories.Exists
              (Work & "/unfinished" & Index'Image & ".cpio"),
            "Omitted Close retained an unfinished archive");
      end loop;
   end Check_Lifetime;

begin
   if Mode = "entries" then
      Write_Entries (Work & "/entries.cpio");
   elsif Mode = "empty" then
      declare
         Archive : CPIO_Archive_Type;
      begin
         CPIO_Create (Archive, Work & "/empty.cpio");
         CPIO_Close (Archive);
      end;
   elsif Mode = "errors" or else Mode = "state" then
      Check_Errors;
   elsif Mode = "parallel" then
      Check_Parallel;
   elsif Mode = "lifetime" then
      Check_Lifetime;
   else
      raise Program_Error with "Unknown CPIO scenario: " & Mode;
   end if;
end CPIO_Driver;
