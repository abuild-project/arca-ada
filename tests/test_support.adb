--  SPDX-License-Identifier: LGPL-2.1-or-later

with Ada.Strings.Fixed;
with GNAT.Directory_Operations;

package body Test_Support is

   use type Ada.Exceptions.Exception_Id;

   procedure Check (Condition : Boolean; Message : String)
   is
   begin
      if not Condition then
         raise Program_Error with Message;
      end if;
   end Check;

   -------------------------------------------------------------------------

   procedure Expect_Failure
     (Action   : not null access procedure;
      Identity : Ada.Exceptions.Exception_Id;
      Message  : String)
   is
      Raised : Boolean := False;
   begin
      begin
         Action.all;
      exception
         when Error : others =>
            Check
              (Ada.Exceptions.Exception_Identity (Error) = Identity,
               Ada.Exceptions.Exception_Information (Error));
            Check
              (Ada.Strings.Fixed.Index
                 (Ada.Exceptions.Exception_Message (Error), Message) > 0,
               "Unexpected failure message: " &
                 Ada.Exceptions.Exception_Message (Error));
            Raised := True;
      end;
      Check (Raised, "Expected failure was not raised: " & Message);
   end Expect_Failure;

   -------------------------------------------------------------------------

   function Open_Descriptor_Count return Natural
   is
      use GNAT.Directory_Operations;

      Search : Dir_Type;
      Name   : String (1 .. 64);
      Last   : Natural;
      Count  : Natural := 0;
   begin
      Open (Search, "/proc/self/fd");
      loop
         Read (Search, Name, Last);
         exit when Last = 0;
         Count := Count + 1;
      end loop;
      Close (Search);
      return Count;
   exception
      when others =>
         if Is_Open (Search) then
            Close (Search);
         end if;
         raise;
   end Open_Descriptor_Count;

end Test_Support;
