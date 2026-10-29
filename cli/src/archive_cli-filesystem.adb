--  SPDX-License-Identifier: GPL-2.0-or-later

with Ada.Directories;
with Ada.Interrupts;
with Ada.Interrupts.Names;
with Archive_CLI.Diagnostics;
with GNAT.OS_Lib;
with Interfaces.C.Strings;

package body Archive_CLI.Filesystem is

   package C renames Interfaces.C;

   use type C.long;
   use type C.Strings.chars_ptr;
   use type Interfaces.Unsigned_32;

   function C_Rename_Noreplace return C.unsigned
     with Import, Convention => C, External_Name => "arca_rename_noreplace";
   --  Read the target header's no-replace rename flag.

   function C_EINVAL return C.int
     with Import, Convention => C, External_Name => "arca_einval";
   --  Read the target header's invalid-argument errno value.

   function C_ENOSYS return C.int
     with Import, Convention => C, External_Name => "arca_enosys";
   --  Read the target header's unavailable-system-call errno value.

   function C_EOPNOTSUPP return C.int
     with Import, Convention => C, External_Name => "arca_eopnotsupp";
   --  Read the target header's unsupported-operation errno value.

   function C_ENOENT return C.int
     with Import, Convention => C, External_Name => "arca_enoent";
   --  Read the target header's absent-path errno value.

   function C_Directory_Flags return C.int
     with Import, Convention => C, External_Name => "arca_directory_flags";
   --  Read target flags for no-follow, close-on-exec directory capabilities.

   function C_Archive_Flags return C.int
     with Import, Convention => C, External_Name => "arca_archive_flags";
   --  Read target flags for exclusive, no-follow archive reservation.

   function C_Remove_Directory return C.int
     with Import, Convention => C, External_Name => "arca_remove_directory";
   --  Read the target header flag for nonrecursive directory removal.

   Directory_Flags        : constant C.int := C_Directory_Flags;
   Archive_Flags          : constant C.int := C_Archive_Flags;
   Remove_Directory       : constant C.int := C_Remove_Directory;
   Rename_No_Replace      : constant C.unsigned := C_Rename_Noreplace;
   Invalid_Argument       : constant C.int := C_EINVAL;
   Not_Implemented        : constant C.int := C_ENOSYS;
   Operation_Unsupported  : constant C.int := C_EOPNOTSUPP;
   Missing_Path           : constant C.int := C_ENOENT;

   protected Cancellation is

      procedure Handle_Interrupt
        with Interrupt_Handler;
      --  Record SIGINT without filesystem work or exception propagation.

      procedure Handle_Termination
        with Interrupt_Handler;
      --  Record SIGTERM for cleanup at the next command boundary.

      procedure Handle_Hangup
        with Interrupt_Handler;
      --  Record SIGHUP for cleanup at the next command boundary.

      function Number return Natural;
      --  Read the process-owned signal state through protected access.

   private

      pragma Interrupt_State (Ada.Interrupts.Names.SIGINT, User);
      pragma Interrupt_State (Ada.Interrupts.Names.SIGTERM, User);
      pragma Interrupt_State (Ada.Interrupts.Names.SIGHUP, User);

      Last_Signal : Natural := 0;
   end Cancellation;

   function C_Stat (Name : C.char_array; Item : access Metadata) return C.int
     with Import, Convention => C, External_Name => "arca_lstat";
   --  Return an errno value and an explicitly sized metadata record.

   function C_Readlink
     (Name     :     C.char_array;
      Buffer   : out C.char_array;
      Capacity :     C.size_t)
      return C.long
     with Import, Convention => C, External_Name => "readlink";
   --  Return a byte count without a NUL, or -1; Linux64 ssize_t is long.

   function C_Mkdtemp
     (Buffer : in out C.char_array) return C.Strings.chars_ptr
     with Import, Convention => C, External_Name => "mkdtemp";
   --  Atomically create the private directory described by the template.
   --  Success points into Buffer and must not be freed; null reports failure.

   function C_Renameat
     (Source_FD : C.int;
      Source    : C.char_array;
      Target_FD : C.int;
      Target    : C.char_array)
      return C.int
     with Import, Convention => C, External_Name => "renameat";
   --  Atomically replace Target on the same filesystem; return zero or -1.

   function C_Linkat
     (Source_FD : C.int;
      Source    : C.char_array;
      Target_FD : C.int;
      Target    : C.char_array;
      Flags     : C.int)
      return C.int
     with Import, Convention => C, External_Name => "linkat";
   --  Publish another name for a closed file without replacing any target.

   function C_Open (Name : C.char_array; Flags : C.int) return C.int
     with Import, Convention => C_Variadic_2, External_Name => "open";
   --  Open a directory without creation; O_PATH permits write/search parents.

   function C_Openat
     (Directory_FD : C.int;
      Name         : C.char_array;
      Flags        : C.int;
      Mode         : C.unsigned)
      return C.int
     with Import, Convention => C_Variadic_3, External_Name => "openat";
   --  Reserve one fresh archive entry relative to an owned directory.

   function C_Close (FD : C.int) return C.int
     with Import, Convention => C, External_Name => "close";
   --  Release a descriptor once; Linux closes it even for delayed errors.

   function C_Unlinkat
     (Directory_FD : C.int; Name : C.char_array; Flags : C.int) return C.int
     with Import, Convention => C, External_Name => "unlinkat";
   --  Remove a single entry; directory removal never recursively follows it.

   function C_Geteuid return C.unsigned
     with Import, Convention => C, External_Name => "geteuid";
   --  Identify the effective owner required for inaccessible private staging.

   function C_Renameat2
     (Source_FD : C.int;
      Source    : C.char_array;
      Target_FD : C.int;
      Target    : C.char_array;
      Flags     : C.unsigned)
      return C.int
     with Import, Convention => C, External_Name => "renameat2";
   --  Apply Linux rename flags and return zero or -1 with errno on failure.

   function C_Strerror (Code : C.int) return C.Strings.chars_ptr
     with Import, Convention => C, External_Name => "strerror";
   --  Read libc's static diagnostic for an errno value; do not free it.

   function Errno_On_Failure (Result : C.int) return C.int;
   --  Capture a zero/-1 call's errno before allocating diagnostic strings.

   procedure Require (Code : C.int; Context : String);
   --  Map a captured errno value to a contextual command diagnostic.

   function Published_Link (Source : Metadata; Target : String) return Boolean;
   --  Resolve an ambiguous NFS link reply only for the same regular inode.

   function Descriptor_Path (FD : C.int) return String;
   --  Name a nonnegative retained descriptor without resolving its pathname.

   procedure Close_Descriptor (FD : in out C.int);
   --  Release once without allowing cleanup diagnostics to mask a result.

   procedure Ignore_Error (Code : C.int);
   --  Discard a cleanup syscall result after its side effect was attempted.

   protected body Cancellation
   is

      procedure Handle_Interrupt
      is
      begin
         Last_Signal := Natural (Ada.Interrupts.Names.SIGINT);
      end Handle_Interrupt;

      ----------------------------------------------------------------------

      procedure Handle_Termination
      is
      begin
         Last_Signal := Natural (Ada.Interrupts.Names.SIGTERM);
      end Handle_Termination;

      ----------------------------------------------------------------------

      procedure Handle_Hangup
      is
      begin
         Last_Signal := Natural (Ada.Interrupts.Names.SIGHUP);
      end Handle_Hangup;

      ----------------------------------------------------------------------

      function Number return Natural
      is
      begin
         return Last_Signal;
      end Number;

   end Cancellation;

   -------------------------------------------------------------------------

   function Errno_On_Failure (Result : C.int) return C.int
   is
   begin
      return (if Result = 0 then 0 else C.int (GNAT.OS_Lib.Errno));
   end Errno_On_Failure;

   -------------------------------------------------------------------------

   procedure Require (Code : C.int; Context : String)
   is
   begin
      if Code /= 0 then
         Diagnostics.Fail_Command
           (Context & ": " & C.Strings.Value (C_Strerror (Code)));
      end if;
   end Require;

   -------------------------------------------------------------------------

   function Published_Link (Source : Metadata; Target : String) return Boolean
   is
      Item : Metadata;
      use type Interfaces.Unsigned_64;
   begin
      return Exists (Target, Item)
        and then Kind (Item) = Regular
        and then Item.Device = Source.Device
        and then Item.Inode = Source.Inode;
   exception
      when Command_Error =>
         --  Verification could not prove publication. Keep the captured link
         --  error instead of replacing it with a secondary inspection error.
         return False;
   end Published_Link;

   -------------------------------------------------------------------------

   function Kind (Item : Metadata) return Entry_Kind
   is
   begin
      if Item.Kind > 6 then
         Diagnostics.Fail_Command ("invalid filesystem node classification");
      end if;

      return Entry_Kind'Val (Item.Kind);
   end Kind;

   -------------------------------------------------------------------------

   function Exists (Name : String; Item : out Metadata) return Boolean
   is
      Value : aliased Metadata;
      Code  : constant C.int := C_Stat (C.To_C (Name), Value'Access);
   begin
      if Code = Missing_Path then
         Item := (others => <>);
         return False;
      end if;

      Require (Code, "cannot inspect '" & Name & "'");
      Item := Value;

      return True;
   end Exists;

   -------------------------------------------------------------------------

   function Stat (Name : String) return Metadata
   is
      Result : Metadata;
   begin
      if not Exists (Name, Result) then
         Diagnostics.Fail_Command ("source does not exist: '" & Name & "'");
      end if;

      return Result;
   end Stat;

   -------------------------------------------------------------------------

   function Canonical (Name : String) return String
   is
      Result : constant String := GNAT.OS_Lib.Normalize_Pathname (Name);
   begin
      if Result = "" then
         Diagnostics.Fail_Command ("cannot resolve path: '" & Name & "'");
      end if;

      return Result;
   end Canonical;

   -------------------------------------------------------------------------

   function Link_Target (Name : String) return String
   is
      Buffer : C.char_array (0 .. Path_Capacity - 1);
      Length : C.long;
   begin
      Length := C_Readlink (C.To_C (Name), Buffer, Buffer'Length);

      if Length < 0 then
         declare
            Code : constant C.int := C.int (GNAT.OS_Lib.Errno);
         begin
            Require (Code, "cannot read symlink '" & Name & "'");
         end;
      elsif Length >= C.long (Buffer'Length) then
         Diagnostics.Fail_Command
           ("symlink target is too long: '" & Name & "'");
      elsif Length = 0 then
         return "";
      end if;

      return C.To_Ada
        (Buffer (0 .. C.size_t (Length) - 1), Trim_Nul => False);
   end Link_Target;

   -------------------------------------------------------------------------

   procedure Install_Signals
   is
   begin
      Ada.Interrupts.Attach_Handler
        (Cancellation.Handle_Interrupt'Access, Ada.Interrupts.Names.SIGINT);
      Ada.Interrupts.Attach_Handler
        (Cancellation.Handle_Termination'Access, Ada.Interrupts.Names.SIGTERM);
      Ada.Interrupts.Attach_Handler
        (Cancellation.Handle_Hangup'Access, Ada.Interrupts.Names.SIGHUP);
   end Install_Signals;

   -------------------------------------------------------------------------

   procedure Check_Interrupted
   is
   begin
      if Cancellation.Number /= 0 then
         raise Interrupted;
      end if;
   end Check_Interrupted;

   -------------------------------------------------------------------------

   function Signal_Number return Natural
   is
   begin
      return Cancellation.Number;
   end Signal_Number;

   -------------------------------------------------------------------------

   function Descriptor_Path (FD : C.int) return String
   is
      Number : constant String := C.int'Image (FD);
   begin
      return "/proc/self/fd/" & Number (2 .. Number'Last);
   end Descriptor_Path;

   -------------------------------------------------------------------------

   procedure Close_Descriptor (FD : in out C.int)
   is
      Previous : constant C.int := FD;
   begin
      FD := -1;

      if Previous >= 0 then
         Ignore_Error (C_Close (Previous));
      end if;
   end Close_Descriptor;

   -------------------------------------------------------------------------

   procedure Ignore_Error (Code : C.int)
   is
      pragma Unreferenced (Code);
   begin
      null;
   end Ignore_Error;

   -------------------------------------------------------------------------

   function Begin_Output (Parent : String) return Transaction
   is
   begin
      return Result : Transaction do
         Result.Parent_FD := C_Open (C.To_C (Parent), Directory_Flags);

         if Result.Parent_FD < 0 then
            Require (C.int (GNAT.OS_Lib.Errno), "cannot open output parent");
         end if;

         declare
            Template : constant C.char_array := C.To_C
              (Descriptor_Path (Result.Parent_FD) & "/.arca-XXXXXX");
         begin
            if Template'Length > Result.Buffer'Length then
               Diagnostics.Fail_Command ("output path is too long");
            end if;

            Result.Buffer (Template'Range) := Template;

            if C_Mkdtemp (Result.Buffer) = C.Strings.Null_Ptr then
               Require
                 (C.int (GNAT.OS_Lib.Errno),
                  "cannot create output staging via /proc/self/fd");
            end if;
         end;

         Result.Active := True;
         Result.Staging_FD := C_Open (Result.Buffer, Directory_Flags);

         if Result.Staging_FD < 0 then
            Require (C.int (GNAT.OS_Lib.Errno), "cannot open output staging");
         end if;

         Result.Identity := Stat (Descriptor_Path (Result.Staging_FD) & "/.");

         if Kind (Result.Identity) /= Directory
           or else Result.Identity.UID /= Interfaces.Unsigned_32 (C_Geteuid)
         then
            Diagnostics.Fail_Command ("output staging is not owned");
         elsif (Result.Identity.Mode and 8#022#) /= 0 then
            Diagnostics.Fail_Command
              ("output staging is writable by other users");
         end if;

         Result.Private_Directory := True;

         --  A stolen victim-owned directory can pass ownership checks. Never
         --  follow an existing archive there, including an archive symlink.
         declare
            Reserved : C.int := C_Openat
              (Result.Staging_FD, C.To_C ("archive"), Archive_Flags, 8#666#);
         begin
            if Reserved < 0 then
               Require
                 (C.int (GNAT.OS_Lib.Errno), "cannot reserve output archive");
            end if;

            Result.Archive_Created := True;
            Close_Descriptor (Reserved);
         end;
      end return;
   end Begin_Output;

   -------------------------------------------------------------------------

   function Staging_Name (Item : Transaction) return String
   is
   begin
      return Descriptor_Path (Item.Staging_FD) & "/archive";
   end Staging_Name;

   -------------------------------------------------------------------------

   procedure Publish
     (Item    : Transaction;
      Target  : String;
      Replace : Boolean)
   is
      Code : C.int;
      Base : constant C.char_array := C.To_C
        (Ada.Directories.Simple_Name (Target));
   begin
      Check_Interrupted;

      if Replace then
         Code := Errno_On_Failure
           (C_Renameat
              (Item.Staging_FD, C.To_C ("archive"), Item.Parent_FD, Base));
      else
         Code := Errno_On_Failure
           (C_Renameat2
              (Item.Staging_FD, C.To_C ("archive"),
               Item.Parent_FD, Base, Rename_No_Replace));

         if Code = Invalid_Argument or else Code = Not_Implemented
           or else Code = Operation_Unsupported
         then
            declare
               Source      : constant String := Staging_Name (Item);
               Info        : constant Metadata := Stat (Source);
               Destination : constant String := Descriptor_Path
                 (Item.Parent_FD) & "/" & Ada.Directories.Simple_Name (Target);
            begin
               Code := Errno_On_Failure
                 (C_Linkat
                    (Item.Staging_FD, C.To_C ("archive"),
                     Item.Parent_FD, Base, 0));

               --  NFS can commit a link but lose its success reply. The
               --  private staging inode identifies our complete output.
               if Code /= 0 and then Published_Link (Info, Destination) then
                  Code := 0;
               end if;
            end;
         end if;
      end if;

      Require (Code, "cannot publish '" & Target & "'");
   end Publish;

   -------------------------------------------------------------------------

   overriding procedure Finalize (Item : in out Transaction)
   is
      Entry_Info : aliased Metadata;
      use type Interfaces.Unsigned_64;
   begin
      begin
         if Item.Archive_Created then
            Ignore_Error
              (C_Unlinkat (Item.Staging_FD, C.To_C ("archive"), 0));
         end if;

         --  Never recurse into a pathname that another parent writer can
         --  replace. A late empty-directory replacement is already removable
         --  by that parent writer; nonempty replacement contents stay intact.
         --  Cleanup must not call a diagnostic-raising helper: an inspection
         --  error must not replace the command failure already in flight.
         if Item.Active and then Item.Private_Directory
           and then C_Stat (Item.Buffer, Entry_Info'Access) = 0
           and then Entry_Info.Kind =
             Interfaces.Unsigned_32 (Entry_Kind'Pos (Directory))
           and then Entry_Info.Device = Item.Identity.Device
           and then Entry_Info.Inode = Item.Identity.Inode
         then
            Ignore_Error (C_Unlinkat
              (Item.Parent_FD, C.To_C (Ada.Directories.Simple_Name
                 (C.To_Ada (Item.Buffer))), Remove_Directory));
         end if;
      exception
         when others =>
            null;
      end;

      --  Writer objects unwind first, including Stream_IO.Delete through the
      --  retained proc path. Always release both descriptors after cleanup.
      Close_Descriptor (Item.Staging_FD);
      Close_Descriptor (Item.Parent_FD);
   end Finalize;

end Archive_CLI.Filesystem;
