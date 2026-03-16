-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

package body MakeOps.Core.TOML.Lexer.Standard_Mode
  with SPARK_Mode => On
is

   --  The Micro-FSM states for character-by-character line parsing.
   type Parse_Phase is
     (Idle,
      Parsing_Section,
      Parsing_Key,
      Expecting_Eq,
      Expecting_Value,
      Parsing_String_Value,
      Escaping_In_String_Value,
      In_Array_Expecting_Item,
      In_Array_Parsing_String,
      Escaping_In_Array_String,
      In_Array_Expecting_Comma_Or_End,
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
      Current_Phase : Parse_Phase := Idle;
      Cursor        : Integer := Line'First;

      --  Indexes to extract zero-allocation slices.
      --  Initialized safely to prevent SPARK overflow and underflow bounds.
      Token_Start : Integer := Line'First;
      Key_Start   : Integer := Line'First;
      Key_End     : Integer := Line'First;
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
              and Token_Start >= Line'First
              and Token_Start <= Line'Last + 1
              and Key_Start >= Line'First
              and Key_Start <= Line'Last
              and Key_End >= Line'First - 1
              and Key_End <= Line'Last
              and Value_Start >= Line'First
              and Value_Start <= Line'Last + 1
              and Key_End >= Key_Start - 1
              and Cursor >= Key_Start
              and
                (if Lexer_State.In_Array_Mode
                 then Lexer_State.Array_Start_Line = Line_Num)
              and
                (if Current_Phase = Error_State
                 then not Result.Success and then Result.Line = Line_Num
                 else Result.Success));
         pragma Loop_Variant (Increases => Cursor);

         case Current_Phase is

            --  1. Looking for a statement (Section, Key, or Comment)

            when Idle                            =>
               if Line (Cursor) = ' ' or Line (Cursor) = ASCII.HT then
                  null;
               elsif Line (Cursor) = '#' then
                  Cursor :=
                    Line'Last; -- Exit loop (comment takes rest of line)
               elsif Line (Cursor) = '[' then
                  Token_Start := Cursor + 1;
                  Current_Phase := Parsing_Section;
               elsif Line (Cursor)
                     in 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' | '-'
               then
                  Key_Start := Cursor;
                  Key_End := Cursor - 1;
                  Current_Phase := Parsing_Key;
               else
                  Result :=
                    (False,
                     Unrecognized_Statement,
                     Line_Num,
                     Column_Number (Cursor));
                  Current_Phase := Error_State;
               end if;

            --  2. Inside a [Section.Name] header

            when Parsing_Section                 =>
               if Line (Cursor) = ']' then
                  if Cursor = Token_Start then
                     Result :=
                       (False,
                        Malformed_Section_Header,
                        Line_Num,
                        Column_Number (Cursor));
                     Current_Phase := Error_State;
                  else
                     Listener.On_Section_Found
                       (Name   => Line (Token_Start .. Cursor - 1),
                        Line   => Line_Num,
                        Column =>
                          Column_Number
                            (Integer'Max (Line'First, Token_Start - 1)));
                     Current_Phase := Trailing_Garbage;
                  end if;
               elsif Line (Cursor) = '[' then
                  Result :=
                    (False,
                     Malformed_Section_Header,
                     Line_Num,
                     Column_Number (Cursor));
                  Current_Phase := Error_State;
               end if;

            --  3. Scanning a Key name before '='

            when Parsing_Key                     =>
               if Line (Cursor) = ' ' or Line (Cursor) = ASCII.HT then
                  Key_End := Cursor - 1;
                  Current_Phase := Expecting_Eq;
               elsif Line (Cursor) = '=' then
                  Key_End := Cursor - 1;
                  Current_Phase := Expecting_Value;
               elsif Line (Cursor)
                     not in 'a' .. 'z'
                          | 'A' .. 'Z'
                          | '0' .. '9'
                          | '_'
                          | '-'
                          | '.'
               then
                  Result :=
                    (False,
                     Unrecognized_Statement,
                     Line_Num,
                     Column_Number (Cursor));
                  Current_Phase := Error_State;
               end if;

            --  4. Key is finished, skipping spaces to find '='

            when Expecting_Eq                    =>
               if Line (Cursor) = '=' then
                  Current_Phase := Expecting_Value;
               elsif Line (Cursor) /= ' ' and Line (Cursor) /= ASCII.HT then
                  Result :=
                    (False,
                     Unrecognized_Statement,
                     Line_Num,
                     Column_Number (Cursor));
                  Current_Phase := Error_State;
               end if;

            --  5. Found '=', looking for a Value

            when Expecting_Value                 =>
               if Line (Cursor) = '"' then
                  Value_Start := Cursor + 1;
                  Current_Phase := Parsing_String_Value;
               elsif Line (Cursor) = '[' then
                  --  Array detected. Trigger event and update Macro-FSM state.
                  Listener.On_Array_Start
                    (Key    => Line (Key_Start .. Key_End),
                     Line   => Line_Num,
                     Column => Column_Number (Key_Start));

                  Lexer_State.In_Array_Mode := True;
                  Lexer_State.Array_Start_Line := Line_Num;
                  Lexer_State.Array_Start_Column := Column_Number (Cursor);

                  Current_Phase := In_Array_Expecting_Item;
               elsif Line (Cursor) /= ' ' and Line (Cursor) /= ASCII.HT then
                  Result :=
                    (False,
                     Unsupported_Value_Type,
                     Line_Num,
                     Column_Number (Cursor));
                  Current_Phase := Error_State;
               end if;

            --  6. Reading a "String" value

            when Parsing_String_Value            =>
               if Line (Cursor) = '\' then
                  Current_Phase := Escaping_In_String_Value;
               elsif Line (Cursor) = '"' then
                  Listener.On_String_Value_Found
                    (Key    => Line (Key_Start .. Key_End),
                     Value  => Line (Value_Start .. Cursor - 1),
                     Line   => Line_Num,
                     Column => Column_Number (Key_Start));
                  Current_Phase := Trailing_Garbage;
               end if;

            when Escaping_In_String_Value        =>
               --  Unconditionally consume the escaped character
               Current_Phase := Parsing_String_Value;

            --  7. Inline Array logic (Array started on the current line)

            when In_Array_Expecting_Item         =>
               if Line (Cursor) = ' ' or Line (Cursor) = ASCII.HT then
                  null;
               elsif Line (Cursor) = '"' then
                  Value_Start := Cursor + 1;
                  Current_Phase := In_Array_Parsing_String;
               elsif Line (Cursor) = ']' then
                  Lexer_State.In_Array_Mode := False;
                  Listener.On_Array_End
                    (Line => Line_Num, Column => Column_Number (Cursor));
                  Current_Phase := Trailing_Garbage;
               elsif Line (Cursor) = '[' then
                  Result :=
                    (False,
                     Unsupported_Value_Type,
                     Line_Num,
                     Column_Number (Cursor));
                  Current_Phase := Error_State;
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

            --  8. Parsing a string inside the inline array

            when In_Array_Parsing_String         =>
               if Line (Cursor) = '\' then
                  Current_Phase := Escaping_In_Array_String;
               elsif Line (Cursor) = '"' then
                  Listener.On_Array_Item
                    (Value  => Line (Value_Start .. Cursor - 1),
                     Line   => Line_Num,
                     Column =>
                       Column_Number
                         (Integer'Max (Line'First, Value_Start - 1)));
                  Current_Phase := In_Array_Expecting_Comma_Or_End;
               end if;

            when Escaping_In_Array_String        =>
               --  Unconditionally consume the escaped character
               Current_Phase := In_Array_Parsing_String;

            --  9. After an array element, looking for `,` or `]`

            when In_Array_Expecting_Comma_Or_End =>
               if Line (Cursor) = ' ' or Line (Cursor) = ASCII.HT then
                  null;
               elsif Line (Cursor) = ',' then
                  Current_Phase := In_Array_Expecting_Item;
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

            --  10. Statement successfully complete, skipping trailing spaces

            when Trailing_Garbage                =>
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

            when Error_State                     =>
               null;

         end case;

         if Current_Phase /= Error_State then
            Cursor := Cursor + 1;
         end if;
      end loop;

      --  Final End-Of-Line Validations (e.g., detecting unclosed strings)
      if Current_Phase /= Error_State then
         case Current_Phase is
            when Idle
               | Trailing_Garbage
               | In_Array_Expecting_Item
               | In_Array_Expecting_Comma_Or_End              =>
               --  These are valid states to end a line in our dialect.
               null;

            when Parsing_Section                              =>
               Result :=
                 (False,
                  Malformed_Section_Header,
                  Line_Num,
                  Column_Number (Integer'Max (Line'First, Token_Start - 1)));

            when Parsing_String_Value
               | Escaping_In_String_Value
               | In_Array_Parsing_String
               | Escaping_In_Array_String                     =>
               Result :=
                 (False,
                  Unrecognized_Statement,
                  Line_Num,
                  Column_Number (Integer'Max (Line'First, Value_Start - 1)));

            when Parsing_Key | Expecting_Eq | Expecting_Value =>
               Result :=
                 (False,
                  Unrecognized_Statement,
                  Line_Num,
                  Column_Number (Key_Start));

            when Error_State                                  =>
               null; -- Handled automatically
         end case;
      end if;

   end Process_Line;

end MakeOps.Core.TOML.Lexer.Standard_Mode;
