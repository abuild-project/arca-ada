--  SPDX-License-Identifier: GPL-2.0-or-later

with Ada.Strings.Unbounded;

package body Archive_CLI.Diagnostics is

   use Ada.Strings.Unbounded;
   use type Ada.Exceptions.Exception_Id;

   --  Run owns this state on the sequential command path. Interrupt handlers
   --  access only the separate protected cancellation object.
   Full_Text : Unbounded_String;
   Identity  : Ada.Exceptions.Exception_Id := Ada.Exceptions.Null_Id;

   procedure Reset
   is
   begin
      Full_Text := Null_Unbounded_String;
      Identity := Ada.Exceptions.Null_Id;
   end Reset;

   -------------------------------------------------------------------------

   procedure Fail_Usage (Text : String)
   is
   begin
      Full_Text := To_Unbounded_String (Text);
      Identity := Usage_Error'Identity;
      raise Usage_Error with Text;
   end Fail_Usage;

   -------------------------------------------------------------------------

   procedure Fail_Command (Text : String)
   is
   begin
      Full_Text := To_Unbounded_String (Text);
      Identity := Command_Error'Identity;
      raise Command_Error with Text;
   end Fail_Command;

   -------------------------------------------------------------------------

   function Message
     (Error : Ada.Exceptions.Exception_Occurrence) return String
   is
      Runtime_Text : constant String :=
        Ada.Exceptions.Exception_Message (Error);
   begin
      if Identity = Ada.Exceptions.Exception_Identity (Error) then
         return To_String (Full_Text);
      elsif Runtime_Text /= "" then
         return Runtime_Text;
      else
         return Ada.Exceptions.Exception_Name (Error);
      end if;
   end Message;

   -------------------------------------------------------------------------

   function Display (Text : String) return String
   is
      Hex    : constant String := "0123456789abcdef";
      Result : Unbounded_String;
   begin
      for C of Text loop
         if C = '\' then
            Append (Result, "\\");
         elsif Character'Pos (C) < 32 or else Character'Pos (C) = 127 then
            Append
              (Result, "\x" & Hex (Character'Pos (C) / 16 + 1) &
               Hex (Character'Pos (C) mod 16 + 1));
         else
            Append (Result, C);
         end if;
      end loop;

      return To_String (Result);
   end Display;

end Archive_CLI.Diagnostics;
