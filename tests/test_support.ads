--  SPDX-License-Identifier: GPL-2.0-or-later

with Ada.Exceptions;

package Test_Support is

   procedure Check (Condition : Boolean; Message : String);
   --  Fail the test with Message unless Condition holds.

   procedure Expect_Failure
     (Action   : not null access procedure;
      Identity : Ada.Exceptions.Exception_Id;
      Message  : String);
   --  Require Action to raise Identity with the supplied message fragment.

   function Open_Descriptor_Count return Natural;
   --  Count descriptors in the Linux reference environment without retaining
   --  the search handle. Compare counts within the same process only.

end Test_Support;
