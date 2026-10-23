--  SPDX-License-Identifier: LGPL-2.1-or-later

with Ahven.Framework;

package Arca.Copy_Unit_Tests is

   type Test_Case is new Ahven.Framework.Test_Case with null record;

   overriding procedure Initialize (Item : in out Test_Case);
   --  Register private-copy failure, payload and exact-buffer checks.

end Arca.Copy_Unit_Tests;
