-- SPDX-License-Identifier: LGPL-2.1-or-later

with Archive_CLI.Options;

package Archive_CLI.Writer is

   procedure Create (Config : Options.Settings);
   --  Inventory one stable tree, emit deterministic entries and publish once.

end Archive_CLI.Writer;
