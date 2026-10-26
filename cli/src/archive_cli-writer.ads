--  SPDX-License-Identifier: GPL-2.0-or-later

with Archive_CLI.Options;

package Archive_CLI.Writer is

   procedure Create (Config : Options.Settings);
   --  Use parsed settings to inventory a stable tree, emit and publish once.

end Archive_CLI.Writer;
