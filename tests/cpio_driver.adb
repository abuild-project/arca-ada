--  SPDX-License-Identifier: LGPL-2.1-or-later

with Ada.Command_Line;
with CPIO_Scenarios;

--  Expose shared scenarios to the independent format checks.
procedure CPIO_Driver
is
begin
   CPIO_Scenarios.Run
     (Ada.Command_Line.Argument (1), Ada.Command_Line.Argument (2));
end CPIO_Driver;
