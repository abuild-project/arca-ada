--  SPDX-License-Identifier: GPL-2.0-or-later
--  Copyright (C) 2008-2026 secunet Security Networks AG
--  Derived from Abuild; see doc/licensing.md

with Ada.Calendar;
with Ada.Finalization;
with Ada.Streams.Stream_IO;
with Interfaces;

package Arca.TAR is

   use Ada.Calendar;
   use Interfaces;

   type TAR_Archive_Type is
     new Ada.Finalization.Limited_Controlled with private;
   --  Own one archive output. Close completes it; leaving scope with an open
   --  writer attempts to discard unfinished output. Synchronize shared calls.

   procedure TAR_Create
     (Item : in out TAR_Archive_Type;
      Name :        String);
   --  Create/truncate Name for a closed writer. Reject reuse while open
   --  without closing or changing the current output.

   procedure TAR_Close (Item : in out TAR_Archive_Type);
   --  Append two zero blocks and close the completed archive. Reject a closed
   --  writer; abandon the instance after an add or I/O failure.

   procedure TAR_Make_File
     (Item   : in out TAR_Archive_Type;
      Name   :        String;
      Source :        String;
      Mode   :        Unsigned_32;
      UID    :        Unsigned_32;
      GID    :        Unsigned_32;
      MTime  :        Time);
   --  Append Source under Name, retaining metadata and exact payload bytes.
   --  Reject missing sources and payloads above 8 GiB - 1 byte.

   procedure TAR_Make_Hardlink
     (Item   : in out TAR_Archive_Type;
      Name   :        String;
      Target :        String;
      Mode   :        Unsigned_32;
      UID    :        Unsigned_32;
      GID    :        Unsigned_32;
      MTime  :        Time);
   --  Append a payload-free hardlink to Target with caller-supplied metadata.

   procedure TAR_Make_Symlink
     (Item   : in out TAR_Archive_Type;
      Name   :        String;
      Target :        String;
      Mode   :        Unsigned_32;
      UID    :        Unsigned_32;
      GID    :        Unsigned_32;
      MTime  :        Time);
   --  Append a symbolic link to Target; use GNU metadata for long targets.

   procedure TAR_Make_Directory
     (Item  : in out TAR_Archive_Type;
      Name  :        String;
      Mode  :        Unsigned_32;
      UID   :        Unsigned_32;
      GID   :        Unsigned_32;
      MTime :        Time);
   --  Append a directory, adding a trailing slash when Name lacks one.

   procedure TAR_Make_FIFO
     (Item  : in out TAR_Archive_Type;
      Name  :        String;
      Mode  :        Unsigned_32;
      UID   :        Unsigned_32;
      GID   :        Unsigned_32;
      MTime :        Time);
   --  Append a payload-free FIFO with caller-supplied metadata.

   procedure TAR_Make_Block_Device
     (Item  : in out TAR_Archive_Type;
      Name  :        String;
      Mode  :        Unsigned_32;
      UID   :        Unsigned_32;
      GID   :        Unsigned_32;
      Major :        Unsigned_32;
      Minor :        Unsigned_32;
      MTime :        Time);
   --  Append a block-device entry with seven-octal-digit major/minor fields.

   procedure TAR_Make_Char_Device
     (Item  : in out TAR_Archive_Type;
      Name  :        String;
      Mode  :        Unsigned_32;
      UID   :        Unsigned_32;
      GID   :        Unsigned_32;
      Major :        Unsigned_32;
      Minor :        Unsigned_32;
      MTime :        Time);
   --  Append a character-device entry with the supplied major/minor fields.

   File_Not_Found       : exception;
   File_Read_Error      : exception;
   File_Too_Big         : exception;
   TAR_Not_Initialized  : exception;
   Unsupported_Metadata : exception;

private

   use Ada.Streams.Stream_IO;

   Block_Size : constant := 512;

   type TAR_Archive_Type is
     new Ada.Finalization.Limited_Controlled with record
      File : File_Type;
   end record;

   overriding procedure Finalize (Item : in out TAR_Archive_Type);
   --  Best-effort discard and closure without replacing a caller exception.

end Arca.TAR;
