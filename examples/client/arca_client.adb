--  SPDX-License-Identifier: GPL-2.0-or-later

with Ada.Command_Line;
with Ada.Calendar.Formatting;
with Ada.Text_IO;
with Arca.CPIO;
pragma Elaborate_All (Arca.CPIO);
with Arca.TAR;
pragma Elaborate_All (Arca.TAR);
with Arca.Version;

--  Verify project import, writer ownership and public version metadata.
procedure Arca_Client
is
   type Writer_Record is limited record
      CPIO : Arca.CPIO.CPIO_Archive_Type;
      TAR  : Arca.TAR.TAR_Archive_Type;
   end record;

   Writers : Writer_Record;
begin
   if Ada.Command_Line.Argument_Count >= 1 then
      Arca.CPIO.CPIO_Create (Writers.CPIO, Ada.Command_Line.Argument (1));
      Arca.CPIO.CPIO_Close (Writers.CPIO);
   end if;

   if Ada.Command_Line.Argument_Count >= 2 then
      Arca.TAR.TAR_Create (Writers.TAR, Ada.Command_Line.Argument (2));
      Arca.TAR.TAR_Close (Writers.TAR);
   end if;

   if Ada.Command_Line.Argument_Count >= 3 then
      Arca.TAR.TAR_Create (Writers.TAR, Ada.Command_Line.Argument (3));
      Arca.TAR.TAR_Make_Directory
        (Writers.TAR, (1 .. 101 => 'n'), 8#755#, 0, 0,
         Ada.Calendar.Formatting.Time_Of
           (1970, 1, 1, Seconds => 0.0, Time_Zone => 0));
      Arca.TAR.TAR_Close (Writers.TAR);
   end if;

   Ada.Text_IO.Put_Line
     ("Arca project import succeeded (" & Arca.Version.Value & ")");
end Arca_Client;
