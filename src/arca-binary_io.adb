-- SPDX-License-Identifier: LGPL-2.1-or-later
-- Copyright (C) 2008-2026 secunet Security Networks AG
-- Additional LGPL grant and source: doc/provenance/cpio-tar.md

with Ada.IO_Exceptions;
with Ada.Unchecked_Deallocation;

package body Arca.Binary_IO is

   use Ada.Streams;

   type Buffer_Access is access Stream_Element_Array;

   procedure Free_Buffer is new Ada.Unchecked_Deallocation
     (Object => Stream_Element_Array,
      Name   => Buffer_Access);
   --  Release the per-call copy buffer on success or exception.

   -------------------------------------------------------------------------

   procedure Discard_Output (File : in out Ada.Streams.Stream_IO.File_Type) is
      package SIO renames Ada.Streams.Stream_IO;
   begin
      if SIO.Is_Open (File) then
         begin
            SIO.Delete (File);
         exception
            when others =>
               --  GNAT rejects nonregular outputs before closing them.
               --  A failed unlink may instead have closed the stream already.
               if SIO.Is_Open (File) then
                  SIO.Close (File);
               end if;
         end;
      end if;
   exception
      when others =>
         --  Implicit finalization must preserve the caller's original failure.
         --  Explicit writer Close remains the reporting operation for I/O.
         null;
   end Discard_Output;

   -------------------------------------------------------------------------

   procedure Copy_File_To_Stream
     (Source_Name :        String;
      Source_Size :        Ada.Directories.File_Size;
      Target      : in out Ada.Streams.Stream_IO.File_Type;
      Buffer_Size :        Stream_Element_Offset
        := Default_Copy_Buffer_Size)
   is
      package SIO renames Ada.Streams.Stream_IO;
      use type Ada.Directories.File_Size;

      Source_File : SIO.File_Type;
      Bytes_Read  : Ada.Directories.File_Size := 0;
   begin
      if Buffer_Size <= 0 then
         raise Constraint_Error with "copy buffer size must be positive";
      end if;

      SIO.Open (File => Source_File,
                Mode => SIO.In_File,
                Name => Source_Name,
                Form => "shared=no");

      if Source_Size = 0 then
         if not SIO.End_Of_File (Source_File) then
            raise Ada.IO_Exceptions.End_Error with
              "Source file grew while copying";
         end if;

         SIO.Close (Source_File);
         return;
      end if;

      declare
         --  Keep the large default copy buffer off worker task stacks and
         --  avoid allocating more than the current source file can use.
         Effective_Buffer_Size : constant Stream_Element_Offset :=
           (if Source_Size > Ada.Directories.File_Size (Buffer_Size)
            then Buffer_Size
            else Stream_Element_Offset (Source_Size));
         Buffer : Buffer_Access := new Stream_Element_Array
           (1 .. Effective_Buffer_Size);
      begin
         while Bytes_Read < Source_Size loop
            declare
               Remaining : constant Ada.Directories.File_Size
                 := Source_Size - Bytes_Read;
               To_Read   : constant Stream_Element_Offset
                 := (if Remaining >
                        Ada.Directories.File_Size (Effective_Buffer_Size)
                     then Effective_Buffer_Size
                     else Stream_Element_Offset (Remaining));
               Last      : Stream_Element_Offset;
            begin
               SIO.Read
                 (File => Source_File,
                  Item => Buffer.all
                    (Buffer'First .. Buffer'First + To_Read - 1),
                  Last => Last);

               if Last - Buffer'First + 1 /= To_Read then
                  raise Ada.IO_Exceptions.End_Error with
                    "Unable to read expected source file size";
               end if;

               SIO.Write
                 (File => Target,
                  Item => Buffer.all (Buffer'First .. Last));
               Bytes_Read := Bytes_Read + Ada.Directories.File_Size (To_Read);
            end;
         end loop;

         if not SIO.End_Of_File (Source_File) then
            raise Ada.IO_Exceptions.End_Error with
              "Source file grew while copying";
         end if;

         Free_Buffer (Buffer);
      exception
         when others =>
            Free_Buffer (Buffer);
            raise;
      end;

      SIO.Close (Source_File);

   exception
      when others =>
         if SIO.Is_Open (Source_File) then
            SIO.Close (Source_File);
         end if;
         raise;
   end Copy_File_To_Stream;

end Arca.Binary_IO;
