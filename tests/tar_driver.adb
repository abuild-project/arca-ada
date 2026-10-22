-- SPDX-License-Identifier: LGPL-2.1-or-later

with Ada.Command_Line;
with TAR_Scenarios;

--  Expose shared scenarios to the independent format checks.
procedure TAR_Driver is
begin
   TAR_Scenarios.Run
     (Ada.Command_Line.Argument (1), Ada.Command_Line.Argument (2));
end TAR_Driver;
