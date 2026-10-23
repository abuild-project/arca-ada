--  SPDX-License-Identifier: LGPL-2.1-or-later

with Ahven.Framework;
with Ahven.Text_Runner;
with Arca.Copy_Unit_Tests;
with Writer_Unit_Tests;

--  Run named library cases; Ahven owns their registration and result status.
procedure Unit_Runner
is
   Suite : Ahven.Framework.Test_Suite :=
     Ahven.Framework.Create_Suite ("Arca unit tests");
begin
   Ahven.Framework.Add_Test (Suite, new Writer_Unit_Tests.CPIO_Case);
   Ahven.Framework.Add_Test (Suite, new Writer_Unit_Tests.TAR_Case);
   Ahven.Framework.Add_Test (Suite, new Arca.Copy_Unit_Tests.Test_Case);
   Ahven.Text_Runner.Run (Suite);
end Unit_Runner;
