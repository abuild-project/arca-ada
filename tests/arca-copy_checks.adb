--  SPDX-License-Identifier: GPL-2.0-or-later

with Ada.Command_Line;
with Arca.Copy_Scenarios;

--  Expose shared scenarios to the independent format checks.
procedure Arca.Copy_Checks
is
begin
   Arca.Copy_Scenarios.Run
     (Ada.Command_Line.Argument (1));
end Arca.Copy_Checks;
