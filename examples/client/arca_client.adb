-- SPDX-License-Identifier: BSD-3-Clause

with Ada.Text_IO;
with Arca;
pragma Elaborate_All (Arca);

--  Verify that an independent client can import and link the Arca project.
procedure Arca_Client is
begin
   Ada.Text_IO.Put_Line ("Arca project import succeeded");
end Arca_Client;
