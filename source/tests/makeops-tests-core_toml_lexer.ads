-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--  MakeOps.Tests.Core_TOML_Lexer
--  Unit tests for the Event-Driven TOML Lexical Analyzer
-------------------------------------------------------------------------------

pragma SPARK_Mode (Off); -- AUnit heavily relies on OOP and access types

with AUnit.Test_Cases;
with Ada.Strings.Unbounded;
with MakeOps.Core.TOML;

package MakeOps.Tests.Core_TOML_Lexer is

   -------------------------------------------------------------------------
   --  Mock Listener Definition
   -------------------------------------------------------------------------

   --  A mock implementation of the Lexer_Listener interface designed to
   --  record incoming events and parameters for later assertion in tests.
   type Mock_Listener is new MakeOps.Core.TOML.Lexer_Listener with record
      --  Individual event counters for precise assertions
      Section_Found_Count      : Natural := 0;
      String_Value_Found_Count : Natural := 0;
      Array_Start_Count        : Natural := 0;
      Array_Item_Count         : Natural := 0;
      Array_End_Count          : Natural := 0;
      EOF_Reached_Count        : Natural := 0;

      --  We use Unbounded_String strictly for testing convenience to store
      --  the Zero-Allocation TOML_Lexeme slices pushed by the Lexer.
      Last_Section_Name : Ada.Strings.Unbounded.Unbounded_String;
      Last_Key          : Ada.Strings.Unbounded.Unbounded_String;
      Last_String_Value : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   --  Listener primitives required by the interface:

   overriding
   procedure On_Section_Found
     (Listener : in out Mock_Listener;
      Name     : MakeOps.Core.TOML.TOML_Lexeme;
      Line     : MakeOps.Core.TOML.Line_Number;
      Column   : MakeOps.Core.TOML.Column_Number);

   overriding
   procedure On_String_Value_Found
     (Listener : in out Mock_Listener;
      Key      : MakeOps.Core.TOML.TOML_Lexeme;
      Value    : MakeOps.Core.TOML.TOML_Lexeme;
      Line     : MakeOps.Core.TOML.Line_Number;
      Column   : MakeOps.Core.TOML.Column_Number);

   overriding
   procedure On_Array_Start
     (Listener : in out Mock_Listener;
      Key      : MakeOps.Core.TOML.TOML_Lexeme;
      Line     : MakeOps.Core.TOML.Line_Number;
      Column   : MakeOps.Core.TOML.Column_Number);

   overriding
   procedure On_Array_Item
     (Listener : in out Mock_Listener;
      Value    : MakeOps.Core.TOML.TOML_Lexeme;
      Line     : MakeOps.Core.TOML.Line_Number;
      Column   : MakeOps.Core.TOML.Column_Number);

   overriding
   procedure On_Array_End
     (Listener : in out Mock_Listener;
      Line     : MakeOps.Core.TOML.Line_Number;
      Column   : MakeOps.Core.TOML.Column_Number);

   overriding
   procedure On_End_Of_File (Listener : in out Mock_Listener);

   --  Helper procedure to reset the mock's state between assertions
   procedure Reset (Listener : in out Mock_Listener);

   -------------------------------------------------------------------------
   --  Test Case Definition
   -------------------------------------------------------------------------

   type Test_Case is new AUnit.Test_Cases.Test_Case with record
      --  State required during tests, e.g., the mock listener instance
      Mock : Mock_Listener;
   end record;

   --  AUnit lifecycle overrides
   overriding
   function Name (T : Test_Case) return AUnit.Message_String;
   overriding
   procedure Register_Tests (T : in out Test_Case);
   overriding
   procedure Set_Up (T : in out Test_Case);

   -------------------------------------------------------------------------
   --  Test Routines (Based on the Test Plan)
   -------------------------------------------------------------------------

   --  1. Initial_State tests
   procedure Test_Initial_State_Independence
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   --  2. Process_Line tests
   --  2a. Happy Paths
   procedure Test_Process_Line_Valid_Section
     (T : in out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_Process_Line_String_Value
     (T : in out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_Process_Line_Single_Line_Array
     (T : in out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_Process_Line_Multi_Line_Array
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   --  2b. Edge & Corner Cases (Happy Paths)
   procedure Test_Process_Line_Inline_Comment
     (T : in out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_Process_Line_Empty_Array
     (T : in out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_Process_Line_Empty_String_Value
     (T : in out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_Sensitive_Chars_In_Strings
     (T : in out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_String_Escaping
     (T : in out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_No_Trailing_Newline_At_EOF
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   --  2c. Error Cases (Fail-Fast)
   procedure Test_Process_Line_Empty_And_Comments
     (T : in out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_Process_Line_Malformed_Section
     (T : in out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_Process_Line_Empty_Section_Name
     (T : in out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_Process_Line_Stray_Bracket
     (T : in out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_Process_Line_Unquoted_Value
     (T : in out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_Process_Line_Nested_Array
     (T : in out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_Process_Line_Missing_Equal_Sign
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   --  3. Finish tests
   procedure Test_Finish_Clean_State
     (T : in out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_Finish_Unclosed_Array
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   --  4. Complex Integration Tests
   procedure Test_Complex_Document_Parsing
     (T : in out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_Whitespace_And_Comment_Stress
     (T : in out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_State_Transition_Errors
     (T : in out AUnit.Test_Cases.Test_Case'Class);

end MakeOps.Tests.Core_TOML_Lexer;
