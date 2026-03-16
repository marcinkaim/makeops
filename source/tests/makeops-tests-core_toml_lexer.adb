-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

pragma SPARK_Mode (Off);

with AUnit.Assertions;
with MakeOps.Core.TOML.Lexer;

package body MakeOps.Tests.Core_TOML_Lexer is

   use AUnit.Assertions;
   use Ada.Strings.Unbounded;
   use MakeOps.Core.TOML;
   use MakeOps.Core.TOML.Lexer;

   -------------------------------------------------------------------------
   --  Mock Listener Implementation
   -------------------------------------------------------------------------

   overriding
   procedure On_Section_Found
     (Listener : in out Mock_Listener;
      Name     : TOML_Lexeme;
      Line     : Line_Number;
      Column   : Column_Number)
   is
      pragma Unreferenced (Line, Column);
   begin
      Listener.Section_Found_Count := Listener.Section_Found_Count + 1;
      Listener.Last_Section_Name := To_Unbounded_String (Name);
   end On_Section_Found;

   overriding
   procedure On_String_Value_Found
     (Listener : in out Mock_Listener;
      Key      : TOML_Lexeme;
      Value    : TOML_Lexeme;
      Line     : Line_Number;
      Column   : Column_Number)
   is
      pragma Unreferenced (Line, Column);
   begin
      Listener.String_Value_Found_Count :=
        Listener.String_Value_Found_Count + 1;
      Listener.Last_Key := To_Unbounded_String (Key);
      Listener.Last_String_Value := To_Unbounded_String (Value);
   end On_String_Value_Found;

   overriding
   procedure On_Array_Start
     (Listener : in out Mock_Listener;
      Key      : TOML_Lexeme;
      Line     : Line_Number;
      Column   : Column_Number)
   is
      pragma Unreferenced (Line, Column);
   begin
      Listener.Array_Start_Count := Listener.Array_Start_Count + 1;
      Listener.Last_Key := To_Unbounded_String (Key);
   end On_Array_Start;

   overriding
   procedure On_Array_Item
     (Listener : in out Mock_Listener;
      Value    : TOML_Lexeme;
      Line     : Line_Number;
      Column   : Column_Number)
   is
      pragma Unreferenced (Line, Column);
   begin
      Listener.Array_Item_Count := Listener.Array_Item_Count + 1;
      Listener.Last_String_Value := To_Unbounded_String (Value);
   end On_Array_Item;

   overriding
   procedure On_Array_End
     (Listener : in out Mock_Listener;
      Line     : Line_Number;
      Column   : Column_Number)
   is
      pragma Unreferenced (Line, Column);
   begin
      Listener.Array_End_Count := Listener.Array_End_Count + 1;
   end On_Array_End;

   overriding
   procedure On_End_Of_File (Listener : in out Mock_Listener) is
   begin
      Listener.EOF_Reached_Count := Listener.EOF_Reached_Count + 1;
   end On_End_Of_File;

   procedure Reset (Listener : in out Mock_Listener) is
   begin
      Listener.Section_Found_Count := 0;
      Listener.String_Value_Found_Count := 0;
      Listener.Array_Start_Count := 0;
      Listener.Array_Item_Count := 0;
      Listener.Array_End_Count := 0;
      Listener.EOF_Reached_Count := 0;
      Listener.Last_Section_Name := Null_Unbounded_String;
      Listener.Last_Key := Null_Unbounded_String;
      Listener.Last_String_Value := Null_Unbounded_String;
   end Reset;

   -------------------------------------------------------------------------
   --  AUnit Test_Case Overrides
   -------------------------------------------------------------------------

   overriding
   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Lexer Tests");
   end Name;

   overriding
   procedure Set_Up (T : in out Test_Case) is
   begin
      --  Clean the mock listener state before each test
      Reset (T.Mock);
   end Set_Up;

   overriding
   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      --  1. Initial_State tests
      Register_Routine
        (T,
         Test_Initial_State_Independence'Access,
         "Test_Initial_State_Independence");

      --  2a. Process_Line: Happy Paths
      Register_Routine
        (T,
         Test_Process_Line_Valid_Section'Access,
         "Test_Process_Line_Valid_Section");
      Register_Routine
        (T,
         Test_Process_Line_String_Value'Access,
         "Test_Process_Line_String_Value");
      Register_Routine
        (T,
         Test_Process_Line_Single_Line_Array'Access,
         "Test_Process_Line_Single_Line_Array");
      Register_Routine
        (T,
         Test_Process_Line_Multi_Line_Array'Access,
         "Test_Process_Line_Multi_Line_Array");

      --  2b. Process_Line: Edge & Corner Cases (Happy Paths)
      Register_Routine
        (T,
         Test_Process_Line_Inline_Comment'Access,
         "Test_Process_Line_Inline_Comment");
      Register_Routine
        (T,
         Test_Process_Line_Empty_Array'Access,
         "Test_Process_Line_Empty_Array");
      Register_Routine
        (T,
         Test_Process_Line_Empty_String_Value'Access,
         "Test_Process_Line_Empty_String_Value");
      Register_Routine
        (T,
         Test_Sensitive_Chars_In_Strings'Access,
         "Test_Sensitive_Chars_In_Strings");
      Register_Routine
        (T, Test_String_Escaping'Access, "Test_String_Escaping");
      Register_Routine
        (T,
         Test_No_Trailing_Newline_At_EOF'Access,
         "Test_No_Trailing_Newline_At_EOF");

      --  2c. Process_Line: Error Cases (Fail-Fast)
      Register_Routine
        (T,
         Test_Process_Line_Empty_And_Comments'Access,
         "Test_Process_Line_Empty_And_Comments");
      Register_Routine
        (T,
         Test_Process_Line_Malformed_Section'Access,
         "Test_Process_Line_Malformed_Section");
      Register_Routine
        (T,
         Test_Process_Line_Empty_Section_Name'Access,
         "Test_Process_Line_Empty_Section_Name");
      Register_Routine
        (T,
         Test_Process_Line_Stray_Bracket'Access,
         "Test_Process_Line_Stray_Bracket");
      Register_Routine
        (T,
         Test_Process_Line_Unquoted_Value'Access,
         "Test_Process_Line_Unquoted_Value");
      Register_Routine
        (T,
         Test_Process_Line_Nested_Array'Access,
         "Test_Process_Line_Nested_Array");
      Register_Routine
        (T,
         Test_Process_Line_Missing_Equal_Sign'Access,
         "Test_Process_Line_Missing_Equal_Sign");

      --  3. Finish tests
      Register_Routine
        (T, Test_Finish_Clean_State'Access, "Test_Finish_Clean_State");
      Register_Routine
        (T, Test_Finish_Unclosed_Array'Access, "Test_Finish_Unclosed_Array");

      --  4. Complex Integration Tests
      Register_Routine
        (T,
         Test_Complex_Document_Parsing'Access,
         "Test_Complex_Document_Parsing");
      Register_Routine
        (T,
         Test_Whitespace_And_Comment_Stress'Access,
         "Test_Whitespace_And_Comment_Stress");
      Register_Routine
        (T,
         Test_State_Transition_Errors'Access,
         "Test_State_Transition_Errors");

   end Register_Tests;

   -------------------------------------------------------------------------
   --  Test Routines
   -------------------------------------------------------------------------

   -------------------------------------------------------------------------
   --  1. Initial_State tests
   -------------------------------------------------------------------------

   procedure Test_Initial_State_Independence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S1, S2         : Lexer.State;
      Dummy_Listener : Mock_Listener;
      Result         : Lexical_Result;
   begin
      --  Fetch the first clean state
      S1 := Lexer.Initial_State;

      --  Mutate S1 by forcing the Lexer into array mode
      Lexer.Process_Line
        (Lexer_State => S1,
         Line        => "deps = [",
         Line_Num    => 1,
         Listener    => Dummy_Listener,
         Result      => Result);

      --  Fetch a new, clean state
      S2 := Lexer.Initial_State;

      --  Assertions
      Assert
        (S1 /= S2,
         "Mutated state S1 must not be equal to "
         & "the newly initialized state S2");
      Assert
        (S2 = Lexer.Initial_State,
         "Initial_State function must always return "
         & "the same deterministic record");
   end Test_Initial_State_Independence;

   -------------------------------------------------------------------------
   --  2a. Happy Paths
   -------------------------------------------------------------------------

   procedure Test_Process_Line_Valid_Section
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      State  : Lexer.State := Lexer.Initial_State;
      Result : Lexical_Result;
   begin
      Lexer.Process_Line
        (Lexer_State => State,
         Line        => "[build.operations]",
         Line_Num    => 1,
         Listener    => Test_Case (T).Mock,
         Result      => Result);

      Assert
        (Result.Success, "Parsing a valid section must return Success = True");
      Assert
        (Test_Case (T).Mock.Section_Found_Count = 1,
         "Exactly one section event should be triggered");
      Assert
        (Test_Case (T).Mock.Last_Section_Name = "build.operations",
         "The extracted section name slice is incorrect");
      Assert
        (Test_Case (T).Mock.String_Value_Found_Count = 0,
         "No other event types should be triggered");
   end Test_Process_Line_Valid_Section;

   procedure Test_Process_Line_String_Value
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      State  : Lexer.State := Lexer.Initial_State;
      Result : Lexical_Result;
   begin
      Lexer.Process_Line
        (Lexer_State => State,
         Line        => "cmd = ""build""",
         Line_Num    => 1,
         Listener    => Test_Case (T).Mock,
         Result      => Result);

      Assert
        (Result.Success,
         "Parsing a valid string value assignment must return Success = True");
      Assert
        (Test_Case (T).Mock.String_Value_Found_Count = 1,
         "Exactly one string value event should be triggered");
      Assert
        (Test_Case (T).Mock.Last_Key = "cmd",
         "The extracted key slice is incorrect");
      Assert
        (Test_Case (T).Mock.Last_String_Value = "build",
         "The extracted string value slice is incorrect without quotes");
   end Test_Process_Line_String_Value;

   procedure Test_Process_Line_Single_Line_Array
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      State  : Lexer.State := Lexer.Initial_State;
      Result : Lexical_Result;
   begin
      Lexer.Process_Line
        (Lexer_State => State,
         Line        => "deps = [""dep1"", ""dep2""]",
         Line_Num    => 1,
         Listener    => Test_Case (T).Mock,
         Result      => Result);

      Assert
        (Result.Success,
         "Parsing a valid single-line array must return Success = True");
      Assert
        (Test_Case (T).Mock.Array_Start_Count = 1,
         "Exactly one Array_Start event should be triggered");
      Assert
        (Test_Case (T).Mock.Last_Key = "deps",
         "The extracted array key slice is incorrect");
      Assert
        (Test_Case (T).Mock.Array_Item_Count = 2,
         "Exactly two Array_Item events should be triggered");
      Assert
        (Test_Case (T).Mock.Last_String_Value = "dep2",
         "The last extracted array item should be 'dep2'");
      Assert
        (Test_Case (T).Mock.Array_End_Count = 1,
         "Exactly one Array_End event should be triggered "
         & "to close the structure");
   end Test_Process_Line_Single_Line_Array;

   procedure Test_Process_Line_Multi_Line_Array
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      State  : Lexer.State := Lexer.Initial_State;
      Result : Lexical_Result;
   begin
      --  Step 1: Open the array
      Lexer.Process_Line
        (Lexer_State => State,
         Line        => "deps = [",
         Line_Num    => 1,
         Listener    => Test_Case (T).Mock,
         Result      => Result);

      Assert (Result.Success, "Line 1 must be parsed successfully");
      Assert
        (Test_Case (T).Mock.Array_Start_Count = 1,
         "Array_Start must be triggered");
      Assert
        (Test_Case (T).Mock.Array_Item_Count = 0,
         "No items should be parsed yet");

      --  Step 2: Parse an item on the next line
      Lexer.Process_Line
        (Lexer_State => State,
         Line        => "   ""dep1"",",
         Line_Num    => 2,
         Listener    => Test_Case (T).Mock,
         Result      => Result);

      Assert (Result.Success, "Line 2 must be parsed successfully");
      Assert
        (Test_Case (T).Mock.Array_Item_Count = 1,
         "One Array_Item must be triggered");

      --  Step 3: Close the array on the third line
      Lexer.Process_Line
        (Lexer_State => State,
         Line        => "]",
         Line_Num    => 3,
         Listener    => Test_Case (T).Mock,
         Result      => Result);

      Assert (Result.Success, "Line 3 must be parsed successfully");
      Assert
        (Test_Case (T).Mock.Array_End_Count = 1,
         "Array_End must be triggered");
   end Test_Process_Line_Multi_Line_Array;

   -------------------------------------------------------------------------
   --  2b. Edge & Corner Cases (Happy Paths)
   -------------------------------------------------------------------------

   procedure Test_Process_Line_Inline_Comment
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      State  : Lexer.State := Lexer.Initial_State;
      Result : Lexical_Result;
   begin
      Lexer.Process_Line
        (Lexer_State => State,
         Line        => "cmd = ""make"" # this is a trailing comment",
         Line_Num    => 1,
         Listener    => Test_Case (T).Mock,
         Result      => Result);

      Assert
        (Result.Success,
         "Parsing a line with an inline comment must return Success = True");
      Assert
        (Test_Case (T).Mock.String_Value_Found_Count = 1,
         "Exactly one string value event should "
         & "be triggered before the comment");
      Assert
        (Test_Case (T).Mock.Last_Key = "cmd",
         "The extracted key slice is incorrect");
      Assert
        (Test_Case (T).Mock.Last_String_Value = "make",
         "The extracted string value slice is incorrect");
   end Test_Process_Line_Inline_Comment;

   procedure Test_Process_Line_Empty_Array
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      State  : Lexer.State := Lexer.Initial_State;
      Result : Lexical_Result;
   begin
      Lexer.Process_Line
        (Lexer_State => State,
         Line        => "deps = []",
         Line_Num    => 1,
         Listener    => Test_Case (T).Mock,
         Result      => Result);

      Assert
        (Result.Success, "Parsing an empty array must return Success = True");
      Assert
        (Test_Case (T).Mock.Array_Start_Count = 1,
         "Exactly one Array_Start event should be triggered");
      Assert
        (Test_Case (T).Mock.Last_Key = "deps",
         "The extracted array key slice is incorrect");
      Assert
        (Test_Case (T).Mock.Array_Item_Count = 0,
         "No Array_Item events should be triggered for an empty array");
      Assert
        (Test_Case (T).Mock.Array_End_Count = 1,
         "Exactly one Array_End event should be triggered");
   end Test_Process_Line_Empty_Array;

   procedure Test_Process_Line_Empty_String_Value
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      State  : Lexer.State := Lexer.Initial_State;
      Result : Lexical_Result;
   begin
      Lexer.Process_Line
        (Lexer_State => State,
         Line        => "args = """"",
         Line_Num    => 1,
         Listener    => Test_Case (T).Mock,
         Result      => Result);

      Assert
        (Result.Success,
         "Parsing an empty string value must return Success = True");
      Assert
        (Test_Case (T).Mock.String_Value_Found_Count = 1,
         "Exactly one string value event should be triggered");
      Assert
        (Test_Case (T).Mock.Last_Key = "args",
         "The extracted key slice is incorrect");
      Assert
        (Test_Case (T).Mock.Last_String_Value = "",
         "The extracted string value slice must be exactly zero-length");
   end Test_Process_Line_Empty_String_Value;

   procedure Test_Sensitive_Chars_In_Strings
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      State  : Lexer.State := Lexer.Initial_State;
      Result : Lexical_Result;
   begin
      --  Test 1: Standard key-value with sensitive chars inside
      Lexer.Process_Line
        (State,
         "cmd = ""make # [build] = []""",
         1,
         Test_Case (T).Mock,
         Result);
      Assert (Result.Success, "Sensitive characters inside string failed");
      Assert
        (Test_Case (T).Mock.Last_String_Value = "make # [build] = []",
         "String content was altered or truncated");

      --  Test 2: Array elements with sensitive chars
      State := Lexer.Initial_State;
      Lexer.Process_Line
        (State, "tags = [""C#"", ""C++""]", 1, Test_Case (T).Mock, Result);
      Assert (Result.Success, "Array with sensitive characters failed");
      Assert
        (Test_Case (T).Mock.Last_String_Value = "C++",
         "Array item parsing failed on sensitive char");
   end Test_Sensitive_Chars_In_Strings;

   procedure Test_String_Escaping (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      State  : Lexer.State := Lexer.Initial_State;
      Result : Lexical_Result;
   begin
      --  Test 1: Escaping inside a standard string value
      --  Simulates line: cmd = "echo \"Hello\""
      Lexer.Process_Line
        (Lexer_State => State,
         Line        => "cmd = ""echo \""Hello\""""",
         Line_Num    => 1,
         Listener    => Test_Case (T).Mock,
         Result      => Result);
      Assert (Result.Success, "Escaping in a standard string value failed");
      Assert
        (Test_Case (T).Mock.Last_String_Value = "echo \""Hello\""",
         "The extracted string must retain the raw escape characters");

      --  Test 2: Escaping inside an inline array
      --  Simulates line: args = ["-c", "\"escaped\""]
      State := Lexer.Initial_State;
      Lexer.Process_Line
        (Lexer_State => State,
         Line        => "args = [""-c"", ""\""escaped\""""]",
         Line_Num    => 1,
         Listener    => Test_Case (T).Mock,
         Result      => Result);
      Assert (Result.Success, "Escaping in an inline array string failed");
      Assert
        (Test_Case (T).Mock.Last_String_Value = "\""escaped\""",
         "The escaped inline array item mismatch");

      --  Test 3: Escaping inside a multi-line array
      --  Simulates line:  "C:\\path\\to\\dir",
      State := Lexer.Initial_State;
      Lexer.Process_Line (State, "paths = [", 1, Test_Case (T).Mock, Result);
      Lexer.Process_Line
        (Lexer_State => State,
         Line        => "   ""C:\\path\\to\\dir"",",
         Line_Num    => 2,
         Listener    => Test_Case (T).Mock,
         Result      => Result);
      Assert
        (Result.Success, "Escaping backslashes in a multi-line array failed");
      Assert
        (Test_Case (T).Mock.Last_String_Value = "C:\\path\\to\\dir",
         "The escaped multi-line array item mismatch");

      --  Test 4: Error Case - Unclosed string due to an escaped closing quote
      --  Simulates line: cmd = "unclosed \"
      State := Lexer.Initial_State;
      Lexer.Process_Line
        (Lexer_State => State,
         Line        => "cmd = ""unclosed \""",
         Line_Num    => 1,
         Listener    => Test_Case (T).Mock,
         Result      => Result);
      Assert
        (not Result.Success,
         "An escaped closing quote must leave the string unclosed and fail");
   end Test_String_Escaping;

   procedure Test_No_Trailing_Newline_At_EOF
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      State  : Lexer.State := Lexer.Initial_State;
      Result : Lexical_Result;
   begin
      --  Simulate reading a file that has exactly one line
      --  and no \n at the end.
      --  The file ends exactly after the last quote.
      Lexer.Process_Line
        (Lexer_State => State,
         Line        => "final_key = ""final_value""",
         Line_Num    => 1,
         Listener    => Test_Case (T).Mock,
         Result      => Result);

      Assert
        (Result.Success,
         "Parsing the final line without a trailing EOL failed");

      --  Immediately trigger EOF without any empty lines processed in between
      Lexer.Finish
        (Lexer_State => State,
         Listener    => Test_Case (T).Mock,
         Result      => Result);

      Assert
        (Result.Success,
         "Finish failed after a line without a trailing newline");
      Assert
        (Test_Case (T).Mock.EOF_Reached_Count = 1,
         "On_End_Of_File event must be triggered");
      Assert
        (Test_Case (T).Mock.String_Value_Found_Count = 1,
         "Exactly one string value should be processed");
      Assert
        (Test_Case (T).Mock.Last_String_Value = "final_value",
         "The extracted string value mismatch");
   end Test_No_Trailing_Newline_At_EOF;

   -------------------------------------------------------------------------
   --  2c. Error Cases (Fail-Fast)
   -------------------------------------------------------------------------

   procedure Test_Process_Line_Empty_And_Comments
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      State  : Lexer.State := Lexer.Initial_State;
      Result : Lexical_Result;
   begin
      Lexer.Process_Line
        (Lexer_State => State,
         Line        => "   # Just a comment line with whitespaces",
         Line_Num    => 1,
         Listener    => Test_Case (T).Mock,
         Result      => Result);

      Assert
        (Result.Success, "Empty and comment lines must return Success = True");
      Assert
        (Test_Case (T).Mock.Section_Found_Count = 0
         and then Test_Case (T).Mock.String_Value_Found_Count = 0
         and then Test_Case (T).Mock.Array_Start_Count = 0,
         "No events should be emitted for comment lines");
   end Test_Process_Line_Empty_And_Comments;

   procedure Test_Process_Line_Malformed_Section
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      State  : Lexer.State := Lexer.Initial_State;
      Result : Lexical_Result;
   begin
      Lexer.Process_Line
        (Lexer_State => State,
         Line        => "[unclosed.section",
         Line_Num    => 1,
         Listener    => Test_Case (T).Mock,
         Result      => Result);

      Assert
        (not Result.Success,
         "Malformed section must be rejected (Success = False)");
      Assert
        (Result.Error_Type = Malformed_Section_Header,
         "Error must be Malformed_Section_Header");
   end Test_Process_Line_Malformed_Section;

   procedure Test_Process_Line_Empty_Section_Name
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      State  : Lexer.State := Lexer.Initial_State;
      Result : Lexical_Result;
   begin
      Lexer.Process_Line
        (Lexer_State => State,
         Line        => "[]",
         Line_Num    => 1,
         Listener    => Test_Case (T).Mock,
         Result      => Result);

      Assert
        (not Result.Success,
         "Empty section name must be rejected (Success = False)");
      Assert
        (Result.Error_Type = Malformed_Section_Header,
         "Error must be Malformed_Section_Header for zero-length names");
   end Test_Process_Line_Empty_Section_Name;

   procedure Test_Process_Line_Stray_Bracket
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      State  : Lexer.State := Lexer.Initial_State;
      Result : Lexical_Result;
   begin
      Lexer.Process_Line
        (Lexer_State => State,
         Line        => "]",
         Line_Num    => 1,
         Listener    => Test_Case (T).Mock,
         Result      => Result);

      Assert
        (not Result.Success,
         "Stray closing bracket must be rejected (Success = False)");
      Assert
        (Result.Error_Type = Unrecognized_Statement,
         "Error must be Unrecognized_Statement");
   end Test_Process_Line_Stray_Bracket;

   procedure Test_Process_Line_Unquoted_Value
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      State  : Lexer.State := Lexer.Initial_State;
      Result : Lexical_Result;
   begin
      Lexer.Process_Line
        (Lexer_State => State,
         Line        => "allow_failure = true",
         Line_Num    => 1,
         Listener    => Test_Case (T).Mock,
         Result      => Result);

      Assert
        (not Result.Success,
         "Unquoted value (e.g. boolean) must be rejected "
         & "per dialect constraints");
      Assert
        (Result.Error_Type = Unsupported_Value_Type,
         "Error must be Unsupported_Value_Type");
   end Test_Process_Line_Unquoted_Value;

   procedure Test_Process_Line_Nested_Array
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      State  : Lexer.State := Lexer.Initial_State;
      Result : Lexical_Result;
   begin
      --  Assuming Lexer has been put into Array Mode
      --  (or evaluates nested bracket instantly)
      --  We simulate a nested array declaration `matrix = [["x"]]`
      Lexer.Process_Line
        (Lexer_State => State,
         Line        => "matrix = [[",
         Line_Num    => 1,
         Listener    => Test_Case (T).Mock,
         Result      => Result);

      Assert
        (not Result.Success,
         "Nested arrays must be rejected per PLAT-013 dialect rules");
      Assert
        (Result.Error_Type = Unsupported_Value_Type,
         "Error must be Unsupported_Value_Type");
   end Test_Process_Line_Nested_Array;

   procedure Test_Process_Line_Missing_Equal_Sign
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      State  : Lexer.State := Lexer.Initial_State;
      Result : Lexical_Result;
   begin
      Lexer.Process_Line
        (Lexer_State => State,
         Line        => "cmd ""build""",
         Line_Num    => 1,
         Listener    => Test_Case (T).Mock,
         Result      => Result);

      Assert
        (not Result.Success,
         "Key-value pairs without an equal sign must fail fast");
      Assert
        (Result.Error_Type = Unrecognized_Statement,
         "Error must be Unrecognized_Statement");
   end Test_Process_Line_Missing_Equal_Sign;

   -------------------------------------------------------------------------
   --  3. Finish tests
   -------------------------------------------------------------------------

   procedure Test_Finish_Clean_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      State  : constant Lexer.State := Lexer.Initial_State;
      Result : Lexical_Result;
   begin
      Lexer.Finish
        (Lexer_State => State,
         Listener    => Test_Case (T).Mock,
         Result      => Result);

      Assert
        (Result.Success, "Finish on a clean state must return Success = True");
      Assert
        (Test_Case (T).Mock.EOF_Reached_Count = 1,
         "Exactly one On_End_Of_File event should be triggered");
   end Test_Finish_Clean_State;

   procedure Test_Finish_Unclosed_Array
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      State  : Lexer.State := Lexer.Initial_State;
      Result : Lexical_Result;
   begin
      --  Force the lexer into an unclosed array state
      Lexer.Process_Line
        (Lexer_State => State,
         Line        => "deps = [",
         Line_Num    => 1,
         Listener    => Test_Case (T).Mock,
         Result      => Result);

      --  Now simulate the end of file
      Lexer.Finish
        (Lexer_State => State,
         Listener    => Test_Case (T).Mock,
         Result      => Result);

      Assert
        (not Result.Success,
         "Finish must fail if the array was left unclosed");
      Assert
        (Result.Error_Type = Unclosed_Array, "Error must be Unclosed_Array");
      Assert
        (Test_Case (T).Mock.EOF_Reached_Count = 0,
         "On_End_Of_File must not be triggered when an error occurs");
   end Test_Finish_Unclosed_Array;

   -------------------------------------------------------------------------
   --  4. Complex Integration Tests
   -------------------------------------------------------------------------

   procedure Test_Complex_Document_Parsing
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      State  : Lexer.State := Lexer.Initial_State;
      Result : Lexical_Result;
   begin
      --  Simulate a real-world multi-line TOML document
      Lexer.Process_Line
        (State, "[project.meta]", 1, Test_Case (T).Mock, Result);
      Assert (Result.Success, "Line 1 failed");

      Lexer.Process_Line
        (State, "name = ""makeops""", 2, Test_Case (T).Mock, Result);
      Assert (Result.Success, "Line 2 failed");

      Lexer.Process_Line (State, "tags = [", 3, Test_Case (T).Mock, Result);
      Assert (Result.Success, "Line 3 failed");

      Lexer.Process_Line (State, "   ""ada"",", 4, Test_Case (T).Mock, Result);
      Assert (Result.Success, "Line 4 failed");

      Lexer.Process_Line
        (State, "   ""spark""", 5, Test_Case (T).Mock, Result);
      Assert (Result.Success, "Line 5 failed");

      Lexer.Process_Line (State, "]", 6, Test_Case (T).Mock, Result);
      Assert (Result.Success, "Line 6 failed");

      Lexer.Process_Line
        (State, "version = ""1.0""", 7, Test_Case (T).Mock, Result);
      Assert (Result.Success, "Line 7 failed");

      Lexer.Finish (State, Test_Case (T).Mock, Result);
      Assert (Result.Success, "Finish failed");

      --  Verify the exact sequence and counts of events
      Assert
        (Test_Case (T).Mock.Section_Found_Count = 1, "Expected 1 section");
      Assert
        (Test_Case (T).Mock.String_Value_Found_Count = 2,
         "Expected 2 standard values");
      Assert
        (Test_Case (T).Mock.Array_Start_Count = 1, "Expected 1 array start");
      Assert
        (Test_Case (T).Mock.Array_Item_Count = 2, "Expected 2 array items");
      Assert (Test_Case (T).Mock.Array_End_Count = 1, "Expected 1 array end");
      Assert
        (Test_Case (T).Mock.EOF_Reached_Count = 1,
         "Expected EOF to be reached");

      --  Verify exact values of the last events
      Assert
        (Test_Case (T).Mock.Last_Key = "version",
         "Last key should be 'version'");
      Assert
        (Test_Case (T).Mock.Last_String_Value = "1.0",
         "Last string value should be '1.0'");
   end Test_Complex_Document_Parsing;

   procedure Test_Whitespace_And_Comment_Stress
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      State  : Lexer.State := Lexer.Initial_State;
      Result : Lexical_Result;
   begin
      --  Test heavy usage of tabs (ASCII.HT) and spaces around tokens
      declare
         Tab : constant Character := ASCII.HT;
      begin
         Lexer.Process_Line
           (State,
            Tab & " [spaced.section] " & Tab & "# comment",
            1,
            Test_Case (T).Mock,
            Result);
         Assert (Result.Success, "Spaced section failed");
         Assert
           (Test_Case (T).Mock.Last_Section_Name = "spaced.section",
            "Trimmed section name incorrect");

         Lexer.Process_Line
           (State,
            Tab & "key" & Tab & "=" & Tab & """value""" & " # c",
            2,
            Test_Case (T).Mock,
            Result);
         Assert (Result.Success, "Spaced key-value failed");
         Assert (Test_Case (T).Mock.Last_Key = "key", "Trimmed key incorrect");
         Assert
           (Test_Case (T).Mock.Last_String_Value = "value",
            "Trimmed value incorrect");

         Lexer.Process_Line
           (State,
            "arr = [" & Tab & """item""" & Tab & "]" & Tab,
            3,
            Test_Case (T).Mock,
            Result);
         Assert (Result.Success, "Spaced inline array failed");
         Assert
           (Test_Case (T).Mock.Array_Item_Count = 1, "Expected 1 array item");
      end;
   end Test_Whitespace_And_Comment_Stress;

   procedure Test_State_Transition_Errors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      State  : Lexer.State := Lexer.Initial_State;
      Result : Lexical_Result;
   begin
      --  Test 1: Garbage after an inline array closes
      Lexer.Process_Line
        (State, "deps = [] garbage", 1, Test_Case (T).Mock, Result);
      Assert (not Result.Success, "Garbage after array should fail");
      Assert
        (Result.Error_Type = Unrecognized_Statement,
         "Error should be Unrecognized_Statement");

      --  Test 2: Garbage after a standard string
      State := Lexer.Initial_State;
      Lexer.Process_Line
        (State, "cmd = ""gcc"" oops", 1, Test_Case (T).Mock, Result);
      Assert (not Result.Success, "Garbage after string should fail");

      --  Test 3: Unclosed string spanning to the end of the line
      State := Lexer.Initial_State;
      Lexer.Process_Line
        (State, "cmd = ""unclosed", 1, Test_Case (T).Mock, Result);
      Assert (not Result.Success, "Unclosed string should fail at EOL");
   end Test_State_Transition_Errors;

end MakeOps.Tests.Core_TOML_Lexer;
