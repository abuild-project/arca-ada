-- SPDX-License-Identifier: LGPL-2.1-or-later

with Ada.Directories;
with GNAT.OS_Lib;
with Interfaces.C.Strings;

package body Archive_CLI.Filesystem is
   package C renames Interfaces.C;
   use type C.int;
   use type Interfaces.Unsigned_32;

   function C_Stat (Name : C.char_array; Item : access Metadata) return C.int;
   --  Return an errno value and an explicitly sized metadata record.
   pragma Import (C, C_Stat, "arca_lstat");

   function C_Readlink
     (Name : C.char_array; Buffer : out C.char_array; Capacity : C.size_t)
      return C.int;
   --  Return a complete NUL-terminated target or an errno value.
   pragma Import (C, C_Readlink, "arca_readlink");

   function C_Mkdtemp (Buffer : in out C.char_array) return C.int;
   --  Atomically create the private directory described by the template.
   pragma Import (C, C_Mkdtemp, "arca_mkdtemp");

   function C_Publish
     (Source, Target : C.char_array; Replace : C.int) return C.int;
   --  Rename within one filesystem without unlinking the destination first.
   pragma Import (C, C_Publish, "arca_publish");

   function C_Strerror (Code : C.int) return C.Strings.chars_ptr;
   --  Read libc's static diagnostic for an errno value; do not free it.
   pragma Import (C, C_Strerror, "strerror");

   function C_Install_Signals return C.int;
   --  Install the command-owned signal handlers.
   pragma Import (C, C_Install_Signals, "arca_install_signals");

   function C_Cancelled return C.int;
   --  Read the signal-safe flag without mutating it.
   pragma Import (C, C_Cancelled, "arca_cancelled");

   procedure Require (Code : C.int; Context : String);
   --  Map a bridge error to a contextual command diagnostic.

   procedure Require (Code : C.int; Context : String) is
   begin
      if Code /= 0 then
         raise Command_Error with
           Context & ": " & C.Strings.Value (C_Strerror (Code));
      end if;
   end Require;

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
      Code : constant C.int := C_Stat (C.To_C (Name), Value'Access);
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
   begin
      Require
        (C_Readlink (C.To_C (Name), Buffer, Buffer'Length),
         "cannot read symlink '" & Name & "'");
      return C.To_Ada (Buffer);
   end Link_Target;

   -------------------------------------------------------------------------

   procedure Install_Signals is
   begin
      Require (C_Install_Signals, "cannot install signal handlers");
   end Install_Signals;

   -------------------------------------------------------------------------

   procedure Check_Interrupted is
   begin
      if C_Cancelled /= 0 then
         raise Interrupted;
      end if;
   end Check_Interrupted;

   -------------------------------------------------------------------------

   function Signal_Number return Natural is
   begin
      return Natural (C_Cancelled);
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
         Require (C_Mkdtemp (Result.Buffer), "cannot create output staging");
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
     (Item : Transaction; Target : String; Replace : Boolean)
   is
   begin
      Check_Interrupted;
      Require
        (C_Publish (C.To_C (Staging_Name (Item)), C.To_C (Target),
                    Boolean'Pos (Replace)),
         "cannot publish '" & Target & "'");
   end Publish;

   -------------------------------------------------------------------------

   overriding procedure Finalize (Item : in out Transaction) is
   begin
      if Item.Active then
         Ada.Directories.Delete_Tree (C.To_Ada (Item.Buffer));
      end if;
   end Finalize;
end Archive_CLI.Filesystem;
