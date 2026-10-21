-- SPDX-License-Identifier: LGPL-2.1-or-later

with Ada.Command_Line;
with Ada.Directories;
with Ada.IO_Exceptions;
with Ada.Streams.Stream_IO;
with Arca.Binary_IO;
with Test_Support;

--  Exercise the private copy helper without exposing a production test API.
procedure Arca.Copy_Checks is

   package SIO renames Ada.Streams.Stream_IO;
   use Test_Support;
   use type Ada.Streams.Stream_Element_Offset;

   Work : constant String := Ada.Command_Line.Argument (1);
   Target : SIO.File_Type;
   Expected_Size : Ada.Directories.File_Size := 0;
   Buffer_Size : Ada.Streams.Stream_Element_Offset := 1;

   procedure Bad_Copy;
   --  Use a tiny source to exercise changed-size and buffer failures.

   procedure Bad_Copy is
   begin
      Binary_IO.Copy_File_To_Stream
        (Work & "/tiny.bin", Expected_Size, Target, Buffer_Size);
   end Bad_Copy;

begin
   SIO.Create (Target, SIO.Out_File, Work & "/discard.bin", "shared=no");
   declare
      Before : constant Natural := Open_Descriptor_Count;
   begin
      for Index in 1 .. 40 loop
         Expected_Size := 0;
         Expect_Failure
           (Bad_Copy'Access, Ada.IO_Exceptions.End_Error'Identity,
            "Source file grew while copying");
         Expected_Size := 4;
         Expect_Failure
           (Bad_Copy'Access, Ada.IO_Exceptions.End_Error'Identity,
            "Unable to read expected source file size");
         Expected_Size := 2;
         Expect_Failure
           (Bad_Copy'Access, Ada.IO_Exceptions.End_Error'Identity,
            "Source file grew while copying");
      end loop;
      Check
        (Open_Descriptor_Count = Before,
         "Failed copy leaked source descriptors");
   end;
   Buffer_Size := 0;
   Expect_Failure
     (Bad_Copy'Access, Constraint_Error'Identity,
      "copy buffer size must be positive");
   Buffer_Size := -1;
   Expect_Failure
     (Bad_Copy'Access, Constraint_Error'Identity,
      "copy buffer size must be positive");
   SIO.Close (Target);
   SIO.Create (Target, SIO.Out_File, Work & "/copy.bin", "shared=no");
   Binary_IO.Copy_File_To_Stream
     (Work & "/payload.bin", Ada.Directories.Size (Work & "/payload.bin"),
      Target, 4093);
   SIO.Close (Target);
exception
   when others =>
      if SIO.Is_Open (Target) then
         SIO.Close (Target);
      end if;
      raise;
end Arca.Copy_Checks;
