-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

with Ada.Environment_Variables;
with AUnit.Assertions; use AUnit.Assertions;
with MakeOps.Sys.Env;  use MakeOps.Sys.Env;

package body MakeOps.Tests.Sys_Env is

   ----------
   -- Name --
   ----------

   function Name (T : Test_Case) return AUnit.Message_String is
   begin
      return AUnit.Format ("DES-005: MakeOps.Sys.Env Tests");
   end Name;

   --------------------
   -- Register_Tests --
   --------------------

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Test_Get_Existing_Variable'Access,
         "Happy Path: Fetch an existing standard OS variable");
      Register_Routine
        (T,
         Test_Get_Non_Existing_Variable'Access,
         "Edge Case: Fetch a non-existing variable (Exception Isolation)");
      Register_Routine
        (T,
         Test_Get_Value_Exceeding_Max_Length'Access,
         "Edge Case: Exceeding Max_Env_Var_Value_Length limits");
      Register_Routine
        (T,
         Test_Get_Empty_Value_Variable'Access,
         "Edge Case: Fetch variable with an empty value");
      Register_Routine
        (T,
         Test_Get_Empty_Name_Variable'Access,
         "Edge Case: Fetch variable using an empty name string");
      Register_Routine
        (T,
         Test_Get_Case_Sensitivity'Access,
         "Edge Case: Case-sensitive name resolution");

      Register_Routine
        (T,
         Test_Get_Value_Exact_Max_Length'Access,
         "Corner Case: Fetch value of exactly "
         & "Max_Env_Var_Value_Length limits");

      Register_Routine
        (T,
         Test_Get_Name_Exact_Max_Length'Access,
         "Corner Case: Fetch variable with name of exactly "
         & "Max_Env_Var_Name_Length");

      Register_Routine
        (T,
         Test_Get_Name_With_Equal_Sign'Access,
         "Corner Case: Fetch variable with equal sign in name");

      Register_Routine
        (T,
         Test_Get_Value_With_Special_Chars'Access,
         "Corner Case: Fetch value containing special/UTF-8 characters");
   end Register_Tests;

   --------------------------------
   -- Test_Get_Existing_Variable --
   --------------------------------

   procedure Test_Get_Existing_Variable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      --  We use PATH as it is practically guaranteed to exist on any
      --  Linux/POSIX system
      Target_Name : constant Env_Name_String :=
        Env_Name_Strings.To_Bounded_String ("PATH");
      Result      : constant Env_Result := Get (Target_Name);
   begin
      --  Assert that the OS adapter found the variable
      Assert
        (Result.Status = Found,
         "Standard PATH variable should be found by the OS adapter");

      --  Assert that the returned bounded string actually contains data
      Assert
        (Env_Value_Strings.Length (Result.Value) > 0,
         "PATH variable value should not be empty");
   end Test_Get_Existing_Variable;

   ------------------------------------
   -- Test_Get_Non_Existing_Variable --
   ------------------------------------

   procedure Test_Get_Non_Existing_Variable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      --  A deliberately fabricated variable name that should not exist
      Target_Name : constant Env_Name_String :=
        Env_Name_Strings.To_Bounded_String ("MKO_NON_EXISTENT_VAR_123");
      Result      : constant Env_Result := Get (Target_Name);
   begin
      --  Assert that the adapter gracefully degraded to Not_Found
      --  instead of propagating Ada.Environment_Variables.Constraint_Error
      Assert
        (Result.Status = Not_Found,
         "Non-existent variable should deterministically "
         & "return Not_Found status");
   end Test_Get_Non_Existing_Variable;

   -----------------------------------------
   -- Test_Get_Value_Exceeding_Max_Length --
   -----------------------------------------

   procedure Test_Get_Value_Exceeding_Max_Length
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Var_Name       : constant String := "MKO_TEST_MAX_LEN";
      --  Create a string exceeding Max_Env_Var_Value_Length by 1 character
      Too_Long_Value : constant String (1 .. Max_Env_Var_Value_Length + 1) :=
        [others => 'A'];
      Target_Name    : constant Env_Name_String :=
        Env_Name_Strings.To_Bounded_String (Var_Name);
      Result         : Env_Result;
   begin
      --  Setup: Set environment variable directly via OS bindings
      Ada.Environment_Variables.Set (Var_Name, Too_Long_Value);

      --  Test
      Result := Get (Target_Name);

      --  Assert: Should return Too_Long state instead of Not_Found
      --  to support Fail-Fast mechanism.
      Assert
        (Result.Status = Too_Long,
         "Variable exceeding max length should "
         & "deterministically return Too_Long (Fail-Fast)");

      --  Teardown
      Ada.Environment_Variables.Clear (Var_Name);
   end Test_Get_Value_Exceeding_Max_Length;

   -----------------------------------
   -- Test_Get_Empty_Value_Variable --
   -----------------------------------

   procedure Test_Get_Empty_Value_Variable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Var_Name    : constant String := "MKO_TEST_EMPTY_VAL";
      Target_Name : constant Env_Name_String :=
        Env_Name_Strings.To_Bounded_String (Var_Name);
      Result      : Env_Result;
   begin
      --  Setup: Export variable with an empty string
      Ada.Environment_Variables.Set (Var_Name, "");

      --  Test
      Result := Get (Target_Name);

      --  Assert: The variable exists, its length should be exactly 0
      Assert
        (Result.Status = Found, "Variable with empty value should be Found");
      Assert
        (Env_Value_Strings.Length (Result.Value) = 0,
         "Variable value length should be exactly 0");

      --  Teardown
      Ada.Environment_Variables.Clear (Var_Name);
   end Test_Get_Empty_Value_Variable;

   ----------------------------------
   -- Test_Get_Empty_Name_Variable --
   ----------------------------------

   procedure Test_Get_Empty_Name_Variable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Target_Name : constant Env_Name_String :=
        Env_Name_Strings.Null_Bounded_String;
      Result      : constant Env_Result := Get (Target_Name);
   begin
      --  Assert: Querying empty string should gracefully degrade
      Assert
        (Result.Status = Not_Found,
         "Querying with empty name should gracefully return Not_Found");
   end Test_Get_Empty_Name_Variable;

   -------------------------------
   -- Test_Get_Case_Sensitivity --
   -------------------------------

   procedure Test_Get_Case_Sensitivity
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Var_Name_Upper    : constant String := "MKO_TEST_CASE";
      Var_Name_Lower    : constant String := "mko_test_case";
      Target_Name_Lower : constant Env_Name_String :=
        Env_Name_Strings.To_Bounded_String (Var_Name_Lower);
      Result            : Env_Result;
   begin
      --  Setup: export variable in UPPERCASE
      Ada.Environment_Variables.Set (Var_Name_Upper, "SOME_VALUE");

      --  Test: fetch using lowercase key
      Result := Get (Target_Name_Lower);

      --  Assert
      Assert
        (Result.Status = Not_Found,
         "Environment variables should be case-sensitive, "
         & "returning Not_Found for lowercase key");

      --  Teardown
      Ada.Environment_Variables.Clear (Var_Name_Upper);
   end Test_Get_Case_Sensitivity;

   -------------------------------------
   -- Test_Get_Value_Exact_Max_Length --
   -------------------------------------

   procedure Test_Get_Value_Exact_Max_Length
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Var_Name    : constant String := "MKO_TEST_EXACT_MAX_VAL";
      --  Create a string of exactly Max_Env_Var_Value_Length characters
      Exact_Value : constant String (1 .. Max_Env_Var_Value_Length) :=
        [others => 'B'];
      Target_Name : constant Env_Name_String :=
        Env_Name_Strings.To_Bounded_String (Var_Name);
      Result      : Env_Result;
   begin
      --  Setup
      Ada.Environment_Variables.Set (Var_Name, Exact_Value);

      --  Test
      Result := Get (Target_Name);

      --  Assert: Should be Found and length should exactly match the limit
      Assert
        (Result.Status = Found,
         "Variable with exact max value length should be Found");
      Assert
        (Env_Value_Strings.Length (Result.Value) = Max_Env_Var_Value_Length,
         "Returned value should have exactly max length");

      --  Teardown
      Ada.Environment_Variables.Clear (Var_Name);
   end Test_Get_Value_Exact_Max_Length;

   ------------------------------------
   -- Test_Get_Name_Exact_Max_Length --
   ------------------------------------

   procedure Test_Get_Name_Exact_Max_Length
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      --  Create a string of exactly 64 characters
      Var_Name    : constant String (1 .. Max_Env_Var_Name_Length) :=
        [others => 'C'];
      Target_Name : constant Env_Name_String :=
        Env_Name_Strings.To_Bounded_String (Var_Name);
      Result      : Env_Result;
   begin
      --  Setup
      Ada.Environment_Variables.Set (Var_Name, "VALID_DATA");

      --  Test
      Result := Get (Target_Name);

      --  Assert
      Assert
        (Result.Status = Found,
         "Variable with exact max name length should be Found");
      Assert
        (Env_Value_Strings.To_String (Result.Value) = "VALID_DATA",
         "Returned value for exact max length name is incorrect");

      --  Teardown
      Ada.Environment_Variables.Clear (Var_Name);
   end Test_Get_Name_Exact_Max_Length;

   -----------------------------------
   -- Test_Get_Name_With_Equal_Sign --
   -----------------------------------

   procedure Test_Get_Name_With_Equal_Sign
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Var_Name    : constant String := "MKO=INVALID_NAME";
      Target_Name : constant Env_Name_String :=
        Env_Name_Strings.To_Bounded_String (Var_Name);
      Result      : Env_Result;
   begin
      --  Test: We do not attempt to Set this variable via Ada bindings, as it
      --  may raise an exception or behave unpredictably on the OS level.
      --  We simply query it.
      Result := Get (Target_Name);

      --  Assert
      Assert
        (Result.Status = Not_Found,
         "Querying variable with equal sign in name should gracefully "
         & "return Not_Found");
   end Test_Get_Name_With_Equal_Sign;

   ---------------------------------------
   -- Test_Get_Value_With_Special_Chars --
   ---------------------------------------

   procedure Test_Get_Value_With_Special_Chars
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Var_Name      : constant String := "MKO_TEST_SPECIAL_CHARS";
      --  Value with Newline (LF), Tab (HT),
      --  Polish Diacritics and Emoji (UTF-8)
      Special_Value : constant String :=
        "Line1"
        & Character'Val (10)
        & "Line2"
        & Character'Val (9)
        & "Zażółć 🚀";
      Target_Name   : constant Env_Name_String :=
        Env_Name_Strings.To_Bounded_String (Var_Name);
      Result        : Env_Result;
   begin
      --  Setup
      Ada.Environment_Variables.Set (Var_Name, Special_Value);

      --  Test
      Result := Get (Target_Name);

      --  Assert
      Assert
        (Result.Status = Found,
         "Variable with special characters should be Found");
      Assert
        (Env_Value_Strings.To_String (Result.Value) = Special_Value,
         "Special characters and UTF-8 bytes should remain intact");

      --  Teardown
      Ada.Environment_Variables.Clear (Var_Name);
   end Test_Get_Value_With_Special_Chars;

end MakeOps.Tests.Sys_Env;
