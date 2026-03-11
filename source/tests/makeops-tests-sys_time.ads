-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

with AUnit.Test_Cases;

package MakeOps.Tests.Sys_Time is

   --  Test case encapsulating tests for MakeOps.Sys.Time
   type Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   procedure Register_Tests (T : in out Test_Case);
   function Name (T : Test_Case) return AUnit.Message_String;

   -------------------------------------------------------------------------
   --  Test Scenarios for MakeOps.Sys.Time (DES-014)
   -------------------------------------------------------------------------

   --  1. Tests for 'Clock'
   procedure Test_Clock_Monotonicity
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Clock_Stability_Polling
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   --  2. Tests for 'Elapsed_Time'
   procedure Test_Elapsed_Time_Standard
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Elapsed_Time_Inverted
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   --  3. Tests for 'Add_Milliseconds'
   procedure Test_Add_Milliseconds_Forward
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Add_Milliseconds_Negative
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   --  4. Tests for 'Is_Past'
   procedure Test_Is_Past_Future_Deadline
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Is_Past_Expired_Deadline
     (T : in out AUnit.Test_Cases.Test_Case'Class);

end MakeOps.Tests.Sys_Time;
