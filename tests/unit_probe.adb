--  SPDX-License-Identifier: GPL-2.0-or-later

with Ahven.Framework;
with Ahven.Text_Runner;
with Harness_Unit_Tests;

--  Prove that a failing Ahven assertion reaches reports and process status.
procedure Unit_Probe
is
   Suite : Ahven.Framework.Test_Suite :=
     Ahven.Framework.Create_Suite ("Harness probe");
begin
   Ahven.Framework.Add_Test (Suite, new Harness_Unit_Tests.Test_Case);
   Ahven.Text_Runner.Run (Suite);
end Unit_Probe;
