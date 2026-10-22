-- SPDX-License-Identifier: LGPL-2.1-or-later

with Ada.Finalization;
with Interfaces;
with Interfaces.C;

package Archive_CLI.Filesystem is

   type Entry_Kind is
     (Regular, Directory, Symlink, FIFO, Block_Device, Char_Device,
      Unsupported);

   type Metadata is record
      Device, Inode, Size : Interfaces.Unsigned_64 := 0;
      MTime, MTime_NS     : Interfaces.Integer_64 := 0;
      Mode, UID, GID      : Interfaces.Unsigned_32 := 0;
      Major, Minor, Kind : Interfaces.Unsigned_32 := 0;
   end record
     with Convention => C;

   function Kind (Item : Metadata) return Entry_Kind;
   --  Decode the bridge's stable node-kind number, independent of mode bits.

   function Exists (Name : String; Item : out Metadata) return Boolean;
   --  lstat Name without following its final symlink; only ENOENT means absent.

   function Stat (Name : String) return Metadata;
   --  Require a present node and return its numeric metadata without following.

   function Canonical (Name : String) return String;
   --  Normalize an existing root/parent path through GNAT, resolving links.

   function Link_Target (Name : String) return String;
   --  Read the complete Linux symlink target, rejecting truncation.

   procedure Install_Signals;
   --  Record SIGINT/SIGTERM for cancellation at safe command boundaries.

   procedure Check_Interrupted;
   --  Raise Interrupted once a termination signal has been recorded.

   function Signal_Number return Natural;
   --  Return the recorded signal for the conventional exit status.

   type Transaction is new Ada.Finalization.Limited_Controlled with private;

   function Begin_Output (Parent : String) return Transaction;
   --  Own a mode-0700 staging directory on the destination filesystem.

   function Staging_Name (Item : Transaction) return String;
   --  Return the private filename passed to the archive writer.

   procedure Publish
     (Item    : Transaction;
      Target  : String;
      Replace : Boolean);
   --  Atomically publish a closed output, enforcing no-clobber by default.
   --  Unsupported no-replace rename uses a same-filesystem hard link. Its
   --  private staging name remains owned until nonthrowing finalization.

private

   use type Interfaces.C.size_t;

   --  Linux path/link bound; fixed storage avoids allocation during setup.
   Path_Capacity : constant := 4096;

   type Transaction is new Ada.Finalization.Limited_Controlled with record
      Buffer : Interfaces.C.char_array (0 .. Path_Capacity - 1) :=
        (others => Interfaces.C.nul);
      Active : Boolean := False;
   end record;

   overriding procedure Finalize (Item : in out Transaction);
   --  Attempt staging removal after writer finalization or publication;
   --  cleanup faults may leave staging but never replace a caller exception.

end Archive_CLI.Filesystem;
