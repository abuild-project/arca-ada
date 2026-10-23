--  SPDX-License-Identifier: LGPL-2.1-or-later
--  Copyright (C) 2008-2026 secunet Security Networks AG
--  Additional LGPL grant and source: doc/provenance/cpio-tar.md

with Ada.Streams.Stream_IO;
with Ada.Calendar;
with Ada.Directories;
with Ada.Finalization;
with Interfaces;

package Arca.CPIO is

   --  This implementation is inspired by the gen_init_cpio tool.

   use Ada.Calendar;
   use Interfaces;

   type Inode_Type is mod 2 ** 32;
   for Inode_Type'Size use 32;

   type CPIO_Archive_Type is tagged limited private;
   --  Own one newc output. Close completes the archive; leaving scope with
   --  an open writer attempts to discard its unfinished output. Independent
   --  instances have independent state; synchronize calls on one instance.

   procedure CPIO_Create
     (Item : in out CPIO_Archive_Type;
      Name :        String);
   --  Create/truncate Name for a closed writer and reset its inode sequence.
   --  Reject reuse while open without changing the existing archive state.

   procedure CPIO_Close
     (Item : in out CPIO_Archive_Type);
   --  Write the trailer, close the completed output and reset internal state.
   --  Reject a writer that is not open. After an I/O failure, leave scope to
   --  discard the incomplete output rather than attempting further adds.

   procedure CPIO_Make_Directory
     (Item  : in out CPIO_Archive_Type;
      Name  :        String;
      Mode  :        Unsigned_32;
      UID   :        Unsigned_32;
      GID   :        Unsigned_32;
      MTime :        Time);
   --  Append a directory with caller-supplied permissions, ownership and time.

   procedure CPIO_Make_File
     (Item   : in out CPIO_Archive_Type;
      Name   :        String;
      Source :        String;
      Mode   :        Unsigned_32;
      UID    :        Unsigned_32;
      GID    :        Unsigned_32;
      NLinks :        Unsigned_32;
      Inode  :        Inode_Type;
      MTime  :        Time);
   --  Append the regular Source file under Name using the supplied metadata.
   --  Obtain Inode from CPIO_Get_Next_Inode or reuse a hardlink-set inode.

   procedure CPIO_Make_Link
     (Item   : in out CPIO_Archive_Type;
      Name   :        String;
      Mode   :        Unsigned_32;
      UID    :        Unsigned_32;
      GID    :        Unsigned_32;
      NLinks :        Unsigned_32;
      Inode  :        Inode_Type;
      MTime  :        Time);
   --  Append a payload-free regular-file link. Match Inode, NLinks and all
   --  metadata with the final CPIO_Make_File entry carrying the set's data.

   procedure CPIO_Make_Symlink
     (Item   : in out CPIO_Archive_Type;
      Name   :        String;
      Target :        String;
      Mode   :        Unsigned_32;
      UID    :        Unsigned_32;
      GID    :        Unsigned_32;
      MTime  :        Time);
   --  Append a symbolic link whose payload is Target without a trailing NUL.

   procedure CPIO_Make_FIFO
     (Item  : in out CPIO_Archive_Type;
      Name  :        String;
      Mode  :        Unsigned_32;
      UID   :        Unsigned_32;
      GID   :        Unsigned_32;
      MTime :        Time);
   --  Append FIFO metadata without creating a FIFO in the host filesystem.

   procedure CPIO_Make_Blockdevice
     (Item  : in out CPIO_Archive_Type;
      Name  :        String;
      Mode  :        Unsigned_32;
      UID   :        Unsigned_32;
      GID   :        Unsigned_32;
      Major :        Unsigned_32;
      Minor :        Unsigned_32;
      MTime :        Time);
   --  Append block-device metadata with the supplied device numbers.

   procedure CPIO_Make_Chardevice
     (Item  : in out CPIO_Archive_Type;
      Name  :        String;
      Mode  :        Unsigned_32;
      UID   :        Unsigned_32;
      GID   :        Unsigned_32;
      Major :        Unsigned_32;
      Minor :        Unsigned_32;
      MTime :        Time);
   --  Append character-device metadata with the supplied device numbers.

   function CPIO_Get_Next_Inode
     (Item : in out CPIO_Archive_Type) return Inode_Type;
   --  Return and advance this writer's inode sequence. Only call between a
   --  successful Create and Close; callers manage hardlink-set membership.

   File_Not_Found       : exception;
   File_Read_Error      : exception;
   File_Too_Big         : exception;
   Wrong_Header_Length  : exception;
   CPIO_Not_Initialized : exception;
   Unsupported_Metadata : exception;

