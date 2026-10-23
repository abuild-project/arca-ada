--  SPDX-License-Identifier: GPL-2.0-or-later

with Ahven;
with Unit_Support;

package body Harness_Unit_Tests is

   use Ahven.Framework;

   procedure Fail_Assertion;
   --  Supply a known diagnostic whose absence makes the harness check fail.

   procedure Fail_Assertion
   is
      Files : constant Unit_Support.Fixture :=
        Unit_Support.Prepare ("assertion-probe");
   begin
      Ahven.Assert
        (False, "intentional assertion probe: " & Unit_Support.Path (Files));
   end Fail_Assertion;

   -------------------------------------------------------------------------

   overriding procedure Initialize (Item : in out Test_Case)
   is
   begin
      Set_Name (Item, "Harness_probe");
      Add_Test_Routine
        (Item, Fail_Assertion'Access, "deliberate assertion failure");
   end Initialize;

end Harness_Unit_Tests;
