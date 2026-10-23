--  SPDX-License-Identifier: LGPL-2.1-or-later

with Ada.Strings.Unbounded;
with Interfaces;

package Archive_CLI.Options is

   type Command_Kind is (Create_Command, Help_Command, Version_Command);
   type Format_Kind is (CPIO_Format, TAR_Format);

   type Owner_Override is record
      Present : Boolean := False;
      Value   : Interfaces.Unsigned_32 := 0;
   end record;

   type Time_Override is record
      Present : Boolean := False;
      Value   : Long_Long_Integer := 0;
   end record;

   type Settings is record
      Command   : Command_Kind := Create_Command;
      Format    : Format_Kind := CPIO_Format;
      Directory : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String (".");
      Output    : Ada.Strings.Unbounded.Unbounded_String;
      UID, GID  : Owner_Override;
      MTime     : Time_Override;
      Force     : Boolean := False;
   end record;

   function Parse return Settings;
   --  Validate decimal options; explicit mtime overrides SOURCE_DATE_EPOCH.

   procedure Print_Help;
   --  Describe the supported create command and its output/metadata policy.

end Archive_CLI.Options;
