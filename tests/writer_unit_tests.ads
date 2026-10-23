--  SPDX-License-Identifier: GPL-2.0-or-later

with Ahven.Framework;

package Writer_Unit_Tests is

   type CPIO_Case is new Ahven.Framework.Test_Case with null record;

   overriding procedure Initialize (Item : in out CPIO_Case);
   --  Register direct CPIO error, ownership, parallel and reuse contracts.

   type TAR_Case is new Ahven.Framework.Test_Case with null record;

   overriding procedure Initialize (Item : in out TAR_Case);
   --  Register direct TAR error, ownership, parallel and reuse contracts.

end Writer_Unit_Tests;
