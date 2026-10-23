--  SPDX-License-Identifier: GPL-2.0-or-later

with Archive_CLI.Options;

package Archive_CLI.Writer is

   procedure Create (Config : Options.Settings);
   --  Inventory one stable tree, emit deterministic entries and publish once.

end Archive_CLI.Writer;
