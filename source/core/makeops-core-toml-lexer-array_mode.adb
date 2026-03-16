-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

package body MakeOps.Core.TOML.Lexer.Array_Mode
  with SPARK_Mode => On
is

   --  The Micro-FSM states for parsing lines while inside a multi-line array.
   type Parse_Phase is
     (Expecting_Item,
      Parsing_String,
      Escaping_In_String,
      Expecting_Comma_Or_End,
      Trailing_Garbage,
      Error_State);

   -------------------------------------------------------------------------
   --  Process_Line
   -------------------------------------------------------------------------
   procedure Process_Line
     (Lexer_State : in out State;
      Line        : TOML_Line;
      Line_Num    : Line_Number;
      Listener    : in out Lexer_Listener'Class;
      Result      : out Lexical_Result)
   is
      Current_Phase : Parse_Phase := Expecting_Item;
      Cursor        : Integer := Line'First;

      --  Index to extract zero-allocation string slices.
      --  Initialized safely to prevent SPARK overflow and underflow bounds.
      Value_Start : Integer := Line'First;

   begin
      --  Initialize out parameter per SPARK requirements
      Result := (Success => True);

      --  Main Flat Micro-FSM Loop
      while Cursor <= Line'Last and Current_Phase /= Error_State loop
         pragma
           Loop_Invariant
             (Cursor >= Line'First
              and Cursor <= Line'Last + 1
              and Value_Start >= Line'First
              and Value_Start <= Line'Last + 1
              and
                (if Current_Phase = Error_State
                 then not Result.Success and then Result.Line = Line_Num
                 else Result.Success));
         pragma Loop_Variant (Increases => Cursor);

         case Current_Phase is

            --  1. Waiting for a string element, closing bracket, or comment

            when Expecting_Item         =>
               if Line (Cursor) = ' ' or Line (Cursor) = ASCII.HT then
                  null;
               elsif Line (Cursor) = '"' then
                  Value_Start := Cursor + 1;
                  Current_Phase := Parsing_String;
               elsif Line (Cursor) = ']' then
                  Lexer_State.In_Array_Mode := False;
                  Listener.On_Array_End
                    (Line => Line_Num, Column => Column_Number (Cursor));
                  Current_Phase := Trailing_Garbage;
               elsif Line (Cursor) = '[' then
                  --  Dialect restriction: Nested arrays `[[..]]`
                  --  are unsupported.
                  Result :=
                    (False,
                     Unsupported_Value_Type,
                     Line_Num,
                     Column_Number (Cursor));
                  Current_Phase := Error_State;
               elsif Line (Cursor) = '#' then
                  Cursor :=
                    Line'Last; -- Exit loop (comment takes rest of line)
               else
                  --  Fail-fast on unquoted items, stray characters, etc.
                  Result :=
                    (False,
                     Unrecognized_Statement,
                     Line_Num,
                     Column_Number (Cursor));
                  Current_Phase := Error_State;
               end if;

            --  2. Reading characters inside a "String"

            when Parsing_String         =>
               if Line (Cursor) = '\' then
                  Current_Phase := Escaping_In_String;
               elsif Line (Cursor) = '"' then
                  Listener.On_Array_Item
                    (Value  => Line (Value_Start .. Cursor - 1),
                     Line   => Line_Num,
                     Column =>
                       Column_Number
                         (Integer'Max (Line'First, Value_Start - 1)));
                  Current_Phase := Expecting_Comma_Or_End;
               end if;

            when Escaping_In_String     =>
               --  Unconditionally consume the escaped character
               Current_Phase := Parsing_String;

            --  3. After a string element, looking for a comma or end bracket

            when Expecting_Comma_Or_End =>
               if Line (Cursor) = ' ' or Line (Cursor) = ASCII.HT then
                  null;
               elsif Line (Cursor) = ',' then
                  Current_Phase := Expecting_Item;
               elsif Line (Cursor) = ']' then
                  Lexer_State.In_Array_Mode := False;
                  Listener.On_Array_End
                    (Line => Line_Num, Column => Column_Number (Cursor));
                  Current_Phase := Trailing_Garbage;
               elsif Line (Cursor) = '#' then
                  Cursor := Line'Last; -- Exit loop
               else
                  Result :=
                    (False,
                     Unrecognized_Statement,
                     Line_Num,
                     Column_Number (Cursor));
                  Current_Phase := Error_State;
               end if;

            --  4. Array block ended on this line,
            --     checking for stray characters

            when Trailing_Garbage       =>
               if Line (Cursor) = '#' then
                  Cursor := Line'Last; -- Exit loop
               elsif Line (Cursor) /= ' ' and Line (Cursor) /= ASCII.HT then
                  Result :=
                    (False,
                     Unrecognized_Statement,
                     Line_Num,
                     Column_Number (Cursor));
                  Current_Phase := Error_State;
               end if;

            when Error_State            =>
               null;

         end case;

         if Current_Phase /= Error_State then
            Cursor := Cursor + 1;
         end if;
      end loop;

      --  Final End-Of-Line Validations
      if Current_Phase /= Error_State then
         case Current_Phase is
            when Expecting_Item | Expecting_Comma_Or_End | Trailing_Garbage =>
               --  These are perfectly valid states to pause parsing and move
               --  to the next line (multi-line arrays).
               null;

            when Parsing_String | Escaping_In_String                        =>
               --  Strings cannot span multiple lines in our TOML dialect.
               Result :=
                 (False,
                  Unrecognized_Statement,
                  Line_Num,
                  Column_Number (Integer'Max (Line'First, Value_Start - 1)));

            when Error_State                                                =>
               null; -- Handled automatically
         end case;
      end if;

   end Process_Line;

end MakeOps.Core.TOML.Lexer.Array_Mode;
