-- SPDX-License-Identifier: LGPL-2.1-or-later

with Ada.Calendar.Formatting;
with Ada.Directories;
with Ada.Exceptions;
with Ada.IO_Exceptions;
with Ada.Streams.Stream_IO;
with Ada.Strings.Unbounded;
with Ahven;
with Arca.CPIO;
with Arca.TAR;
with CPIO_Scenarios;
with TAR_Scenarios;
with Test_Support;
with Unit_Support;
with GNAT.OS_Lib;

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

   generic
      type Writer_Type is limited private;
      with procedure Create_Archive (Item : in out Writer_Type; Name : String);
      --  Open one output through the public writer API.

      with procedure Close_Archive (Item : in out Writer_Type);
      --  Complete and close the writer as a positive control.

   procedure Finalizer_Failure_Checks;
   --  Preserve caller failures and close handles when deletion is rejected.

   procedure Finalizer_Failure_Checks is
      use Ada.Strings.Unbounded;
      use type Ada.Directories.File_Size;
      package SIO renames Ada.Streams.Stream_IO;
      Marker : exception;
      Work : Unbounded_String;
      Before : constant Natural := Test_Support.Open_Descriptor_Count;
   begin
      --  Explicit Close is valid for a nonregular destination too.
      declare
         Item : Writer_Type;
      begin
         Create_Archive (Item, "/dev/null");
         Close_Archive (Item);
      end;
      Ahven.Assert
        (Test_Support.Open_Descriptor_Count = Before,
         "Explicit Close leaked a nonregular output descriptor");

      for Nonregular in reverse Boolean loop
         for Raise_Original in Boolean loop
            declare
               Files : constant Fixture := Prepare_Native ("writer-finalizer");
               Output : constant String :=
                 (if Nonregular then "/dev/null" else Path (Files) & "/part");
               Raised : Boolean := False;
            begin
               Work := To_Unbounded_String (Path (Files));
               begin
                  declare
                     Item : Writer_Type;
                  begin
                     Create_Archive (Item, Output);
                     if not Nonregular then
                        GNAT.OS_Lib.Set_Non_Writable (Path (Files));
                        --  Prove that this filesystem enforces the fault.
                        declare
                           Probe : SIO.File_Type;
                           Denied : Boolean := False;
                        begin
                           begin
                              SIO.Create
                                (Probe, SIO.Out_File, Path (Files) & "/probe",
                                 "shared=no");
                              SIO.Close (Probe);
                           exception
                              when Ada.IO_Exceptions.Name_Error |
                                   Ada.IO_Exceptions.Use_Error =>
                                 Denied := True;
                           end;
                           Ahven.Assert
                             (Denied, "Native permission fault was not active");
                        end;
                     end if;
                     if Raise_Original then
                        raise Marker with "original writer caller failure";
                     end if;
                  end;
               exception
                  when Error : Marker =>
                     Ahven.Assert
                       (Ada.Exceptions.Exception_Message (Error) =
                        "original writer caller failure",
                        "Finalization changed the caller exception message");
                     Raised := True;
               end;
               Ahven.Assert
                 (Raised = Raise_Original,
                  "Finalization changed caller exception propagation");
               Ahven.Assert
                 (Test_Support.Open_Descriptor_Count = Before,
                  "Failed finalization leaked an output descriptor");
               Ahven.Assert
                 (Ada.Directories.Exists (Output),
                  "Cleanup removed a nonregular or undeletable output");
               if not Nonregular then
                  Ahven.Assert
                    (Ada.Directories.Size (Output) = 0,
                     "Cleanup invented bytes in the incomplete archive");
               end if;
            end;
            Ahven.Assert
              (not Ada.Directories.Exists (To_String (Work)),
               "Native cleanup fixture survived its owner");
         end loop;
      end loop;
   end Finalizer_Failure_Checks;

   -------------------------------------------------------------------------

   procedure CPIO_Finalizer_Failures is new Finalizer_Failure_Checks
     (Arca.CPIO.CPIO_Archive_Type,
      Arca.CPIO.CPIO_Create, Arca.CPIO.CPIO_Close);
   --  Exercise CPIO's finalizer through normal and exceptional scope exit.

   procedure TAR_Finalizer_Failures is new Finalizer_Failure_Checks
     (Arca.TAR.TAR_Archive_Type, Arca.TAR.TAR_Create, Arca.TAR.TAR_Close);
   --  Exercise TAR's finalizer with the same independent failure fixtures.

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
      Add_Test_Routine
        (Item, CPIO_Finalizer_Failures'Access, "finalizer failure cleanup");
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
      Add_Test_Routine
        (Item, TAR_Finalizer_Failures'Access, "finalizer failure cleanup");
      Add_Test_Routine (Item, TAR_Parallel'Access, "parallel instances");
      Add_Test_Routine (Item, TAR_Reuse'Access, "closed writer reuse");
      Add_Test_Routine (Item, TAR_Create_Failure'Access, "failed Create retry");
   end Initialize;

end Writer_Unit_Tests;
