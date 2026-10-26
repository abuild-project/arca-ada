--  SPDX-License-Identifier: GPL-2.0-or-later

with Ada.Command_Line;
with Ada.Text_IO;
with Archive_CLI.Diagnostics;
with Archive_CLI.Filesystem;
with Archive_CLI.Options;
with Archive_CLI.Writer;

package body Archive_CLI is

   procedure Run
   is
   begin
      Diagnostics.Reset;

      declare
         Config : constant Options.Settings := Options.Parse;
      begin
         case Config.Command is
            when Options.Help_Command =>
               Options.Print_Help;

            when Options.Version_Command =>
               Ada.Text_IO.Put_Line ("arca development");

            when Options.Create_Command =>
               Filesystem.Install_Signals;
               Writer.Create (Config);
         end case;
      end;
   exception
      when Error : Usage_Error =>
         Ada.Text_IO.Put_Line
           (Ada.Text_IO.Standard_Error,
            "arca: " & Diagnostics.Display (Diagnostics.Message (Error)));
         Ada.Command_Line.Set_Exit_Status (2);

      when Interrupted =>
         Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error, "arca: interrupted");
         Ada.Command_Line.Set_Exit_Status
           (Ada.Command_Line.Exit_Status (128 + Filesystem.Signal_Number));

      when Error : others =>
         if Filesystem.Signal_Number /= 0 then
            Ada.Text_IO.Put_Line
              (Ada.Text_IO.Standard_Error, "arca: interrupted");
            Ada.Command_Line.Set_Exit_Status
              (Ada.Command_Line.Exit_Status
                 (128 + Filesystem.Signal_Number));
         else
            Ada.Text_IO.Put_Line
              (Ada.Text_IO.Standard_Error,
               "arca: " & Diagnostics.Display (Diagnostics.Message (Error)));
            Ada.Command_Line.Set_Exit_Status (1);
         end if;
   end Run;

end Archive_CLI;