private
   use Ada.Streams.Stream_IO;

   --  taken from stat(2) man page
   S_IFLNK : constant := 8#0120000#;  --  Symbolic Link
   S_IFREG : constant := 8#0100000#;  --  Regular File
   S_IFBLK : constant := 8#0060000#;  --  Block Device
   S_IFDIR : constant := 8#0040000#;  --  Directory
   S_IFCHR : constant := 8#0020000#;  --  Character Device
   S_IFIFO : constant := 8#0010000#;  --  FIFO

   type Offset_Type is mod 2 ** 32;
   for Offset_Type'Size use 32;

   subtype Align_Type is Offset_Type range 2 .. 512;

   CPIO_Header_Length : constant Offset_Type := 110;
   --  Header width; the field map and format reference are in the body.

   CPIO_Header_Magic  : constant String  := "070701";
   --  magic for newc format

   CPIO_First_Inode   : constant Inode_Type := 721;
   --  the very first inode in the cpio archive

   type CPIO_Header_Type is
      record
         Inode    : Unsigned_32;
         Mode     : Unsigned_32;
         UID      : Unsigned_32;
         GID      : Unsigned_32;
         NLink    : Unsigned_32;
         MTime    : Unsigned_32;
         FileSize : Unsigned_32;
         Major    : Unsigned_32;
         Minor    : Unsigned_32;
         RMajor   : Unsigned_32;
         RMinor   : Unsigned_32;
         NameSize : Unsigned_32;
         ChkSum   : Unsigned_32;
      end record;
   --  raw (unformatted) cpio header data without the magic marker

   type CPIO_Archive_Type is new Ada.Finalization.Limited_Controlled with
      record
         File   : File_Type;
         Offset : Offset_Type := 0;
         Inode  : Inode_Type := 0;
      end record;
   --  internal state of the cpio archive containing the file handle, the
   --  current file offset in the cpio archive and the next usable inode

   overriding procedure Finalize (Item : in out CPIO_Archive_Type);
   --  Best-effort discard and closure without replacing a caller exception.

   procedure Inc_Inode
     (Item : in out CPIO_Archive_Type);
   --  increment the internal inode number of the cpio archive

   procedure Inc_Offset
     (Item   : in out CPIO_Archive_Type;
      Offset :        Offset_Type);
   --  Increment the internal file offset used for archive alignment.

   procedure CPIO_Write_Trailer
     (Item : in out CPIO_Archive_Type);
   --  write the cpio trailer (always the last data in the cpio archive)

   procedure CPIO_Write_Header
     (Item   : in out CPIO_Archive_Type;
      Header :        CPIO_Header_Type);
   --  Write the formatted header data into the CPIO archive.

   procedure CPIO_Write_String
     (Item : in out CPIO_Archive_Type;
      Name :        String);
   --  write a string into the cpio archive

   procedure CPIO_Write_Padding
     (Item  : in out CPIO_Archive_Type;
      Align :        Align_Type);
   --  add nul byte padding into the cpio archive until the offset is n-aligned

   procedure CPIO_Copy_Binary_File
     (Item        : in out CPIO_Archive_Type;
      Source_Name :        String;
      Source_Size :        Ada.Directories.File_Size);
   --  copy the regular file with the name Source_Name of size Source_Size into
   --  the created cpio archive

end Arca.CPIO;
