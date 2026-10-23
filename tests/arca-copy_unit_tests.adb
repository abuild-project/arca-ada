--  SPDX-License-Identifier: LGPL-2.1-or-later

with Ada.IO_Exceptions;
with Ada.Streams.Stream_IO;
with Ahven;
with Arca.Binary_IO;
with Arca.Copy_Scenarios;
with Test_Support;
with Unit_Support;

package body Arca.Copy_Unit_Tests is

   package SIO renames Ada.Streams.Stream_IO;

   use Ahven.Framework;
   use Unit_Support;
   use type SIO.Count;

   procedure Shared_Checks;
   --  Reject growth, short reads and invalid buffers without leaking handles.

   procedure Exact_Buffer;
   --  Copy a source exactly one buffer long without inventing trailing bytes.

   procedure Empty_Source;
   --  Accept an empty source with zero output and no retained source handle.

   procedure Missing_Source;
   --  Preserve the missing-source exception and leave the target usable.

   procedure Comparison_Sensitivity;
   --  Reject different bytes and lengths while closing comparison streams.

   -------------------------------------------------------------------------

   procedure Shared_Checks
   is
      Files : constant Fixture := Prepare ("copy-shared");
   begin
      Copy_Scenarios.Run (Path (Files));
      Assert_Equal_Files
        (Path (Files) & "/payload.bin", Path (Files) & "/copy.bin");
   end Shared_Checks;

   -------------------------------------------------------------------------

   procedure Exact_Buffer
   is
      Files  : constant Fixture := Prepare ("copy-exact");
      Target : SIO.File_Type;
   begin
      SIO.Create
        (Target, SIO.Out_File, Path (Files) & "/copy.bin", "shared=no");
      Binary_IO.Copy_File_To_Stream
        (Path (Files) & "/tiny.bin", 3, Target, 3);
      SIO.Close (Target);
      Assert_Equal_Files
        (Path (Files) & "/tiny.bin", Path (Files) & "/copy.bin");
   exception
      when others =>
         if SIO.Is_Open (Target) then
            SIO.Close (Target);
         end if;
         raise;
   end Exact_Buffer;

   -------------------------------------------------------------------------

   procedure Empty_Source
   is
      Files  : constant Fixture := Prepare ("copy-empty");
      Target : SIO.File_Type;
      Before : Natural;
   begin
      SIO.Create
        (Target, SIO.Out_File, Path (Files) & "/copy.bin", "shared=no");
      Before := Test_Support.Open_Descriptor_Count;
      Binary_IO.Copy_File_To_Stream
        (Path (Files) & "/empty.bin", 0, Target, 1);
      Ahven.Assert (SIO.Size (Target) = 0, "Empty copy emitted payload bytes");
      Ahven.Assert
        (Test_Support.Open_Descriptor_Count = Before,
         "Empty copy leaked its source descriptor");
      SIO.Close (Target);
   exception
      when others =>
         if SIO.Is_Open (Target) then
            SIO.Close (Target);
         end if;
         raise;
   end Empty_Source;

   -------------------------------------------------------------------------

   procedure Missing_Source
   is
      Files  : constant Fixture := Prepare ("copy-missing");
      Target : SIO.File_Type;
      Before : Natural;
   begin
      SIO.Create
        (Target, SIO.Out_File, Path (Files) & "/copy.bin", "shared=no");
      Before := Test_Support.Open_Descriptor_Count;
      begin
         Binary_IO.Copy_File_To_Stream
           (Path (Files) & "/missing.bin", 0, Target, 1);
         Ahven.Fail ("Missing source was accepted");
      exception
         when Ada.IO_Exceptions.Name_Error =>
            null;
      end;
      Ahven.Assert
        (Test_Support.Open_Descriptor_Count = Before,
         "Missing source leaked a descriptor");
      Binary_IO.Copy_File_To_Stream
        (Path (Files) & "/tiny.bin", 3, Target, 2);
      SIO.Close (Target);
      Assert_Equal_Files
        (Path (Files) & "/tiny.bin", Path (Files) & "/copy.bin");
   exception
      when others =>
         if SIO.Is_Open (Target) then
            SIO.Close (Target);
         end if;
         raise;
   end Missing_Source;

   -------------------------------------------------------------------------

   procedure Comparison_Sensitivity
   is
      Files  : constant Fixture := Prepare ("copy-comparison");
      Target : SIO.File_Type;
      Before : Natural;

      procedure Changed_Bytes;
      --  Compare equal-length sources with one deliberately changed byte.

      procedure Changed_Length;
      --  Compare empty and nonempty sources to pin the length guard.

      procedure Changed_Bytes
      is
      begin
         Assert_Equal_Files
           (Path (Files) & "/tiny.bin", Path (Files) & "/changed.bin");
      end Changed_Bytes;

      ----------------------------------------------------------------------

      procedure Changed_Length
      is
      begin
         Assert_Equal_Files
           (Path (Files) & "/tiny.bin", Path (Files) & "/empty.bin");
      end Changed_Length;
   begin
      SIO.Create
        (Target, SIO.Out_File, Path (Files) & "/changed.bin", "shared=no");
      SIO.Write (Target, Ada.Streams.Stream_Element_Array'(1, 2, 4));
      SIO.Close (Target);
      Before := Test_Support.Open_Descriptor_Count;
      Test_Support.Expect_Failure
        (Changed_Bytes'Access, Ahven.Assertion_Error'Identity,
         "File bytes differ");
      Test_Support.Expect_Failure
        (Changed_Length'Access, Ahven.Assertion_Error'Identity,
         "File lengths differ");
      Ahven.Assert
        (Test_Support.Open_Descriptor_Count = Before,
         "Failed file comparison leaked descriptors");
   exception
      when others =>
         if SIO.Is_Open (Target) then
            SIO.Close (Target);
         end if;
         raise;
   end Comparison_Sensitivity;

   -------------------------------------------------------------------------

   overriding procedure Initialize (Item : in out Test_Case)
   is
   begin
      Set_Name (Item, "Binary_IO");
      Add_Test_Routine (Item, Shared_Checks'Access, "copy error contracts");
      Add_Test_Routine (Item, Exact_Buffer'Access, "exact buffer payload");
      Add_Test_Routine (Item, Empty_Source'Access, "empty source");
      Add_Test_Routine (Item, Missing_Source'Access, "missing source recovery");
      Add_Test_Routine
        (Item, Comparison_Sensitivity'Access, "comparison sensitivity");
   end Initialize;

end Arca.Copy_Unit_Tests;
