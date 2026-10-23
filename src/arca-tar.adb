--  SPDX-License-Identifier: GPL-2.0-or-later
--  Copyright (C) 2008-2026 secunet Security Networks AG
--  Derived from Abuild; see doc/licensing.md

with Ada.Calendar.Conversions;
with Ada.Calendar.Formatting;
with Ada.Characters.Latin_1;
with Ada.Directories;
with Ada.IO_Exceptions;
with Ada.Streams;

with Arca.Binary_IO;

package body Arca.TAR is

   use Arca.Binary_IO;
   use Ada.Streams;
   use type Ada.Directories.File_Size;

   Regular_Type    : constant Character := '0';
   Hardlink_Type   : constant Character := '1';
   Symlink_Type    : constant Character := '2';
   Char_Type       : constant Character := '3';
   Block_Type      : constant Character := '4';
   Directory_Type  : constant Character := '5';
   FIFO_Type       : constant Character := '6';
   Long_Name_Type  : constant Character := 'L';
   Long_Link_Type  : constant Character := 'K';

   USTAR_Magic     : constant String :=
     "ustar" & Ada.Characters.Latin_1.NUL;
   USTAR_Version   : constant String := "00";
   GNU_Long_Name   : constant String := "././@LongLink";

   --  Writer overview
   --
   --  Every archive entry starts with exactly one 512-byte header block and
   --  is followed by zero or more 512-byte payload blocks. Regular file data
   --  is padded with NUL bytes up to the next 512-byte boundary, and the
   --  archive ends with two all-zero blocks.
   --
   --  This implementation writes POSIX ustar headers (`magic = "ustar\0"`,
   --  `version = "00"`) and only falls back to the GNU LongLink / LongName
   --  extension for path or link targets that do not fit into the standard
   --  `name` / `prefix` fields.
   --
   --  The old libtar based path used TAR_GNU mode, which encoded the magic
   --  field as `ustar  `, stored file type bits in the numeric mode field
   --  and emitted GNU LongName/LongLink records more eagerly. The native
   --  writer intentionally keeps the same archive semantics while writing
   --  cleaner POSIX ustar headers: type information lives in `typeflag`,
   --  mode contains only permission bits, unused bytes are NUL-filled, and
   --  GNU metadata records are reserved for names that ustar cannot express.
   --
   --  Header block layout (1-based indices in this Ada implementation):
   --
   --    1 .. 100   name
   --  101 .. 108   mode
   --  109 .. 116   uid
   --  117 .. 124   gid
   --  125 .. 136   size
   --  137 .. 148   mtime
   --  149 .. 156   chksum
   --        157    typeflag
   --  158 .. 257   linkname
   --  258 .. 263   magic
   --  264 .. 265   version
   --  266 .. 297   uname
   --  298 .. 329   gname
   --  330 .. 337   devmajor
   --  338 .. 345   devminor
   --  346 .. 500   prefix
   --  501 .. 512   padding
   --
   --  In the common case a long pathname is first mapped to the POSIX
   --  `prefix` + `name` split. Only if no slash exists that satisfies
   --  `prefix <= 155` and `name <= 100` do we emit a GNU long-name record.
   --  Numeric fields contain zero-padded ASCII octal digits and NUL. The
   --  checksum sums all 512 unsigned header bytes with its own field treated
   --  as spaces, then stores six octal digits, NUL and space. Reserved bytes
   --  remain NUL. Normative ustar and GNU references are linked in doc/tar.md.
   Name_First      : constant Positive := 1;
   Name_Last       : constant Positive := 100;
   Mode_First      : constant Positive := 101;
   Mode_Last       : constant Positive := 108;
   UID_First       : constant Positive := 109;
   UID_Last        : constant Positive := 116;
   GID_First       : constant Positive := 117;
   GID_Last        : constant Positive := 124;
   Size_First      : constant Positive := 125;
   Size_Last       : constant Positive := 136;
   MTime_First     : constant Positive := 137;
   MTime_Last      : constant Positive := 148;
   Chk_First       : constant Positive := 149;
   Chk_Last        : constant Positive := 156;
   Type_Pos        : constant Positive := 157;
   Link_First      : constant Positive := 158;
   Link_Last       : constant Positive := 257;
   Magic_First     : constant Positive := 258;
   Magic_Last      : constant Positive := 263;
   Version_First   : constant Positive := 264;
   Version_Last    : constant Positive := 265;
   DevMajor_First  : constant Positive := 330;
   DevMajor_Last   : constant Positive := 337;
   DevMinor_First  : constant Positive := 338;
   DevMinor_Last   : constant Positive := 345;
   Prefix_First    : constant Positive := 346;
   Prefix_Last     : constant Positive := 500;

   Permission_Mask       : constant Unsigned_32 := 8#7777#;
   Max_Field_12          : constant Long_Long_Integer := 8 ** 11 - 1;
   Name_Field_Length     : constant Natural := Name_Last - Name_First + 1;
   Link_Field_Length     : constant Natural := Link_Last - Link_First + 1;
   Prefix_Field_Length   : constant Natural := Prefix_Last - Prefix_First + 1;
   Long_Metadata_Mode    : constant Unsigned_32 := 8#644#;
   Unix_Epoch            : constant Time
     := Ada.Calendar.Formatting.Time_Of
       (Year      => 1970,
        Month     => 1,
        Day       => 1,
        Seconds   => 0.0,
        Time_Zone => 0);
   --  UTC UNIX epoch used for GNU long metadata records.

   subtype Header_Block is String (1 .. Block_Size);

   type Octal_Overflow_Kind is
     (Metadata_Overflow,
      Size_Overflow);

   type Optional_String_Slice is record
      Present : Boolean;
      First   : Positive;
      Last    : Natural;
   end record;

   function Make_Slice
     (First : Positive;
      Last  : Natural)
      return Optional_String_Slice;
   --  Return an explicit slice descriptor instead of using sentinel indexes.

   function No_Slice (First : Positive) return Optional_String_Slice;
   --  Return a non-present slice anchored at First for valid index defaults.

   procedure Require_Initialized (Item : TAR_Archive_Type);
   --  Raise if the archive file has not been opened yet.

   procedure Write_Block
     (Item : in out TAR_Archive_Type;
      Data :        String);
   --  Write one already-sized TAR block or payload fragment.

   procedure Write_Padding
     (Item       : in out TAR_Archive_Type;
      Data_Size  :        Ada.Directories.File_Size);
   --  Pad the current payload to the next TAR block boundary.

   procedure Copy_File_Data
     (Item        : in out TAR_Archive_Type;
      Source_Name :        String;
      Source_Size :        Ada.Directories.File_Size);
   --  Copy a regular file payload and verify that the expected size was read.

   procedure Write_Long_Metadata
     (Item      : in out TAR_Archive_Type;
      Value     :        String;
      Typeflag  :        Character);
   --  Emit a GNU LongLink/LongName metadata entry for the following header.

   procedure Write_Header
     (Item       : in out TAR_Archive_Type;
      Name       :        String;
      Link_Name  :        String;
      Typeflag   :        Character;
      Mode       :        Unsigned_32;
      UID        :        Unsigned_32;
      GID        :        Unsigned_32;
      Size       :        Long_Long_Integer;
      MTime      :        Time;
      Major      :        Unsigned_32 := 0;
      Minor      :        Unsigned_32 := 0);
   --  Write the ustar header, including optional GNU long metadata records.

   procedure Make_Device
     (Item     : in out TAR_Archive_Type;
      Name     :        String;
      Typeflag :        Character;
      Mode     :        Unsigned_32;
      UID      :        Unsigned_32;
      GID      :        Unsigned_32;
      Major    :        Unsigned_32;
      Minor    :        Unsigned_32;
      MTime    :        Time);
   --  Add a device entry shared by block and character devices.

   function Directory_Header_Name (Name : String) return String;
   --  Add a trailing slash when absent; retain existing trailing separators.

   function Find_Split_Position (Path : String) return Natural;
   --  Return a slash where Path can be split into prefix/name fields.

   procedure Put_String
     (Header : in out Header_Block;
      First  :        Positive;
      Last   :        Positive;
      Value  :        String);
   --  Copy a string into a fixed-width header field, truncating if needed.

   procedure Put_Octal
     (Header    : in out Header_Block;
      First     :        Positive;
      Last      :        Positive;
      Value     :        Long_Long_Integer;
      Overflow  :        Octal_Overflow_Kind := Metadata_Overflow;
      Checksum  :        Boolean := False);
   --  Encode a numeric header field using tar's NUL-terminated octal format.

   procedure Put_Octal_Digits
     (Header    : in out Header_Block;
      First     :        Positive;
      Last      :        Positive;
      Value     :        Long_Long_Integer;
      Overflow  :        Octal_Overflow_Kind);
   --  Write a non-negative number to an already-sized octal digit field.

   procedure Raise_Octal_Overflow (Kind : Octal_Overflow_Kind);
   --  Raise the exception that matches the overflowing numeric field class.

   function Compute_Checksum (Header : Header_Block) return Long_Long_Integer;
   --  Sum all header bytes after the checksum field has been filled with
   --  spaces, matching the tar checksum algorithm.

   ----------------------------------------------------------------------

   overriding procedure Finalize (Item : in out TAR_Archive_Type)
   is
   begin
      Arca.Binary_IO.Discard_Output (Item.File);
   end Finalize;

   ----------------------------------------------------------------------

   procedure Require_Initialized (Item : TAR_Archive_Type)
   is
   begin
      if not Is_Open (File => Item.File) then
         raise TAR_Not_Initialized;
      end if;
   end Require_Initialized;

   ----------------------------------------------------------------------

   function Make_Slice
     (First : Positive;
      Last  : Natural)
      return Optional_String_Slice
   is
   begin
      return Optional_String_Slice'
        (Present => Last >= First,
         First   => First,
         Last    => Last);
   end Make_Slice;

   ----------------------------------------------------------------------

   function No_Slice (First : Positive) return Optional_String_Slice
   is
   begin
      return Optional_String_Slice'
        (Present => False,
         First   => First,
         Last    => 0);
   end No_Slice;

   ----------------------------------------------------------------------

   procedure Raise_Octal_Overflow (Kind : Octal_Overflow_Kind)
   is
   begin
      case Kind is
         when Size_Overflow =>
            raise File_Too_Big;
         when Metadata_Overflow =>
            raise Unsupported_Metadata;
      end case;
   end Raise_Octal_Overflow;

   ----------------------------------------------------------------------

   procedure Put_Octal_Digits
     (Header    : in out Header_Block;
      First     :        Positive;
      Last      :        Positive;
      Value     :        Long_Long_Integer;
      Overflow  :        Octal_Overflow_Kind)
   is
      Temp : Long_Long_Integer := Value;
   begin
      if Temp < 0 then
         raise Unsupported_Metadata;
      end if;

      for Index in reverse First .. Last loop
         exit when Temp = 0;
         Header (Index) := Character'Val
           (Character'Pos ('0') + Integer (Temp mod 8));
         Temp := Temp / 8;
      end loop;

      if Temp /= 0 then
         Raise_Octal_Overflow (Kind => Overflow);
      end if;
   end Put_Octal_Digits;

   ----------------------------------------------------------------------

   procedure Put_String
     (Header : in out Header_Block;
      First  :        Positive;
      Last   :        Positive;
      Value  :        String)
   is
      Max_Length : constant Natural := Last - First + 1;
      Length     : constant Natural
        := Natural'Min (Value'Length, Max_Length);
   begin
      if Length > 0 then
         Header (First .. First + Length - 1)
           := Value (Value'First .. Value'First + Length - 1);
      end if;
   end Put_String;

   ----------------------------------------------------------------------

   procedure Put_Octal
     (Header    : in out Header_Block;
      First     :        Positive;
      Last      :        Positive;
      Value     :        Long_Long_Integer;
      Overflow  :        Octal_Overflow_Kind := Metadata_Overflow;
      Checksum  :        Boolean := False)
   is
      Digit_Last : Positive := Last - 1;
   begin
      Header (First .. Last) := (others => '0');

      if Checksum then
         --  The tar checksum field is special: it contains six octal digits,
         --  followed by NUL and a trailing space instead of only NUL.
         Header (First .. Last) := (others => ' ');
         Digit_Last := Last - 2;
         Header (First .. Digit_Last) := (others => '0');
         Put_Octal_Digits
           (Header   => Header,
            First    => First,
            Last     => Digit_Last,
            Value    => Value,
            Overflow => Overflow);
         Header (Last - 1) := Ada.Characters.Latin_1.NUL;
         Header (Last) := ' ';
      else
         Put_Octal_Digits
           (Header   => Header,
            First    => First,
            Last     => Last - 1,
            Value    => Value,
            Overflow => Overflow);
         Header (Last) := Ada.Characters.Latin_1.NUL;
      end if;
   end Put_Octal;

   ----------------------------------------------------------------------

   function Compute_Checksum (Header : Header_Block) return Long_Long_Integer
   is
      Result : Long_Long_Integer := 0;
   begin
      for C of Header loop
         Result := Result + Character'Pos (C);
      end loop;

      return Result;
   end Compute_Checksum;

   ----------------------------------------------------------------------

   procedure Write_Block
     (Item : in out TAR_Archive_Type;
      Data :        String)
   is
   begin
      String'Write (Stream (Item.File), Data);
   end Write_Block;

   ----------------------------------------------------------------------

   procedure Write_Padding
     (Item       : in out TAR_Archive_Type;
      Data_Size  :        Ada.Directories.File_Size)
   is
      Padding : constant Ada.Directories.File_Size
        := (Ada.Directories.File_Size (Block_Size)
            - (Data_Size mod Ada.Directories.File_Size (Block_Size)))
           mod Ada.Directories.File_Size (Block_Size);
   begin
      if Padding > 0 then
         String'Write
           (Stream (Item.File),
            String'(1 .. Integer (Padding) => Ada.Characters.Latin_1.NUL));
      end if;
   end Write_Padding;

   ----------------------------------------------------------------------

   procedure Copy_File_Data
     (Item        : in out TAR_Archive_Type;
      Source_Name :        String;
      Source_Size :        Ada.Directories.File_Size)
   is
   begin
      Copy_File_To_Stream
        (Source_Name => Source_Name,
         Source_Size => Source_Size,
         Target      => Item.File);
   exception
      when Ada.IO_Exceptions.End_Error =>
         raise File_Read_Error;
   end Copy_File_Data;

   ----------------------------------------------------------------------

   function Find_Split_Position (Path : String) return Natural
   is
   begin
      for Index in reverse Path'Range loop
         if Path (Index) = '/'
           and then Index > Path'First
           and then Index - Path'First <= Prefix_Field_Length
           and then Path'Last - Index > 0
           and then Path'Last - Index <= Name_Field_Length
         then
            return Index;
         end if;
      end loop;

      return 0;
   end Find_Split_Position;

   ----------------------------------------------------------------------

   procedure Write_Long_Metadata
     (Item      : in out TAR_Archive_Type;
      Value     :        String;
      Typeflag  :        Character)
   is
   begin
      --  GNU tar extension:
      --  write a synthetic "././@LongLink" entry whose payload contains the
      --  full path or link target for the following header.
      Write_Header (Item      => Item,
                    Name      => GNU_Long_Name,
                    Link_Name => "",
                    Typeflag  => Typeflag,
                    Mode      => Long_Metadata_Mode,
                    UID       => 0,
                    GID       => 0,
                    Size      => Long_Long_Integer (Value'Length + 1),
                    MTime     => Unix_Epoch);
      Write_Block
        (Item => Item, Data => Value & Ada.Characters.Latin_1.NUL);
      Write_Padding
        (Item      => Item,
         Data_Size => Ada.Directories.File_Size (Value'Length + 1));
   end Write_Long_Metadata;

   ----------------------------------------------------------------------

   procedure Write_Header
     (Item       : in out TAR_Archive_Type;
      Name       :        String;
      Link_Name  :        String;
      Typeflag   :        Character;
      Mode       :        Unsigned_32;
      UID        :        Unsigned_32;
      GID        :        Unsigned_32;
      Size       :        Long_Long_Integer;
      MTime      :        Time;
      Major      :        Unsigned_32 := 0;
      Minor      :        Unsigned_32 := 0)
   is
      Header        : Header_Block :=
        (others => Ada.Characters.Latin_1.NUL);
      --  Write source slices directly in this per-entry hot path. Bounded
      --  header fields only need indexes, so avoid heap-backed temporaries.
      Stored_Name   : Optional_String_Slice :=
        Make_Slice (Name'First, Name'Last);
      Stored_Link   : Optional_String_Slice :=
        Make_Slice (Link_Name'First, Link_Name'Last);
      Use_Long_Link_Marker : Boolean := False;
      Stored_Prefix        : Optional_String_Slice := No_Slice (Name'First);
      Header_Time          : constant Long_Long_Integer
        := Long_Long_Integer (Ada.Calendar.Conversions.To_Unix_Time (MTime));
   begin
      if Name'Length > Name_Field_Length then
         declare
            Slash_Pos : constant Natural := Find_Split_Position (Name);
         begin
            if Slash_Pos /= 0 then
               Stored_Name := Make_Slice (Slash_Pos + 1, Name'Last);
               Stored_Prefix := Make_Slice (Name'First, Slash_Pos - 1);
            else
               Write_Long_Metadata (Item     => Item,
                                    Value    => Name,
                                    Typeflag => Long_Name_Type);
               Stored_Name :=
                 Make_Slice (Name'First,
                             Name'First + Name_Field_Length - 1);
            end if;
         end;
      end if;

      if Link_Name'Length > Link_Field_Length then
         Write_Long_Metadata (Item     => Item,
                              Value    => Link_Name,
                              Typeflag => Long_Link_Type);
         Stored_Link := No_Slice (Link_Name'First);
         Use_Long_Link_Marker := True;
      end if;

      if Stored_Name.Present then
         Put_String
           (Header => Header,
            First  => Name_First,
            Last   => Name_Last,
            Value  => Name (Stored_Name.First .. Stored_Name.Last));
      end if;
      Put_Octal (Header => Header,
                 First  => Mode_First,
                 Last   => Mode_Last,
                 Value  => Long_Long_Integer (Mode and Permission_Mask));
      Put_Octal (Header => Header,
                 First  => UID_First,
                 Last   => UID_Last,
                 Value  => Long_Long_Integer (UID));
      Put_Octal (Header => Header,
                 First  => GID_First,
                 Last   => GID_Last,
                 Value  => Long_Long_Integer (GID));
      Put_Octal (Header => Header,
                 First  => Size_First,
                 Last   => Size_Last,
                 Value  => Size,
                 Overflow => Size_Overflow);
      Put_Octal (Header => Header,
                 First  => MTime_First,
                 Last   => MTime_Last,
                 Value  => Header_Time);
      Header (Chk_First .. Chk_Last) := (others => ' ');
      Header (Type_Pos) := Typeflag;
      if Use_Long_Link_Marker then
         Put_String
           (Header => Header,
            First  => Link_First,
            Last   => Link_Last,
            Value  => GNU_Long_Name);
      elsif Stored_Link.Present then
         Put_String
           (Header => Header,
            First  => Link_First,
            Last   => Link_Last,
            Value  => Link_Name (Stored_Link.First .. Stored_Link.Last));
      end if;
      Put_String (Header => Header,
                  First  => Magic_First,
                  Last   => Magic_Last,
                  Value  => USTAR_Magic);
      Put_String (Header => Header,
                  First  => Version_First,
                  Last   => Version_Last,
                  Value  => USTAR_Version);
      Put_Octal (Header => Header,
                 First  => DevMajor_First,
                 Last   => DevMajor_Last,
                 Value  => Long_Long_Integer (Major));
      Put_Octal (Header => Header,
                 First  => DevMinor_First,
                 Last   => DevMinor_Last,
                 Value  => Long_Long_Integer (Minor));
      if Stored_Prefix.Present then
         Put_String
           (Header => Header,
            First  => Prefix_First,
            Last   => Prefix_Last,
            Value  => Name (Stored_Prefix.First .. Stored_Prefix.Last));
      end if;

      Put_Octal (Header    => Header,
                 First     => Chk_First,
                 Last      => Chk_Last,
                 Value     => Compute_Checksum (Header),
                 Checksum  => True);

      Write_Block (Item => Item, Data => Header);
   end Write_Header;

   ----------------------------------------------------------------------

   procedure Make_Device
     (Item     : in out TAR_Archive_Type;
      Name     :        String;
      Typeflag :        Character;
      Mode     :        Unsigned_32;
      UID      :        Unsigned_32;
      GID      :        Unsigned_32;
      Major    :        Unsigned_32;
      Minor    :        Unsigned_32;
      MTime    :        Time)
   is
   begin
      Require_Initialized (Item);
      Write_Header (Item      => Item,
                    Name      => Name,
                    Link_Name => "",
                    Typeflag  => Typeflag,
                    Mode      => Mode,
                    UID       => UID,
                    GID       => GID,
                    Size      => 0,
                    MTime     => MTime,
                    Major     => Major,
                    Minor     => Minor);
   end Make_Device;

   ----------------------------------------------------------------------

   function Directory_Header_Name (Name : String) return String
   is
   begin
      if Name'Length > 0 and then Name (Name'Last) = '/' then
         return Name;
      end if;

      return Name & "/";
   end Directory_Header_Name;

   ----------------------------------------------------------------------

   procedure TAR_Create
     (Item : in out TAR_Archive_Type;
      Name :        String)
   is
   begin
      if Is_Open (Item.File) then
         raise Ada.IO_Exceptions.Status_Error with
           "TAR_Create called on an open archive";
      end if;
      Create (File => Item.File,
              Mode => Out_File,
              Name => Name,
              Form => "shared=no");
   end TAR_Create;

   ----------------------------------------------------------------------

   procedure TAR_Close (Item : in out TAR_Archive_Type)
   is
      Zero_Block : constant Header_Block :=
        (others => Ada.Characters.Latin_1.NUL);
   begin
      Require_Initialized (Item);
      Write_Block (Item => Item, Data => Zero_Block);
      Write_Block (Item => Item, Data => Zero_Block);
      Close (File => Item.File);
   end TAR_Close;

   ----------------------------------------------------------------------

   procedure TAR_Make_File
     (Item   : in out TAR_Archive_Type;
      Name   :        String;
      Source :        String;
      Mode   :        Unsigned_32;
      UID    :        Unsigned_32;
      GID    :        Unsigned_32;
      MTime  :        Time)
   is
      Source_Size : Ada.Directories.File_Size;
   begin
      Require_Initialized (Item);

      if not Ada.Directories.Exists (Name => Source) then
         raise File_Not_Found;
      end if;

      Source_Size := Ada.Directories.Size (Name => Source);
      if Long_Long_Integer (Source_Size) > Max_Field_12 then
         raise File_Too_Big;
      end if;

      Write_Header (Item      => Item,
                    Name      => Name,
                    Link_Name => "",
                    Typeflag  => Regular_Type,
                    Mode      => Mode,
                    UID       => UID,
                    GID       => GID,
                    Size      => Long_Long_Integer (Source_Size),
                    MTime     => MTime);
      Copy_File_Data (Item        => Item,
                      Source_Name => Source,
                      Source_Size => Source_Size);
      Write_Padding (Item      => Item,
                     Data_Size => Source_Size);
   end TAR_Make_File;

   ----------------------------------------------------------------------

   procedure TAR_Make_Hardlink
     (Item   : in out TAR_Archive_Type;
      Name   :        String;
      Target :        String;
      Mode   :        Unsigned_32;
      UID    :        Unsigned_32;
      GID    :        Unsigned_32;
      MTime  :        Time)
   is
   begin
      Require_Initialized (Item);
      Write_Header (Item      => Item,
                    Name      => Name,
                    Link_Name => Target,
                    Typeflag  => Hardlink_Type,
                    Mode      => Mode,
                    UID       => UID,
                    GID       => GID,
                    Size      => 0,
                    MTime     => MTime);
   end TAR_Make_Hardlink;

   ----------------------------------------------------------------------

   procedure TAR_Make_Symlink
     (Item   : in out TAR_Archive_Type;
      Name   :        String;
      Target :        String;
      Mode   :        Unsigned_32;
      UID    :        Unsigned_32;
      GID    :        Unsigned_32;
      MTime  :        Time)
   is
   begin
      Require_Initialized (Item);
      Write_Header (Item      => Item,
                    Name      => Name,
                    Link_Name => Target,
                    Typeflag  => Symlink_Type,
                    Mode      => Mode,
                    UID       => UID,
                    GID       => GID,
                    Size      => 0,
                    MTime     => MTime);
   end TAR_Make_Symlink;

   ----------------------------------------------------------------------

   procedure TAR_Make_Directory
     (Item  : in out TAR_Archive_Type;
      Name  :        String;
      Mode  :        Unsigned_32;
      UID   :        Unsigned_32;
      GID   :        Unsigned_32;
      MTime :        Time)
   is
      Header_Name : constant String := Directory_Header_Name (Name);
   begin
      Require_Initialized (Item);
      Write_Header (Item      => Item,
                    Name      => Header_Name,
                    Link_Name => "",
                    Typeflag  => Directory_Type,
                    Mode      => Mode,
                    UID       => UID,
                    GID       => GID,
                    Size      => 0,
                    MTime     => MTime);
   end TAR_Make_Directory;

   ----------------------------------------------------------------------

   procedure TAR_Make_FIFO
     (Item  : in out TAR_Archive_Type;
      Name  :        String;
      Mode  :        Unsigned_32;
      UID   :        Unsigned_32;
      GID   :        Unsigned_32;
      MTime :        Time)
   is
   begin
      Require_Initialized (Item);
      Write_Header (Item      => Item,
                    Name      => Name,
                    Link_Name => "",
                    Typeflag  => FIFO_Type,
                    Mode      => Mode,
                    UID       => UID,
                    GID       => GID,
                    Size      => 0,
                    MTime     => MTime);
   end TAR_Make_FIFO;

   ----------------------------------------------------------------------

   procedure TAR_Make_Block_Device
     (Item  : in out TAR_Archive_Type;
      Name  :        String;
      Mode  :        Unsigned_32;
      UID   :        Unsigned_32;
      GID   :        Unsigned_32;
      Major :        Unsigned_32;
      Minor :        Unsigned_32;
      MTime :        Time)
   is
   begin
      Make_Device (Item     => Item,
                   Name     => Name,
                   Typeflag => Block_Type,
                   Mode     => Mode,
                   UID      => UID,
                   GID      => GID,
                   Major    => Major,
                   Minor    => Minor,
                   MTime    => MTime);
   end TAR_Make_Block_Device;

   ----------------------------------------------------------------------

   procedure TAR_Make_Char_Device
     (Item  : in out TAR_Archive_Type;
      Name  :        String;
      Mode  :        Unsigned_32;
      UID   :        Unsigned_32;
      GID   :        Unsigned_32;
      Major :        Unsigned_32;
      Minor :        Unsigned_32;
      MTime :        Time)
   is
   begin
      Make_Device (Item     => Item,
                   Name     => Name,
                   Typeflag => Char_Type,
                   Mode     => Mode,
                   UID      => UID,
                   GID      => GID,
                   Major    => Major,
                   Minor    => Minor,
                   MTime    => MTime);
   end TAR_Make_Char_Device;

end Arca.TAR;
