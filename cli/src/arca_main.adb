--  SPDX-License-Identifier: GPL-2.0-or-later

with Archive_CLI;

--  Provide the executable entry point independently of the library namespace.
procedure Arca_Main
is
begin
   Archive_CLI.Run;
end Arca_Main;
