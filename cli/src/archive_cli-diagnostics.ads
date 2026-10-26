--  SPDX-License-Identifier: GPL-2.0-or-later

with Ada.Exceptions;

package Archive_CLI.Diagnostics is

   procedure Reset;
   --  Discard the preceding invocation's full diagnostic.

   procedure Fail_Usage (Text : String)
     with No_Return;
   --  Retain Text outside the bounded exception message and raise Usage_Error.

   procedure Fail_Command (Text : String)
     with No_Return;
   --  Retain complete Text separately and raise Command_Error.

   function Message
     (Error : Ada.Exceptions.Exception_Occurrence) return String;
   --  Return retained text for its CLI exception, otherwise its runtime text
   --  or exception name when the runtime supplied no message.

   function Display (Text : String) return String;
   --  Escape control bytes, DEL and backslash without changing other bytes.

end Archive_CLI.Diagnostics;
