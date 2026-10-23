--  SPDX-License-Identifier: GPL-2.0-or-later

package Archive_CLI is

   Usage_Error, Command_Error, Interrupted : exception;

   procedure Run;
   --  Parse one invocation and create an archive or print command help.

end Archive_CLI;
