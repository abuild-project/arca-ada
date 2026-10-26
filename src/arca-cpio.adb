--  SPDX-License-Identifier: GPL-2.0-or-later
--  Copyright (C) 2008-2026 secunet Security Networks AG
--  Derived from Abuild; see doc/licensing.md

with Ada.Calendar.Conversions;
with Ada.Characters.Latin_1;
with Ada.IO_Exceptions;
with Interfaces.C;
with GNAT.Formatted_String;

with Arca.Binary_IO;

package body Arca.CPIO is

   CPIO_Max_Payload_Message : constant String :=
     "newc CPIO supports payloads up to 4 GiB - 1 byte";

   Permission_Mask : constant Unsigned_32 := 8#7777#;

   --  Writer overview
   --
   --  This writer emits the ASCII "newc" CPIO format. Every archive entry
   --  consists of one fixed 110-byte header, the NUL-terminated file name,
   --  optional file data and NUL padding. Both the name area and the payload
   --  area are padded to 4-byte boundaries. The archive ends with a
   --  "TRAILER!!!" entry and is then padded to a 512-byte boundary.
   --
   --  Header layout (1-based indices in this Ada implementation):
   --
   --    1 ..   6   magic ("070701")
   --    7 ..  14   inode
   --   15 ..  22   mode
   --   23 ..  30   uid
   --   31 ..  38   gid
   --   39 ..  46   nlink
   --   47 ..  54   mtime
   --   55 ..  62   filesize
   --   63 ..  70   devmajor
   --   71 ..  78   devminor
   --   79 ..  86   rdevmajor
   --   87 ..  94   rdevminor
   --   95 .. 102   namesize, including the trailing NUL byte
   --  103 .. 110   checksum, always zero for "newc"
   --
   --  Regular-file hardlinks follow the common CPIO convention used by
   --  gen_init_cpio: all link headers share the same inode and nlink count,
   --  but only the last entry carries the file payload. Callers supply
   --  consistent metadata for every header of the same hardlink set.
   --  The normative format reference is linked in doc/cpio.md.

   -------------------------------------------------------------------------

   overriding procedure Finalize (Item : in out CPIO_Archive_Type)
   is
   begin
      Arca.Binary_IO.Discard_Output (Item.File);
   end Finalize;

   -------------------------------------------------------------------------

   function Encode_MTime (MTime : Time) return Unsigned_32;
   --  Convert Ada time to the 32-bit UNIX timestamp stored by newc headers.

   function Encode_Mode (Kind, Mode : Unsigned_32) return Unsigned_32;
   --  Select the operation's entry kind and retain only caller permissions.

   -------------------------------------------------------------------------

   procedure Inc_Offset
     (Item   : in out CPIO_Archive_Type;
      Offset :        Offset_Type)
   is
   begin
      Item.Offset := Item.Offset + Offset;
   end Inc_Offset;

   -------------------------------------------------------------------------

   procedure Inc_Inode
     (Item : in out CPIO_Archive_Type)
   is
   begin
      Item.Inode := Item.Inode + 1;
   end Inc_Inode;

   -------------------------------------------------------------------------

   function CPIO_Get_Next_Inode
     (Item : in out CPIO_Archive_Type) return Inode_Type
   is
      Result : constant Inode_Type := Item.Inode;
   begin
      Item.Inc_Inode;
      return Result;
   end CPIO_Get_Next_Inode;

   -------------------------------------------------------------------------

   function Encode_MTime (MTime : Time) return Unsigned_32
   is
      use Ada.Calendar.Conversions;
      use type Interfaces.C.long;

      Unix_Time : Interfaces.C.long;
   begin
      Unix_Time := To_Unix_Time (MTime);
      if Unix_Time < Interfaces.C.long'(0)
        or else Long_Long_Integer (Unix_Time)
          > Long_Long_Integer (Unsigned_32'Last)
      then
         raise Unsupported_Metadata with
           "CPIO mtime outside supported UNIX timestamp range";
      end if;

      return Unsigned_32 (Unix_Time);
   exception
      when Constraint_Error | Ada.Calendar.Time_Error =>
         raise Unsupported_Metadata with
           "CPIO mtime outside supported UNIX timestamp range";
   end Encode_MTime;

   -------------------------------------------------------------------------

   function Encode_Mode (Kind, Mode : Unsigned_32) return Unsigned_32
   is
   begin
      return Kind or (Mode and Permission_Mask);
   end Encode_Mode;

   -------------------------------------------------------------------------

   procedure CPIO_Write_Header
     (Item   : in out CPIO_Archive_Type;
      Header :        CPIO_Header_Type)
   is
      use GNAT.Formatted_String;

      Formatted_Header : Formatted_String :=
        +"%s%08X%08X%08lX%08lX%08X%08lX%08X%08X%08X%08X%08X%08X%08X";
   begin
      Formatted_Header := Formatted_Header
        & CPIO_Header_Magic
        & Long_Integer (Header.Inode)
        & Long_Integer (Header.Mode)
        & Long_Integer (Header.UID)
        & Long_Integer (Header.GID)
        & Long_Integer (Header.NLink)
        & Long_Integer (Header.MTime)
        & Long_Integer (Header.FileSize)
        & Long_Integer (Header.Major)
        & Long_Integer (Header.Minor)
        & Long_Integer (Header.RMajor)
        & Long_Integer (Header.RMinor)
        & Long_Integer (Header.NameSize)
        & Long_Integer (Header.ChkSum);

      declare
         Header : constant String := -Formatted_Header;
      begin
         if Header'Length /= CPIO_Header_Length then
            raise Wrong_Header_Length with "CPIO header length should be "
              & Offset_Type'Image (CPIO_Header_Length) & " but found  "
              & Integer'Image (Header'Length) & " instead";
         end if;

         String'Write (Stream (Item.File), Header);
      end;

      Item.Inc_Offset (Offset => CPIO_Header_Length);
   end CPIO_Write_Header;

   -------------------------------------------------------------------------

   procedure CPIO_Write_String
     (Item : in out CPIO_Archive_Type;
      Name :        String)
   is
      Name_Length : constant Offset_Type := Name'Length + 1;
   begin
      --  write name string with trailing nul byte
      String'Write (Stream (Item.File), Name & Ada.Characters.Latin_1.NUL);
      Item.Inc_Offset (Offset => Name_Length);
   end CPIO_Write_String;

   -------------------------------------------------------------------------

   procedure CPIO_Write_Padding
     (Item  : in out CPIO_Archive_Type;
      Align :        Align_Type)
   is
   begin
      --  make the current offset n byte aligned
      while Item.Offset mod Align /= 0
      loop
         Character'Write (Stream (Item.File), Ada.Characters.Latin_1.NUL);
         Item.Inc_Offset (Offset => 1);
      end loop;
   end CPIO_Write_Padding;

   -------------------------------------------------------------------------

   procedure CPIO_Write_Trailer
     (Item : in out CPIO_Archive_Type)
   is
      Trailer_Marker : constant String := "TRAILER!!!";
      Trailer_Header : constant CPIO_Header_Type :=
        CPIO_Header_Type'(NLink    => 1,
                          NameSize => Trailer_Marker'Length + 1,
                          others   => 0);
   begin
      Item.CPIO_Write_Header (Header => Trailer_Header);
      Item.CPIO_Write_String (Name => Trailer_Marker);
      Item.CPIO_Write_Padding (Align => 512);
   end CPIO_Write_Trailer;

   -------------------------------------------------------------------------

   procedure CPIO_Copy_Binary_File
     (Item        : in out CPIO_Archive_Type;
      Source_Name :        String;
      Source_Size :        Ada.Directories.File_Size)
   is
   begin
      Arca.Binary_IO.Copy_File_To_Stream
        (Source_Name => Source_Name,
         Source_Size => Source_Size,
         Target      => Item.File);
   exception
      when Ada.IO_Exceptions.End_Error =>
         raise File_Read_Error with
           "Could not read expected source file size from '"
           & Source_Name & "'";
   end CPIO_Copy_Binary_File;

   -------------------------------------------------------------------------

   procedure CPIO_Make_Directory
     (Item  : in out CPIO_Archive_Type;
      Name  :        String;
      Mode  :        Unsigned_32;
      UID   :        Unsigned_32;
      GID   :        Unsigned_32;
      MTime :        Time)
   is
      Header : CPIO_Header_Type;
   begin
      if not Is_Open (File => Item.File) then
         raise CPIO_Not_Initialized with
           "CPIO_Make_Directory called on uninitialized archive";
      end if;

      Header :=
        CPIO_Header_Type'(Inode    => Unsigned_32 (Item.CPIO_Get_Next_Inode),
                          Mode     => Encode_Mode (S_IFDIR, Mode),
                          UID      => UID,
                          GID      => GID,
                          NLink    => 2,
                          MTime    => Encode_MTime (MTime),
                          Major    => 3,
                          Minor    => 1,
                          NameSize => Name'Length + 1,
                          others   => 0);

      Item.CPIO_Write_Header (Header => Header);
      Item.CPIO_Write_String (Name => Name);
      Item.CPIO_Write_Padding (Align => 4);
   end CPIO_Make_Directory;

   -------------------------------------------------------------------------

   procedure CPIO_Make_File
     (Item   : in out CPIO_Archive_Type;
      Name   :        String;
      Source :        String;
      Mode   :        Unsigned_32;
      UID    :        Unsigned_32;
      GID    :        Unsigned_32;
      NLinks :        Unsigned_32;
      Inode  :        Inode_Type;
      MTime  :        Time)
   is
      use Ada.Directories;

      Header      : CPIO_Header_Type;
      Source_Size : File_Size;
   begin
      if not Is_Open (File => Item.File) then
         raise CPIO_Not_Initialized with
           "CPIO_Make_File called on uninitialized archive";
      end if;

      if not Exists (Name => Source) then
         raise File_Not_Found with "Could not locate source file '"
           & Source & "'";
      end if;

      Source_Size := Size (Name => Source);

      if Source_Size > File_Size (Unsigned_32'Last) then
         raise File_Too_Big with "File '" & Source & "' too big, "
           & CPIO_Max_Payload_Message;
      end if;

      Header :=
        CPIO_Header_Type'(Inode    => Unsigned_32 (Inode),
                          Mode     => Encode_Mode (S_IFREG, Mode),
                          UID      => UID,
                          GID      => GID,
                          NLink    => NLinks,
                          MTime    => Encode_MTime (MTime),
                          FileSize => Unsigned_32 (Source_Size),
                          Major    => 3,
                          Minor    => 1,
                          NameSize => Name'Length + 1,
                          others   => 0);

      Item.CPIO_Write_Header (Header => Header);
      Item.CPIO_Write_String (Name => Name);
      Item.CPIO_Write_Padding (Align => 4);

      --  write binary data part
      Item.CPIO_Copy_Binary_File
        (Source_Name => Source,
         Source_Size => Source_Size);

      Item.Inc_Offset (Offset => Offset_Type (Source_Size));
      Item.CPIO_Write_Padding (Align => 4);
   end CPIO_Make_File;

   -------------------------------------------------------------------------

   procedure CPIO_Make_Link
     (Item   : in out CPIO_Archive_Type;
      Name   :        String;
      Mode   :        Unsigned_32;
      UID    :        Unsigned_32;
      GID    :        Unsigned_32;
      NLinks :        Unsigned_32;
      Inode  :        Inode_Type;
      MTime  :        Time)
   is
      Header : CPIO_Header_Type;
   begin
      if not Is_Open (File => Item.File) then
         raise CPIO_Not_Initialized with
           "CPIO_Make_Link called on uninitialized archive";
      end if;

      Header :=
        CPIO_Header_Type'(Inode    => Unsigned_32 (Inode),
                          Mode     => Encode_Mode (S_IFREG, Mode),
                          UID      => UID,
                          GID      => GID,
                          NLink    => NLinks,
                          MTime    => Encode_MTime (MTime),
                          Major    => 3,
                          Minor    => 1,
                          NameSize => Name'Length + 1,
                          others   => 0);

      Item.CPIO_Write_Header (Header => Header);
      Item.CPIO_Write_String (Name => Name);
      Item.CPIO_Write_Padding (Align => 4);
   end CPIO_Make_Link;

   -------------------------------------------------------------------------

   procedure CPIO_Make_Symlink
     (Item   : in out CPIO_Archive_Type;
      Name   :        String;
      Target :        String;
      Mode   :        Unsigned_32;
      UID    :        Unsigned_32;
      GID    :        Unsigned_32;
      MTime  :        Time)
   is
      Header : CPIO_Header_Type;
   begin
      if not Is_Open (File => Item.File) then
         raise CPIO_Not_Initialized with
           "CPIO_Make_Symlink called on uninitialized archive";
      end if;

      --  Symlink targets are in-memory strings, but they still occupy the
      --  newc FileSize field and therefore share the same payload limit as
      --  copied regular-file data.
      if Long_Long_Integer (Target'Length)
        > Long_Long_Integer (Unsigned_32'Last)
      then
         raise File_Too_Big with "Symlink target for '" & Name & "' too big, "
           & CPIO_Max_Payload_Message;
      end if;

      Header :=
        CPIO_Header_Type'(Inode    => Unsigned_32 (Item.CPIO_Get_Next_Inode),
                          Mode     => Encode_Mode (S_IFLNK, Mode),
                          UID      => UID,
                          GID      => GID,
                          NLink    => 1,
                          MTime    => Encode_MTime (MTime),
                          FileSize => Target'Length,
                          Major    => 3,
                          Minor    => 1,
                          NameSize => Name'Length + 1,
                          others   => 0);

      Item.CPIO_Write_Header (Header => Header);
      Item.CPIO_Write_String (Name => Name);
      Item.CPIO_Write_Padding (Align => 4);

      --  binary data part (no explicit null byte required)
      String'Write (Stream (Item.File), Target);
      Item.Inc_Offset (Offset => Target'Length);
      Item.CPIO_Write_Padding (Align => 4);
   end CPIO_Make_Symlink;

   -------------------------------------------------------------------------

   procedure CPIO_Make_FIFO
     (Item  : in out CPIO_Archive_Type;
      Name  :        String;
      Mode  :        Unsigned_32;
      UID   :        Unsigned_32;
      GID   :        Unsigned_32;
      MTime :        Time)
   is
      Header : CPIO_Header_Type;
   begin
      if not Is_Open (File => Item.File) then
         raise CPIO_Not_Initialized with
           "CPIO_Make_FIFO called on uninitialized archive";
      end if;

      Header :=
        CPIO_Header_Type'(Inode    => Unsigned_32 (Item.CPIO_Get_Next_Inode),
                          Mode     => Encode_Mode (S_IFIFO, Mode),
                          UID      => UID,
                          GID      => GID,
                          NLink    => 1,
                          MTime    => Encode_MTime (MTime),
                          Major    => 3,
                          Minor    => 1,
                          NameSize => Name'Length + 1,
                          others   => 0);

      Item.CPIO_Write_Header (Header => Header);
      Item.CPIO_Write_String (Name => Name);
      Item.CPIO_Write_Padding (Align => 4);
   end CPIO_Make_FIFO;

   -------------------------------------------------------------------------

   procedure CPIO_Make_Blockdevice
     (Item  : in out CPIO_Archive_Type;
      Name  :        String;
      Mode  :        Unsigned_32;
      UID   :        Unsigned_32;
      GID   :        Unsigned_32;
      Major :        Unsigned_32;
      Minor :        Unsigned_32;
      MTime :        Time)
   is
      Header : CPIO_Header_Type;
   begin
      if not Is_Open (File => Item.File) then
         raise CPIO_Not_Initialized with
           "CPIO_Make_Blockdevice called on uninitialized archive";
      end if;

      Header :=
        CPIO_Header_Type'(Inode    => Unsigned_32 (Item.CPIO_Get_Next_Inode),
                          Mode     => Encode_Mode (S_IFBLK, Mode),
                          UID      => UID,
                          GID      => GID,
                          NLink    => 1,
                          MTime    => Encode_MTime (MTime),
                          Major    => 3,
                          Minor    => 1,
                          RMajor   => Major,
                          RMinor   => Minor,
                          NameSize => Name'Length + 1,
                          others   => 0);

      Item.CPIO_Write_Header (Header => Header);
      Item.CPIO_Write_String (Name => Name);
      Item.CPIO_Write_Padding (Align => 4);
   end CPIO_Make_Blockdevice;

   -------------------------------------------------------------------------

   procedure CPIO_Make_Chardevice
     (Item  : in out CPIO_Archive_Type;
      Name  :        String;
      Mode  :        Unsigned_32;
      UID   :        Unsigned_32;
      GID   :        Unsigned_32;
      Major :        Unsigned_32;
      Minor :        Unsigned_32;
      MTime :        Time)
   is
      Header : CPIO_Header_Type;
   begin
      if not Is_Open (File => Item.File) then
         raise CPIO_Not_Initialized with
           "CPIO_Make_Chardevice called on uninitialized archive";
      end if;

      Header :=
        CPIO_Header_Type'(Inode    => Unsigned_32 (Item.CPIO_Get_Next_Inode),
                          Mode     => Encode_Mode (S_IFCHR, Mode),
                          UID      => UID,
                          GID      => GID,
                          NLink    => 1,
                          MTime    => Encode_MTime (MTime),
                          Major    => 3,
                          Minor    => 1,
                          RMajor   => Major,
                          RMinor   => Minor,
                          NameSize => Name'Length + 1,
                          others   => 0);

      Item.CPIO_Write_Header (Header => Header);
      Item.CPIO_Write_String (Name => Name);
      Item.CPIO_Write_Padding (Align => 4);
   end CPIO_Make_Chardevice;

   -------------------------------------------------------------------------

   procedure CPIO_Create
     (Item : in out CPIO_Archive_Type;
      Name :        String)
   is
   begin
      if Is_Open (Item.File) then
         raise Ada.IO_Exceptions.Status_Error with
           "CPIO_Create called on an open archive";
      end if;
      Item.Inode  := CPIO_First_Inode;
      Item.Offset := 0;
      Create (File => Item.File,
              Mode => Out_File,
              Name => Name,
              Form => "shared=no");
   end CPIO_Create;

   -------------------------------------------------------------------------

   procedure CPIO_Close
     (Item : in out CPIO_Archive_Type)
   is
   begin
      if not Is_Open (File => Item.File) then
         raise CPIO_Not_Initialized with
           "CPIO_Close called on uninitialized archive";
      end if;

      Item.CPIO_Write_Trailer;
      Close (File => Item.File);
      Item.Inode  := 0;
      Item.Offset := 0;
   end CPIO_Close;

end Arca.CPIO;
