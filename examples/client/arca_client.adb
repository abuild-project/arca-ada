-- SPDX-License-Identifier: LGPL-2.1-or-later

with Ada.Command_Line;
with Ada.Text_IO;
with Arca.CPIO;
pragma Elaborate_All (Arca.CPIO);

--  Verify that an independent client can import and link the Arca project.
procedure Arca_Client is
   Archive : Arca.CPIO.CPIO_Archive_Type;
begin
   if Ada.Command_Line.Argument_Count = 1 then
      Arca.CPIO.CPIO_Create (Archive, Ada.Command_Line.Argument (1));
      Arca.CPIO.CPIO_Close (Archive);
   end if;
   Ada.Text_IO.Put_Line ("Arca project import succeeded");
end Arca_Client;
