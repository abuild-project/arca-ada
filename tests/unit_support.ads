-- SPDX-License-Identifier: LGPL-2.1-or-later

with Ada.Finalization;
with Ada.Strings.Unbounded;

package Unit_Support is

   type Fixture is new Ada.Finalization.Limited_Controlled with private;

   function Prepare (Name : String) return Fixture;
   --  Create private patterned, empty, tiny and sparse sources for one test.

   function Path (Item : Fixture) return String;
   --  Return the fixture directory beneath this runner's private root.

   procedure Assert_Equal_Files (Left, Right : String);
   --  Compare complete files with bounded buffers, including their lengths.

   procedure Exercise
     (Action    : not null access procedure (Mode, Work : String);
      Mode      : String;
      Name      : String;
      Extension : String);
   --  Run shared direct assertions and check their output postconditions.

private

   type Fixture is new Ada.Finalization.Limited_Controlled with record
      Directory : Ada.Strings.Unbounded.Unbounded_String;
      Created   : Boolean := False;
   end record;

   overriding procedure Finalize (Item : in out Fixture);
   --  Remove only the directory successfully created by this fixture.

end Unit_Support;
