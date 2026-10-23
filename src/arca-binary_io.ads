--  SPDX-License-Identifier: LGPL-2.1-or-later
--  Copyright (C) 2008-2026 secunet Security Networks AG
--  Additional LGPL grant and source: doc/provenance/cpio-tar.md

with Ada.Directories;
with Ada.Streams;
with Ada.Streams.Stream_IO;

private package Arca.Binary_IO is

   Default_Copy_Buffer_Size : constant Ada.Streams.Stream_Element_Offset
     := 1_048_576;
   --  Per-call heap buffer bound for linear source-to-target file copies.

   procedure Copy_File_To_Stream
     (Source_Name :        String;
      Source_Size :        Ada.Directories.File_Size;
      Target      : in out Ada.Streams.Stream_IO.File_Type;
      Buffer_Size :        Ada.Streams.Stream_Element_Offset
        := Default_Copy_Buffer_Size);
   --  Copy exactly Source_Size bytes to the open Target at its current
   --  position. Reject a nonpositive buffer and changed source sizes.
   --  Close the source and free the private buffer on success or exception.

   procedure Discard_Output (File : in out Ada.Streams.Stream_IO.File_Type);
   --  Best-effort removal of an open incomplete output. If Delete fails,
   --  still attempt Close; never propagate an implicit-cleanup failure.

end Arca.Binary_IO;
