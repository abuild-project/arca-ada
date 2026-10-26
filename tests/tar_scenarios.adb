--  SPDX-License-Identifier: GPL-2.0-or-later

with Ada.Calendar;
with Ada.Calendar.Formatting;
with Ada.Directories;
with Ada.Exceptions;
with Ada.IO_Exceptions;
with Ada.Strings.Unbounded;
with Arca.TAR;
with Interfaces;
with Test_Support;

package body TAR_Scenarios is

   procedure Run (Mode, Work : String)
   is

      use Arca.TAR;
      use Interfaces;
      use Test_Support;
      use type Ada.Exceptions.Exception_Id;

      Fixed_Time : constant Ada.Calendar.Time :=
        Ada.Calendar.Formatting.Time_Of
          (2000, 1, 1, Seconds => 0.0, Time_Zone => 0);
      Epoch : constant Ada.Calendar.Time :=
        Ada.Calendar.Formatting.Time_Of
          (1970, 1, 1, Seconds => 0.0, Time_Zone => 0);
      Max_Time : constant Ada.Calendar.Time :=
        Ada.Calendar.Formatting.Time_Of
          (2242, 3, 16, Seconds => 46_591.0, Time_Zone => 0);
      Max_Field   : constant Unsigned_32 := 2 ** 21 - 1;
      Deep_Prefix : constant String :=
        "directory/directory/directory/directory/" &
        "directory/directory/directory/directory/" &
        "directory/directory/directory/directory/middle";

      procedure Write_Entries (Name : String);
      --  Emit all entry kinds, exact-fit fields and both GNU metadata kinds.

      procedure Write_Golden;
      --  Emit the exact historical GNU ustar subset with its original payload.

      procedure Write_Edges;
      --  Exercise padding, nondefault string bounds and long metadata sizes.

      procedure Write_Aligned;
      --  Emit a block-aligned payload spanning more than one copy buffer.

      procedure Write_Owners;
      --  Emit numeric owner/group IDs absent from the reference image's users.

      procedure Check_Errors;
      --  Check exceptions, explicit messages and short-header recovery.

      procedure Check_Lifetime;
      --  Check cleanup after omitted closes, failed adds and task termination.

      procedure Check_Parallel;
      --  Write independent archives on bounded worker stacks.

      procedure Expect_Error
        (Action  : not null access procedure;
         Kind    : Ada.Exceptions.Exception_Id;
         Message : String := "");
      --  Require the original exception and explicitly supplied messages.

      -------------------------------------------------------------------------

      procedure Expect_Error
        (Action  : not null access procedure;
         Kind    : Ada.Exceptions.Exception_Id;
         Message : String := "")
      is
         Raised : Boolean := False;
      begin
         begin
            Action.all;
         exception
            when Error : others =>
               Check
                 (Ada.Exceptions.Exception_Identity (Error) = Kind,
                  Ada.Exceptions.Exception_Information (Error));
               if Message /= "" then
                  Check
                    (Ada.Exceptions.Exception_Message (Error) = Message,
                     "Unexpected TAR exception message: " &
                     Ada.Exceptions.Exception_Message (Error));
               end if;
               Raised := True;
         end;
         Check (Raised, "Expected TAR exception was not raised");
      end Expect_Error;

      -------------------------------------------------------------------------

      procedure Write_Entries (Name : String)
      is
         Archive : TAR_Archive_Type;
      begin
         TAR_Create (Archive, Name);
         TAR_Make_Directory (Archive, "dir", 8#750#, 17, 23, Fixed_Time);
         TAR_Make_File
           (Archive, "dir/payload", Work & "/payload.bin", 8#100640#,
            17, 23, Fixed_Time);
         TAR_Make_File
           (Archive, "empty", Work & "/empty.bin", 8#600#, 17, 23, Fixed_Time);
         TAR_Make_Hardlink
           (Archive, "hard", "dir/payload", 8#640#, 17, 23, Fixed_Time);
         TAR_Make_Symlink
           (Archive, "symlink", "dir/payload", 8#777#, 17, 23, Fixed_Time);
         TAR_Make_Symlink
           (Archive, "long-symlink", (1 .. 300 => 'x'), 8#777#,
            17, 23, Fixed_Time);
         TAR_Make_FIFO (Archive, "fifo", 8#640#, 17, 23, Fixed_Time);
         TAR_Make_Block_Device
           (Archive, "block", 8#006#, 17, 23, 21, 5, Fixed_Time);
         TAR_Make_Char_Device
           (Archive, "character", 8#772#, 17, 23, 5, 12, Fixed_Time);
         TAR_Make_Char_Device
           (Archive, "max-metadata", 8#177777#, Max_Field, Max_Field,
            Max_Field, Max_Field, Max_Time);
         TAR_Make_Directory (Archive, "epoch", 8#700#, 17, 23, Epoch);
         TAR_Make_File
           (Archive, (1 .. 155 => 'a') & "/" & (1 .. 100 => 'p'),
            Work & "/tiny.bin", 8#644#, 17, 23, Fixed_Time);
         TAR_Make_File
           (Archive, (1 .. 101 => 'n'), Work & "/tiny.bin", 8#644#,
            17, 23, Fixed_Time);
         TAR_Make_File
           (Archive, (1 .. 100 => 'e'), Work & "/tiny.bin", 8#644#,
            17, 23, Fixed_Time);
         TAR_Make_Symlink
           (Archive, "exact-target", (1 .. 100 => 't'), 8#777#,
            17, 23, Fixed_Time);
         TAR_Make_Hardlink
           (Archive, (1 .. 120 => 'h'), (1 .. 101 => 'n'), 8#644#,
            17, 23, Fixed_Time);
         TAR_Close (Archive);
      end Write_Entries;

      -------------------------------------------------------------------------

      procedure Write_Golden
      is
         Archive : TAR_Archive_Type;
      begin
         TAR_Create (Archive, Work & "/golden.tar");
         TAR_Make_File
           (Archive, "regular_file", Work & "/regular_file", 8#644#,
            0, 0, Fixed_Time);
         TAR_Make_Directory (Archive, "directory", 8#755#, 0, 0, Fixed_Time);
         TAR_Make_Symlink
           (Archive, "symbolic_link", "regular_file", 8#777#,
            0, 0, Fixed_Time);
         TAR_Make_FIFO (Archive, "fifo", 8#777#, 0, 0, Fixed_Time);
         TAR_Make_Char_Device
           (Archive, "character_device", 8#772#, 0, 0, 5, 12, Fixed_Time);
         TAR_Make_Block_Device
           (Archive, "block_device", 8#006#, 0, 0, 21, 5, Fixed_Time);
         TAR_Make_File
           (Archive, (1 .. 150 => 'a') & "/middle/leaf.txt",
            Work & "/regular_file", 8#644#, 0, 0, Fixed_Time);
         TAR_Close (Archive);
      end Write_Golden;

      -------------------------------------------------------------------------

      procedure Write_Edges
      is
         Archive     : TAR_Archive_Type;
         Offset_Name : constant String (7 .. 106) := (others => 'i');
         Offset_Link : constant String (11 .. 110) := (others => 'j');
         Sizes       : constant array (Positive range <>) of Natural :=
           (0, 1, 511, 512, 513, 1_048_576, 1_048_577, 1_049_088);
      begin
         TAR_Create (Archive, Work & "/edges.tar");
         TAR_Make_Directory
           (Archive, "already/", 8#755#, 0, 0, Fixed_Time);
         TAR_Make_Directory
           (Archive, "repeated//", 8#755#, 0, 0, Fixed_Time);
         TAR_Make_Directory
           (Archive, (1 .. 150 => 'd'), 8#755#, 0, 0, Fixed_Time);
         TAR_Make_Directory
           (Archive, "/" & (1 .. 100 => 'r'), 8#755#, 0, 0, Fixed_Time);
         TAR_Make_File
           (Archive, Offset_Name, Work & "/tiny.bin", 8#644#,
            0, 0, Fixed_Time);
         TAR_Make_Symlink
           (Archive, "offset-link", Offset_Link, 8#777#, 0, 0, Fixed_Time);
         TAR_Make_File
           (Archive, Deep_Prefix & "/leaf.bin", Work & "/tiny.bin",
            8#644#, 0, 0, Fixed_Time);
         TAR_Make_Hardlink
           (Archive, "deep-hardlink", Deep_Prefix & "/leaf.bin",
            8#644#, 0, 0, Fixed_Time);
         for Length in 511 .. 513 loop
            TAR_Make_Symlink
              (Archive, "target" & Natural'Image (Length), (1 .. Length => 'x'),
               8#777#, 0, 0, Fixed_Time);
         end loop;
         for Size of Sizes loop
            TAR_Make_File
              (Archive, "size" & Natural'Image (Size),
               Work & "/size" & Natural'Image (Size) & ".bin", 8#644#,
               0, 0, Fixed_Time);
         end loop;
         TAR_Make_File
           (Archive, Character'Val (255) & "byte-name", Work & "/tiny.bin",
            8#644#, 0, 0, Fixed_Time);
         TAR_Close (Archive);
      end Write_Edges;

      -------------------------------------------------------------------------

      procedure Write_Aligned
      is
         Archive : TAR_Archive_Type;
      begin
         TAR_Create (Archive, Work & "/aligned.tar");
         TAR_Make_File
           (Archive, "aligned.bin", Work & "/size 1049088.bin",
            8#644#, 0, 0, Fixed_Time);
         TAR_Close (Archive);
      end Write_Aligned;

      -------------------------------------------------------------------------

      procedure Write_Owners
      is
         Archive : TAR_Archive_Type;
      begin
         TAR_Create (Archive, Work & "/owners.tar");
         TAR_Make_File
           (Archive, "numeric-owner", Work & "/tiny.bin", 8#644#,
            65_432, 65_431, Fixed_Time);
         TAR_Close (Archive);
      end Write_Owners;

      -------------------------------------------------------------------------

      procedure Check_Errors
      is
         Archive   : TAR_Archive_Type;
         Stamp     : Ada.Calendar.Time := Fixed_Time;
         UID       : Unsigned_32 := 17;
         GID       : Unsigned_32 := 23;
         Major     : Unsigned_32 := 5;
         Minor     : Unsigned_32 := 12;
         Operation : Positive := 1;

         procedure Close_Unopened;
         --  Attempt to close a closed archive.

         procedure Add_Metadata;
         --  Exercise the selected timestamp, owner and device numeric fields.

         procedure Missing_Source;
         --  Attempt to add a nonexistent regular source file.

         procedure Oversized_Source;
         --  Reject the first payload size beyond eleven octal digits.

         procedure Recreate_Open;
         --  Reject a second Create without changing the current output.

         procedure Add_Unopened;
         --  Require initialization for every public entry operation.

         procedure Close_Unopened
         is
         begin
            TAR_Close (Archive);
         end Close_Unopened;

         ----------------------------------------------------------------------

         procedure Add_Metadata
         is
         begin
            TAR_Make_Char_Device
              (Archive, "metadata", 8#644#, UID, GID, Major, Minor, Stamp);
         end Add_Metadata;

         ----------------------------------------------------------------------

         procedure Missing_Source
         is
         begin
            TAR_Make_File
              (Archive, "missing", Work & "/missing.bin", 0, 0, 0, Fixed_Time);
         end Missing_Source;

         ----------------------------------------------------------------------

         procedure Oversized_Source
         is
         begin
            TAR_Make_File
              (Archive, "oversized", Work & "/oversized.bin",
               0, 0, 0, Fixed_Time);
         end Oversized_Source;

         ----------------------------------------------------------------------

         procedure Recreate_Open
         is
         begin
            TAR_Create (Archive, Work & "/replacement.tar");
         end Recreate_Open;

         ----------------------------------------------------------------------

         procedure Add_Unopened
         is
         begin
            case Operation is
               when 1 =>
                  TAR_Make_File
                    (Archive, "file", Work & "/tiny.bin", 0, 0, 0, Fixed_Time);
               when 2 =>
                  TAR_Make_Hardlink
                    (Archive, "hard", "target", 0, 0, 0, Fixed_Time);
               when 3 =>
                  TAR_Make_Symlink
                    (Archive, "symbolic", "target", 0, 0, 0, Fixed_Time);
               when 4 =>
                  TAR_Make_Directory (Archive, "dir", 0, 0, 0, Fixed_Time);
               when 5 =>
                  TAR_Make_FIFO (Archive, "fifo", 0, 0, 0, Fixed_Time);
               when 6 =>
                  TAR_Make_Block_Device
                    (Archive, "block", 0, 0, 0, 1, 2, Fixed_Time);
               when others =>
                  TAR_Make_Char_Device
                    (Archive, "character", 0, 0, 0, 1, 2, Fixed_Time);
            end case;
         end Add_Unopened;
      begin
         Expect_Error (Close_Unopened'Access, TAR_Not_Initialized'Identity);
         for Index in 1 .. 7 loop
            Operation := Index;
            Expect_Error (Add_Unopened'Access, TAR_Not_Initialized'Identity);
         end loop;
         TAR_Create (Archive, Work & "/errors.tar");
         if Mode = "state" then
            TAR_Make_Directory
              (Archive, "before-recreate", 8#700#, 0, 0, Fixed_Time);
            Expect_Error
              (Recreate_Open'Access, Ada.IO_Exceptions.Status_Error'Identity,
               "TAR_Create called on an open archive");
         end if;
         Expect_Error (Missing_Source'Access, File_Not_Found'Identity);
         Expect_Error (Oversized_Source'Access, File_Too_Big'Identity);
         Stamp := Ada.Calendar.Formatting.Time_Of
           (1969, 12, 31, Seconds => 86_399.0, Time_Zone => 0);
         Expect_Error (Add_Metadata'Access, Unsupported_Metadata'Identity);
         Stamp := Ada.Calendar.Formatting.Time_Of
           (2242, 3, 16, Seconds => 46_592.0, Time_Zone => 0);
         Expect_Error (Add_Metadata'Access, Unsupported_Metadata'Identity);
         Stamp := Ada.Calendar.Formatting.Time_Of
           (2300, 1, 1, Seconds => 0.0, Time_Zone => 0);
         Expect_Error (Add_Metadata'Access, Unsupported_Metadata'Identity);
         Stamp := Fixed_Time;
         UID := Max_Field + 1;
         Expect_Error (Add_Metadata'Access, Unsupported_Metadata'Identity);
         UID := 17;
         GID := Max_Field + 1;
         Expect_Error (Add_Metadata'Access, Unsupported_Metadata'Identity);
         GID := 23;
         Major := Max_Field + 1;
         Expect_Error (Add_Metadata'Access, Unsupported_Metadata'Identity);
         Major := 5;
         Minor := Max_Field + 1;
         Expect_Error (Add_Metadata'Access, Unsupported_Metadata'Identity);
         TAR_Make_Directory
           (Archive, "after-errors", 8#700#, 0, 0, Fixed_Time);
         TAR_Close (Archive);
         Expect_Error (Close_Unopened'Access, TAR_Not_Initialized'Identity);
      end Check_Errors;

      -------------------------------------------------------------------------

      procedure Check_Lifetime
      is
         Before       : constant Natural := Open_Descriptor_Count;
         Caller_Abort : exception;
      begin
         for Index in 1 .. 40 loop
            begin
               declare
                  Archive : TAR_Archive_Type;
               begin
                  TAR_Create
                    (Archive,
                     Work & "/unfinished" & Natural'Image (Index) & ".tar");
                  case Index mod 4 is
                     when 0 =>
                        TAR_Make_File
                          (Archive, "missing", Work & "/missing.bin",
                           0, 0, 0, Fixed_Time);
                     when 1 =>
                        raise Caller_Abort;
                     when 2 =>
                        TAR_Make_Directory
                          (Archive, (1 .. 120 => 'q'), 0,
                           Max_Field + 1, 0, Fixed_Time);
                     when others =>
                        null;
                  end case;
               end;
            exception
               when Caller_Abort | File_Not_Found | Unsupported_Metadata =>
                  null;
            end;
         end loop;
         Check
           (Open_Descriptor_Count = Before,
            "Omitted Close leaked TAR descriptors");
         for Index in 1 .. 40 loop
            Check
              (not Ada.Directories.Exists
                 (Work & "/unfinished" & Natural'Image (Index) & ".tar"),
               "Omitted Close retained an unfinished TAR archive");
         end loop;
         declare
            task type Owned_Writer (Number : Positive) is
               entry Ready;
               entry Complete;
            end Owned_Writer;

            task body Owned_Writer
            is
               Archive : TAR_Archive_Type;
            begin
               TAR_Create
                 (Archive,
                  Work & "/task-output" & Positive'Image (Number) & ".tar");
               accept Ready;
               accept Complete;
            end Owned_Writer;

            Normal_Exit : Owned_Writer (1);
            Abandoned   : Owned_Writer (2);
         begin
            Normal_Exit.Ready;
            Normal_Exit.Complete;
            Abandoned.Ready;
            abort Abandoned;
         end;
         for Index in 1 .. 2 loop
            Check
              (not Ada.Directories.Exists
                 (Work & "/task-output" & Natural'Image (Index) & ".tar"),
               "Task termination retained an unfinished TAR archive");
         end loop;
         Check
           (Open_Descriptor_Count = Before,
            "Task abort leaked TAR descriptors");
      end Check_Lifetime;

      -------------------------------------------------------------------------

      procedure Check_Parallel
      is
         task type Writer
           with Storage_Size => 131_072
         is
            entry Start (Number : Positive);
            entry Finish
              (Success : out Boolean;
               Detail  : out Ada.Strings.Unbounded.Unbounded_String);
         end Writer;

         task body Writer
         is
            Index      : Positive;
            OK         : Boolean := True;
            Error_Info : Ada.Strings.Unbounded.Unbounded_String;
         begin
            accept Start (Number : Positive) do
               Index := Number;
            end Start;
            begin
               Write_Entries
                 (Work & "/parallel" & Natural'Image (Index) & ".tar");
            exception
               when Error : others =>
                  Error_Info := Ada.Strings.Unbounded.To_Unbounded_String
                    (Ada.Exceptions.Exception_Information (Error));
                  OK := False;
            end;
            accept Finish
              (Success : out Boolean;
               Detail  : out Ada.Strings.Unbounded.Unbounded_String)
            do
               Success := OK;
               Detail := Error_Info;
            end Finish;
         end Writer;

         Writers    : array (1 .. 8) of Writer;
         All_OK     : Boolean := True;
         Last_Error : Ada.Strings.Unbounded.Unbounded_String;
      begin
         for Index in Writers'Range loop
            Writers (Index).Start (Index);
         end loop;
         for Index in Writers'Range loop
            declare
               OK     : Boolean;
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
           (All_OK, "Parallel TAR writer failed: " &
            Ada.Strings.Unbounded.To_String (Last_Error));
      end Check_Parallel;

   begin
      if Mode = "entries" then
         Write_Entries (Work & "/entries.tar");
      elsif Mode = "golden" then
         Write_Golden;
      elsif Mode = "edges" then
         Write_Edges;
      elsif Mode = "aligned" then
         Write_Aligned;
      elsif Mode = "owners" then
         Write_Owners;
      elsif Mode = "installed-long" then
         declare
            Archive : TAR_Archive_Type;
         begin
            TAR_Create (Archive, Work & "/installed-long.tar");
            TAR_Make_Directory
              (Archive, (1 .. 101 => 'n'), 8#755#, 0, 0, Epoch);
            TAR_Close (Archive);
         end;
      elsif Mode = "errors" or else Mode = "state" then
         Check_Errors;
      elsif Mode = "parallel" then
         Check_Parallel;
      elsif Mode = "lifetime" then
         Check_Lifetime;
      elsif Mode = "empty" then
         declare
            Archive : TAR_Archive_Type;
         begin
            TAR_Create (Archive, Work & "/empty.tar");
            TAR_Close (Archive);
         end;
      elsif Mode = "max-size" then
         declare
            Archive : TAR_Archive_Type;
         begin
            TAR_Create (Archive, Work & "/max-size.tar");
            TAR_Make_File
              (Archive, "max-size", Work & "/max-size.bin",
               8#644#, 0, 0, Fixed_Time);
            TAR_Close (Archive);
         end;
      else
         raise Program_Error with "Unknown TAR scenario: " & Mode;
      end if;
   end Run;

end TAR_Scenarios;
