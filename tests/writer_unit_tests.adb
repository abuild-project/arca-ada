-- SPDX-License-Identifier: LGPL-2.1-or-later

with Ada.Calendar.Formatting;
with Ada.IO_Exceptions;
with Ahven;
with Arca.CPIO;
with Arca.TAR;
with CPIO_Scenarios;
with TAR_Scenarios;
with Unit_Support;

package body Writer_Unit_Tests is

   use Ahven.Framework;
   use Unit_Support;
   use type Arca.CPIO.Inode_Type;

   Fixed_Time : constant Ada.Calendar.Time :=
     Ada.Calendar.Formatting.Time_Of
       (2000, 1, 1, Seconds => 0.0, Time_Zone => 0);

   procedure CPIO_Errors;
   --  Pin exception identities/messages and recovery after rejected metadata.

   procedure CPIO_State;
   --  Preserve the open output and its inode state after repeated Create.

   procedure CPIO_Lifetime;
   --  Discard incomplete outputs on scope exit, exceptions and task exit.

   procedure CPIO_Parallel;
   --  Compare complete outputs from eight independent bounded-stack workers.

   procedure CPIO_Reuse;
   --  Reset offsets and automatic inode allocation when reusing a closed type.

   procedure CPIO_Create_Failure;
   --  Recover the same instance after Create fails before opening a file.

   procedure TAR_Errors;
   --  Pin all unopened operations, bounds and recovery after short headers.

   procedure TAR_State;
   --  Preserve the open output when a second Create is rejected.

   procedure TAR_Lifetime;
   --  Discard incomplete GNU metadata on exceptions and owner-task exit.

   procedure TAR_Parallel;
   --  Compare complete outputs from eight independent bounded-stack workers.

   procedure TAR_Reuse;
   --  Reuse a closed instance without carrying archive bytes into the next one.

   procedure TAR_Create_Failure;
   --  Recover the same instance after a nonexistent-parent Create failure.

   -------------------------------------------------------------------------

   procedure CPIO_Errors is
   begin
      Exercise (CPIO_Scenarios.Run'Access, "errors", "cpio-errors", ".cpio");
   end CPIO_Errors;

   -------------------------------------------------------------------------

   procedure CPIO_State is
   begin
      Exercise (CPIO_Scenarios.Run'Access, "state", "cpio-state", ".cpio");
   end CPIO_State;

   -------------------------------------------------------------------------

   procedure CPIO_Lifetime is
   begin
      Exercise
        (CPIO_Scenarios.Run'Access, "lifetime", "cpio-lifetime", ".cpio");
   end CPIO_Lifetime;

   -------------------------------------------------------------------------

   procedure CPIO_Parallel is
   begin
      Exercise
        (CPIO_Scenarios.Run'Access, "parallel", "cpio-parallel", ".cpio");
   end CPIO_Parallel;

   -------------------------------------------------------------------------

   procedure CPIO_Reuse is
      Files : constant Fixture := Prepare ("cpio-reuse");
      Archive : Arca.CPIO.CPIO_Archive_Type;
      First : Arca.CPIO.Inode_Type;
   begin
      Arca.CPIO.CPIO_Create (Archive, Path (Files) & "/first.cpio");
      First := Arca.CPIO.CPIO_Get_Next_Inode (Archive);
      Arca.CPIO.CPIO_Make_Directory (Archive, "dir", 8#755#, 1, 2, Fixed_Time);
      Arca.CPIO.CPIO_Close (Archive);
      Arca.CPIO.CPIO_Create (Archive, Path (Files) & "/second.cpio");
      Ahven.Assert
        (Arca.CPIO.CPIO_Get_Next_Inode (Archive) = First,
         "Create did not reset automatic CPIO inode allocation");
      Arca.CPIO.CPIO_Make_Directory (Archive, "dir", 8#755#, 1, 2, Fixed_Time);
      Arca.CPIO.CPIO_Close (Archive);
      Assert_Equal_Files
        (Path (Files) & "/first.cpio", Path (Files) & "/second.cpio");
   end CPIO_Reuse;

   -------------------------------------------------------------------------

   procedure CPIO_Create_Failure is
      Files : constant Fixture := Prepare ("cpio-create-failure");
      Archive : Arca.CPIO.CPIO_Archive_Type;
   begin
      begin
         Arca.CPIO.CPIO_Create (Archive, Path (Files) & "/absent/out.cpio");
         Ahven.Fail ("Create accepted a nonexistent parent");
      exception
         when Ada.IO_Exceptions.Name_Error => null;
      end;
      Arca.CPIO.CPIO_Create (Archive, Path (Files) & "/retry.cpio");
      Arca.CPIO.CPIO_Close (Archive);
      Arca.CPIO.CPIO_Create (Archive, Path (Files) & "/reference.cpio");
      Arca.CPIO.CPIO_Close (Archive);
      Assert_Equal_Files
        (Path (Files) & "/retry.cpio", Path (Files) & "/reference.cpio");
   end CPIO_Create_Failure;

   -------------------------------------------------------------------------

   procedure TAR_Errors is
   begin
      Exercise (TAR_Scenarios.Run'Access, "errors", "tar-errors", ".tar");
   end TAR_Errors;

   -------------------------------------------------------------------------

   procedure TAR_State is
   begin
      Exercise (TAR_Scenarios.Run'Access, "state", "tar-state", ".tar");
   end TAR_State;

   -------------------------------------------------------------------------

   procedure TAR_Lifetime is
   begin
      Exercise
        (TAR_Scenarios.Run'Access, "lifetime", "tar-lifetime", ".tar");
   end TAR_Lifetime;

   -------------------------------------------------------------------------

   procedure TAR_Parallel is
   begin
      Exercise
        (TAR_Scenarios.Run'Access, "parallel", "tar-parallel", ".tar");
   end TAR_Parallel;

   -------------------------------------------------------------------------

   procedure TAR_Reuse is
      Files : constant Fixture := Prepare ("tar-reuse");
      Archive : Arca.TAR.TAR_Archive_Type;
   begin
      Arca.TAR.TAR_Create (Archive, Path (Files) & "/first.tar");
      Arca.TAR.TAR_Make_Directory (Archive, "dir", 8#755#, 1, 2, Fixed_Time);
      Arca.TAR.TAR_Close (Archive);
      Arca.TAR.TAR_Create (Archive, Path (Files) & "/second.tar");
      Arca.TAR.TAR_Make_Directory (Archive, "dir", 8#755#, 1, 2, Fixed_Time);
      Arca.TAR.TAR_Close (Archive);
      Assert_Equal_Files
        (Path (Files) & "/first.tar", Path (Files) & "/second.tar");
   end TAR_Reuse;

   -------------------------------------------------------------------------

   procedure TAR_Create_Failure is
      Files : constant Fixture := Prepare ("tar-create-failure");
      Archive : Arca.TAR.TAR_Archive_Type;
   begin
      begin
         Arca.TAR.TAR_Create (Archive, Path (Files) & "/absent/out.tar");
         Ahven.Fail ("Create accepted a nonexistent parent");
      exception
         when Ada.IO_Exceptions.Name_Error => null;
      end;
      Arca.TAR.TAR_Create (Archive, Path (Files) & "/retry.tar");
      Arca.TAR.TAR_Close (Archive);
      Arca.TAR.TAR_Create (Archive, Path (Files) & "/reference.tar");
      Arca.TAR.TAR_Close (Archive);
      Assert_Equal_Files
        (Path (Files) & "/retry.tar", Path (Files) & "/reference.tar");
   end TAR_Create_Failure;

   -------------------------------------------------------------------------

   overriding procedure Initialize (Item : in out CPIO_Case) is
   begin
      Set_Name (Item, "CPIO");
      Add_Test_Routine (Item, CPIO_Errors'Access, "error contracts");
      Add_Test_Routine (Item, CPIO_State'Access, "open Create preserves state");
      Add_Test_Routine (Item, CPIO_Lifetime'Access, "owner lifetime cleanup");
      Add_Test_Routine (Item, CPIO_Parallel'Access, "parallel instances");
      Add_Test_Routine (Item, CPIO_Reuse'Access, "closed writer reuse");
      Add_Test_Routine
        (Item, CPIO_Create_Failure'Access, "failed Create retry");
   end Initialize;

   -------------------------------------------------------------------------

   overriding procedure Initialize (Item : in out TAR_Case) is
   begin
      Set_Name (Item, "TAR");
      Add_Test_Routine (Item, TAR_Errors'Access, "error contracts");
      Add_Test_Routine (Item, TAR_State'Access, "open Create preserves state");
      Add_Test_Routine (Item, TAR_Lifetime'Access, "owner lifetime cleanup");
      Add_Test_Routine (Item, TAR_Parallel'Access, "parallel instances");
      Add_Test_Routine (Item, TAR_Reuse'Access, "closed writer reuse");
      Add_Test_Routine (Item, TAR_Create_Failure'Access, "failed Create retry");
   end Initialize;

end Writer_Unit_Tests;
