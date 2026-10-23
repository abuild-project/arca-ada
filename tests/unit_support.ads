--  SPDX-License-Identifier: LGPL-2.1-or-later

with Ada.Finalization;
with Ada.Strings.Unbounded;
with Interfaces.C;

package Unit_Support is

   type Fixture is new Ada.Finalization.Limited_Controlled with private;

   function Prepare (Name : String) return Fixture;
   --  Create private patterned, empty, tiny and sparse sources for one test.

   function Prepare_Native (Name : String) return Fixture;
   --  Own an empty private Linux /tmp tree for real permission-failure tests.

   function Path (Item : Fixture) return String;
   --  Return the owned directory beneath the runner root or on native /tmp.

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
      Directory   : Ada.Strings.Unbounded.Unbounded_String;
      Created     : Boolean := False;
      Native      : Boolean := False;
      Native_Path : Interfaces.C.char_array (0 .. 127) :=
        (others => Interfaces.C.nul);
   end record;

   overriding procedure Finalize (Item : in out Fixture);
   --  Restore native-directory write permission, then remove the owned tree.

end Unit_Support;
