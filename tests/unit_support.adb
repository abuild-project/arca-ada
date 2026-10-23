--  SPDX-License-Identifier: LGPL-2.1-or-later

with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Exceptions;
with Ada.Streams.Stream_IO;
with Ahven;
with GNAT.OS_Lib;
with Interfaces.C.Strings;

package body Unit_Support is

   package SIO renames Ada.Streams.Stream_IO;

   use Ada.Streams;
   use Ada.Strings.Unbounded;
   use type Ada.Directories.File_Size;
   use type SIO.Count;
   use type Interfaces.C.Strings.chars_ptr;
   use type Interfaces.C.size_t;

   function Mkdtemp
     (Template : in out Interfaces.C.char_array)
      return Interfaces.C.Strings.chars_ptr
     with Import, Convention => C, External_Name => "mkdtemp";
   --  Create a mode-0700 directory; its returned pointer aliases Template.

   function Path (Item : Fixture) return String
   is
   begin
      return (if Item.Native then Interfaces.C.To_Ada (Item.Native_Path)
              else To_String (Item.Directory));
   end Path;

   -------------------------------------------------------------------------

   function Prepare (Name : String) return Fixture
   is
      File  : SIO.File_Type;
      Block : Stream_Element_Array (1 .. 4093);

      procedure Create_Source (Filename : String; Size : Natural);
      --  Write an exact patterned source using a small reusable buffer.

      procedure Create_Source (Filename : String; Size : Natural)
      is
         Remaining : Natural := Size;
      begin
         SIO.Create (File, SIO.Out_File, Filename, "shared=no");

         while Remaining > 0 loop
            declare
               Count : constant Natural :=
                 Natural'Min (Remaining, Block'Length);
            begin
               SIO.Write (File, Block (1 .. Stream_Element_Offset (Count)));
               Remaining := Remaining - Count;
            end;
         end loop;

         SIO.Close (File);
      end Create_Source;
   begin
      for Index in Block'Range loop
         Block (Index) := Stream_Element (Index mod 251);
      end loop;

      return Result : Fixture do
         Result.Directory := To_Unbounded_String
           (Ada.Environment_Variables.Value ("ARCA_TEST_ROOT") & "/" & Name);
         Ada.Directories.Create_Directory (Path (Result));
         Result.Created := True;

         Create_Source (Path (Result) & "/payload.bin", 2_097_189);
         Create_Source (Path (Result) & "/empty.bin", 0);
         Create_Source (Path (Result) & "/tiny.bin", 3);

         SIO.Create
           (File, SIO.Out_File, Path (Result) & "/oversized.bin", "shared=no");
         SIO.Set_Index (File, 2 ** 33);
         SIO.Write (File, Stream_Element_Array'(1 => 0));
         SIO.Close (File);
      end return;
   exception
      when others =>
         if SIO.Is_Open (File) then
            SIO.Close (File);
         end if;
         raise;
   end Prepare;

   -------------------------------------------------------------------------

   function Prepare_Native (Name : String) return Fixture
   is
      Template : constant Interfaces.C.char_array :=
        Interfaces.C.To_C ("/tmp/arca-" & Name & "-XXXXXX");
   begin
      return Result : Fixture do
         Result.Native := True;
         if Template'Length > Result.Native_Path'Length then
            raise Constraint_Error with "native fixture name is too long";
         end if;

         Result.Native_Path (Template'Range) := Template;
         if Mkdtemp (Result.Native_Path) = Interfaces.C.Strings.Null_Ptr then
            raise Program_Error with GNAT.OS_Lib.Errno_Message;
         end if;

         Result.Created := True;
      end return;
   end Prepare_Native;

   -------------------------------------------------------------------------

   overriding procedure Finalize (Item : in out Fixture)
   is
   begin
      if Item.Created then
         if Item.Native then
            GNAT.OS_Lib.Set_Writable (Path (Item));
         end if;
         Ada.Directories.Delete_Tree (Path (Item));
      end if;
   end Finalize;

   -------------------------------------------------------------------------

   procedure Assert_Equal_Files (Left, Right : String)
   is
      A, B           : SIO.File_Type;
      Data_A, Data_B : Stream_Element_Array (1 .. 4096);
      Last_A, Last_B : Stream_Element_Offset;
   begin
      Ahven.Assert
        (Ada.Directories.Size (Left) = Ada.Directories.Size (Right),
         "File lengths differ: " & Left & " / " & Right);
      SIO.Open (A, SIO.In_File, Left, "shared=no");
      SIO.Open (B, SIO.In_File, Right, "shared=no");

      while not SIO.End_Of_File (A) loop
         SIO.Read (A, Data_A, Last_A);
         SIO.Read (B, Data_B, Last_B);
         Ahven.Assert
           (Last_A = Last_B and then
            Data_A (1 .. Last_A) = Data_B (1 .. Last_B),
            "File bytes differ: " & Left & " / " & Right);
      end loop;

      Ahven.Assert (SIO.End_Of_File (B), "Unexpected trailing bytes");
      SIO.Close (A);
      SIO.Close (B);
   exception
      when others =>
         if SIO.Is_Open (A) then
            SIO.Close (A);
         end if;
         if SIO.Is_Open (B) then
            SIO.Close (B);
         end if;
         raise;
   end Assert_Equal_Files;

   -------------------------------------------------------------------------

   procedure Exercise
     (Action    : not null access procedure (Mode, Work : String);
      Mode      : String;
      Name      : String;
      Extension : String)
   is
      Files : constant Fixture := Prepare (Name);
      Work  : constant String := Path (Files);
   begin
      Action (Mode, Work);

      if Mode = "parallel" then
         for Index in 2 .. 8 loop
            Assert_Equal_Files
              (Work & "/parallel 1" & Extension,
               Work & "/parallel" & Natural'Image (Index) & Extension);
         end loop;
      elsif Mode = "errors" or else Mode = "state" then
         Ahven.Assert
           (Ada.Directories.Size (Work & "/errors" & Extension) > 0,
            "Recovery did not produce a completed archive");
         Ahven.Assert
           (not Ada.Directories.Exists (Work & "/replacement" & Extension),
            "Repeated Create opened a replacement output");
      end if;
   exception
      when Error : Program_Error =>
         Ahven.Fail (Ada.Exceptions.Exception_Message (Error));
   end Exercise;

end Unit_Support;
