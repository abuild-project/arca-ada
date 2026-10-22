-- SPDX-License-Identifier: LGPL-2.1-or-later

with Ada.Command_Line;
with Ada.Environment_Variables;
with Ada.Strings.Fixed;
with Ada.Text_IO;

package body Archive_CLI.Options is

   use Ada.Command_Line;
   use Ada.Strings.Unbounded;
   use type Interfaces.Unsigned_32;

   function Number
     (Text, Name : String;
      Limit      : Long_Long_Integer)
      return Long_Long_Integer;
   --  Parse unsigned decimal digits with overflow checks before arithmetic.

   function Number
     (Text, Name : String;
      Limit      : Long_Long_Integer)
      return Long_Long_Integer
   is
      Result : Long_Long_Integer := 0;
   begin
      if Text'Length = 0 then
         raise Usage_Error with Name & " requires a decimal integer";
      end if;

      for C of Text loop
         if C not in '0' .. '9' then
            raise Usage_Error with Name & " requires a decimal integer";
         end if;

         declare
            Digit : constant Long_Long_Integer :=
              Character'Pos (C) - Character'Pos ('0');
         begin
            if Result > (Limit - Digit) / 10 then
               raise Usage_Error with Name & " is out of range";
            end if;

            Result := Result * 10 + Digit;
         end;
      end loop;

      return Result;
   end Number;

   -------------------------------------------------------------------------

   function Parse return Settings is
      type Option_Kind is
        (Format_Option, Root_Option, Output_Option,
         UID_Option, GID_Option, Time_Option, Force_Option);

      Seen   : array (Option_Kind) of Boolean := (others => False);
      Result : Settings;
      Index  : Positive := 2;
   begin
      if Argument_Count = 1
        and then (Argument (1) = "--help" or else Argument (1) = "-h")
      then
         Result.Command := Help_Command;
         return Result;
      elsif Argument_Count = 1 and then Argument (1) = "--version" then
         Result.Command := Version_Command;
         return Result;
      elsif Argument_Count = 0 or else Argument (1) /= "create" then
         raise Usage_Error with "expected the create command; use --help";
      end if;

      while Index <= Argument_Count loop
         declare
            Arg   : constant String := Argument (Index);
            Split : constant Natural := Ada.Strings.Fixed.Index (Arg, "=");
            Name  : constant String :=
              (if Split = 0 then Arg else Arg (Arg'First .. Split - 1));

            Kind  : Option_Kind;
            Value : Unbounded_String;
         begin
            if Arg = "--help" or else Arg = "-h" then
               Result.Command := Help_Command;
               return Result;
            elsif Name = "--format" then
               Kind := Format_Option;
            elsif Name = "-C" or else Name = "--directory" then
               Kind := Root_Option;
            elsif Name = "-o" or else Name = "--output" then
               Kind := Output_Option;
            elsif Name = "--uid" then
               Kind := UID_Option;
            elsif Name = "--gid" then
               Kind := GID_Option;
            elsif Name = "--mtime" then
               Kind := Time_Option;
            elsif Name = "--force" then
               Kind := Force_Option;
            else
               raise Usage_Error with "unknown option: " & Arg;
            end if;

            if Seen (Kind) then
               raise Usage_Error with "duplicate option: " & Name;
            end if;

            Seen (Kind) := True;

            if Kind = Force_Option then
               if Split /= 0 then
                  raise Usage_Error with "--force does not take a value";
               end if;

               Result.Force := True;
            else
               if Split /= 0 then
                  Value := To_Unbounded_String (Arg (Split + 1 .. Arg'Last));
               else
                  Index := Index + 1;
                  if Index > Argument_Count then
                     raise Usage_Error with Name & " requires a value";
                  end if;

                  Value := To_Unbounded_String (Argument (Index));
               end if;

               if Length (Value) = 0 then
                  raise Usage_Error with Name & " requires a value";
               end if;

               case Kind is
                  when Format_Option =>
                     if Value = "cpio" then
                        Result.Format := CPIO_Format;
                     elsif Value = "tar" then
                        Result.Format := TAR_Format;
                     else
                        raise Usage_Error with "format must be cpio or tar";
                     end if;

                  when Root_Option =>
                     Result.Directory := Value;

                  when Output_Option =>
                     Result.Output := Value;

                  when UID_Option | GID_Option =>
                     declare
                        Owner : constant Owner_Override :=
                          (True, Interfaces.Unsigned_32
                             (Number (To_String (Value), Name, 2 ** 32 - 1)));
                     begin
                        if Kind = UID_Option then
                           Result.UID := Owner;
                        else
                           Result.GID := Owner;
                        end if;
                     end;

                  when Time_Option =>
                     Result.MTime :=
                       (True, Number (To_String (Value), Name,
                                      Long_Long_Integer'Last));

                  when Force_Option =>
                     null;
               end case;
            end if;
         end;

         Index := Index + 1;
      end loop;

      if not Seen (Format_Option) or else not Seen (Output_Option) then
         raise Usage_Error with "--format and --output are required";
      end if;

      if Result.Output = "-" then
         raise Usage_Error with "choose an output file instead of stdout";
      end if;

      if not Result.MTime.Present
        and then Ada.Environment_Variables.Exists ("SOURCE_DATE_EPOCH")
      then
         Result.MTime :=
           (True, Number
              (Ada.Environment_Variables.Value ("SOURCE_DATE_EPOCH"),
               "SOURCE_DATE_EPOCH", Long_Long_Integer'Last));
      end if;

      declare
         Max_Time : constant Long_Long_Integer :=
           (if Result.Format = CPIO_Format then 2 ** 32 - 1
            else 2 ** 33 - 1);
      begin
         if Result.MTime.Present and then Result.MTime.Value > Max_Time then
            raise Usage_Error with "mtime is outside the selected format";
         end if;

         if Result.Format = TAR_Format
           and then
             ((Result.UID.Present and then Result.UID.Value > 2 ** 21 - 1)
              or else
              (Result.GID.Present and then Result.GID.Value > 2 ** 21 - 1))
         then
            raise Usage_Error with "owner is outside the TAR field range";
         end if;
      end;

      return Result;
   end Parse;

   -------------------------------------------------------------------------

   procedure Print_Help is
      use Ada.Text_IO;
   begin
      Put_Line
        ("Usage: arca create --format cpio|tar -o ARCHIVE [-C DIRECTORY]");
      Put_Line ("  --uid N, --gid N   Override numeric source owners");
      Put_Line ("  --mtime SECONDS   Override UNIX mtime (unsigned decimal)");
      Put_Line ("  --force           Replace an existing regular file or link");
      Put_Line ("  --help, -h        Show help; --version shows the version");

      New_Line;

      Put_Line ("Archives contain DIRECTORY's contents in lexical order.");
      Put_Line ("Source modes and metadata are preserved unless overridden.");
      Put_Line ("SOURCE_DATE_EPOCH supplies mtime when --mtime is absent.");
      Put_Line ("Symlinks are preserved; regular-file hardlinks share data.");
      Put_Line ("Output is published after completion; existing output is");
      Put_Line ("excluded from the input tree and needs --force to replace.");
   end Print_Help;

end Archive_CLI.Options;
