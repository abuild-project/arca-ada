-- SPDX-License-Identifier: LGPL-2.1-or-later

with Ada.Directories;
with Ada.Interrupts;
with Ada.Interrupts.Names;
with GNAT.OS_Lib;
with Interfaces.C.Strings;

package body Archive_CLI.Filesystem is

   package C renames Interfaces.C;

   use type C.int;
   use type C.long;
   use type C.Strings.chars_ptr;
   use type Interfaces.Unsigned_32;

   --  Linux fcntl/stdio constants; the CLI targets the 64-bit Linux ABI.
   Current_Directory_FD : constant C.int := -100; --  AT_FDCWD
   Rename_No_Replace    : constant C.unsigned := 1; --  RENAME_NOREPLACE

   --  Linux errno values for unsupported no-replace rename operations.
   Invalid_Argument      : constant C.int := 22; --  EINVAL
   Not_Implemented       : constant C.int := 38; --  ENOSYS
   Operation_Unsupported : constant C.int := 95; --  EOPNOTSUPP

   protected Cancellation is

      procedure Handle_Interrupt;
      --  Record SIGINT without filesystem work or exception propagation.
      pragma Interrupt_Handler (Handle_Interrupt);

      procedure Handle_Termination;
      --  Record SIGTERM for cleanup at the next command boundary.
      pragma Interrupt_Handler (Handle_Termination);

      function Number return Natural;
      --  Read the process-owned signal state through protected access.

   private

      pragma Interrupt_State (Ada.Interrupts.Names.SIGINT, User);
      pragma Interrupt_State (Ada.Interrupts.Names.SIGTERM, User);

      Last_Signal : Natural := 0;
   end Cancellation;

   function C_Stat (Name : C.char_array; Item : access Metadata) return C.int;
   --  Return an errno value and an explicitly sized metadata record.
   pragma Import (C, C_Stat, "arca_lstat");

   function C_Readlink
     (Name     :     C.char_array;
      Buffer   : out C.char_array;
      Capacity :     C.size_t)
      return C.long;
   --  Return a byte count without a NUL, or -1; Linux64 ssize_t is long.
   pragma Import (C, C_Readlink, "readlink");

   function C_Mkdtemp
     (Buffer : in out C.char_array) return C.Strings.chars_ptr;
   --  Atomically create the private directory described by the template.
   --  Success points into Buffer and must not be freed; null reports failure.
   pragma Import (C, C_Mkdtemp, "mkdtemp");

   function C_Rename (Source, Target : C.char_array) return C.int;
   --  Atomically replace Target on the same filesystem; return zero or -1.
   pragma Import (C, C_Rename, "rename");

   function C_Link (Source, Target : C.char_array) return C.int;
   --  Publish another name for a closed file without replacing any target.
   pragma Import (C, C_Link, "link");

   function C_Renameat2
     (Source_FD : C.int;
      Source    : C.char_array;
      Target_FD : C.int;
      Target    : C.char_array;
      Flags     : C.unsigned)
      return C.int;
   --  Apply Linux rename flags and return zero or -1 with errno on failure.
   pragma Import (C, C_Renameat2, "renameat2");

   function C_Strerror (Code : C.int) return C.Strings.chars_ptr;
   --  Read libc's static diagnostic for an errno value; do not free it.
   pragma Import (C, C_Strerror, "strerror");

   function Errno_On_Failure (Result : C.int) return C.int;
   --  Capture a zero/-1 call's errno before allocating diagnostic strings.

   procedure Require (Code : C.int; Context : String);
   --  Map a captured errno value to a contextual command diagnostic.

   function Published_Link (Source : Metadata; Target : String) return Boolean;
   --  Resolve an ambiguous NFS link reply only for the same regular inode.

   protected body Cancellation is

      procedure Handle_Interrupt is
      begin
         Last_Signal := Natural (Ada.Interrupts.Names.SIGINT);
      end Handle_Interrupt;

      ----------------------------------------------------------------------

      procedure Handle_Termination is
      begin
         Last_Signal := Natural (Ada.Interrupts.Names.SIGTERM);
      end Handle_Termination;

      ----------------------------------------------------------------------

      function Number return Natural is
      begin
         return Last_Signal;
      end Number;

   end Cancellation;

   -------------------------------------------------------------------------

   function Errno_On_Failure (Result : C.int) return C.int is
   begin
      return (if Result = 0 then 0 else C.int (GNAT.OS_Lib.Errno));
   end Errno_On_Failure;

   -------------------------------------------------------------------------

   procedure Require (Code : C.int; Context : String) is
   begin
      if Code /= 0 then
         raise Command_Error with
           Context & ": " & C.Strings.Value (C_Strerror (Code));
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

   function Kind (Item : Metadata) return Entry_Kind is
   begin
      if Item.Kind > 6 then
         raise Command_Error with "invalid filesystem node classification";
      end if;

      return Entry_Kind'Val (Item.Kind);
   end Kind;

   -------------------------------------------------------------------------

   function Exists (Name : String; Item : out Metadata) return Boolean is
      Value : aliased Metadata;
      Code  : constant C.int := C_Stat (C.To_C (Name), Value'Access);
   begin
      if Code = 2 then --  ENOENT on the supported Linux environment.
         Item := (others => <>);
         return False;
      end if;

      Require (Code, "cannot inspect '" & Name & "'");
      Item := Value;

      return True;
   end Exists;

   -------------------------------------------------------------------------

   function Stat (Name : String) return Metadata is
      Result : Metadata;
   begin
      if not Exists (Name, Result) then
         raise Command_Error with "source does not exist: '" & Name & "'";
      end if;

      return Result;
   end Stat;

   -------------------------------------------------------------------------

   function Canonical (Name : String) return String is
      Result : constant String := GNAT.OS_Lib.Normalize_Pathname (Name);
   begin
      if Result = "" then
         raise Command_Error with "cannot resolve path: '" & Name & "'";
      end if;

      return Result;
   end Canonical;

   -------------------------------------------------------------------------

   function Link_Target (Name : String) return String is
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
         raise Command_Error with "symlink target is too long: '" & Name & "'";
      elsif Length = 0 then
         return "";
      end if;

      return C.To_Ada
        (Buffer (0 .. C.size_t (Length) - 1), Trim_Nul => False);
   end Link_Target;

   -------------------------------------------------------------------------

   procedure Install_Signals is
   begin
      Ada.Interrupts.Attach_Handler
        (Cancellation.Handle_Interrupt'Access, Ada.Interrupts.Names.SIGINT);
      Ada.Interrupts.Attach_Handler
        (Cancellation.Handle_Termination'Access, Ada.Interrupts.Names.SIGTERM);
   end Install_Signals;

   -------------------------------------------------------------------------

   procedure Check_Interrupted is
   begin
      if Cancellation.Number /= 0 then
         raise Interrupted;
      end if;
   end Check_Interrupted;

   -------------------------------------------------------------------------

   function Signal_Number return Natural is
   begin
      return Cancellation.Number;
   end Signal_Number;

   -------------------------------------------------------------------------

   function Begin_Output (Parent : String) return Transaction is
      Template : constant C.char_array := C.To_C (Parent & "/.arca-XXXXXX");
   begin
      return Result : Transaction do
         if Template'Length > Result.Buffer'Length then
            raise Command_Error with "output path is too long";
         end if;

         Result.Buffer (Template'Range) := Template;

         if C_Mkdtemp (Result.Buffer) = C.Strings.Null_Ptr then
            Require (C.int (GNAT.OS_Lib.Errno), "cannot create output staging");
         end if;

         Result.Active := True;
      end return;
   end Begin_Output;

   -------------------------------------------------------------------------

   function Staging_Name (Item : Transaction) return String is
   begin
      return C.To_Ada (Item.Buffer) & "/archive";
   end Staging_Name;

   -------------------------------------------------------------------------

   procedure Publish
     (Item    : Transaction;
      Target  : String;
      Replace : Boolean)
   is
      Code : C.int;
   begin
      Check_Interrupted;

      if Replace then
         Code := Errno_On_Failure
           (C_Rename (C.To_C (Staging_Name (Item)), C.To_C (Target)));
      else
         Code := Errno_On_Failure
           (C_Renameat2
              (Current_Directory_FD, C.To_C (Staging_Name (Item)),
               Current_Directory_FD, C.To_C (Target), Rename_No_Replace));

         if Code = Invalid_Argument or else Code = Not_Implemented
           or else Code = Operation_Unsupported
         then
            declare
               Source : constant String := Staging_Name (Item);
               Info   : constant Metadata := Stat (Source);
            begin
               Code := Errno_On_Failure
                 (C_Link (C.To_C (Source), C.To_C (Target)));

               --  NFS can commit a link but lose its success reply. The
               --  private staging inode identifies our complete output.
               if Code /= 0 and then Published_Link (Info, Target) then
                  Code := 0;
               end if;
            end;
         end if;
      end if;

      Require (Code, "cannot publish '" & Target & "'");
   end Publish;

   -------------------------------------------------------------------------

   overriding procedure Finalize (Item : in out Transaction) is
   begin
      if Item.Active then
         Ada.Directories.Delete_Tree (C.To_Ada (Item.Buffer));
      end if;
   exception
      when others =>
         --  Best effort: preserve the caller's exception and a successful
         --  publication. A cleanup fault may leave the private staging tree.
         null;
   end Finalize;

end Archive_CLI.Filesystem;
