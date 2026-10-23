--  SPDX-License-Identifier: LGPL-2.1-or-later

with Ahven.Framework;

package Harness_Unit_Tests is

   type Test_Case is new Ahven.Framework.Test_Case with null record;

   overriding procedure Initialize (Item : in out Test_Case);
   --  Register the deliberate failure used only by the harness probe.

end Harness_Unit_Tests;
