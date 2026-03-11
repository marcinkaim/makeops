-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

with AUnit.Test_Cases;

package MakeOps.Tests.Sys_Env is

   --  Test case encapsulating all tests for MakeOps.Sys.Env
   type Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   procedure Register_Tests (T : in out Test_Case);
   function Name (T : Test_Case) return AUnit.Message_String;

   --  Test Scenarios defined in DES-005
   procedure Test_Get_Existing_Variable
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Get_Non_Existing_Variable
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   --  Edge Cases: Length and Empty values
   procedure Test_Get_Value_Exceeding_Max_Length
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Get_Empty_Value_Variable
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Get_Empty_Name_Variable
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   --  Edge Cases: Case Sensitivity
   procedure Test_Get_Case_Sensitivity
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   --  Corner Cases: Strict Boundaries and Special Characters
   procedure Test_Get_Value_Exact_Max_Length
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Get_Name_Exact_Max_Length
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Get_Name_With_Equal_Sign
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Get_Value_With_Special_Chars
     (T : in out AUnit.Test_Cases.Test_Case'Class);

end MakeOps.Tests.Sys_Env;
