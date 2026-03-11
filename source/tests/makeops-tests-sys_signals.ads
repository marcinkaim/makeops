-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

with AUnit.Test_Cases;

package MakeOps.Tests.Sys_Signals is

   --  Test case encapsulating tests for MakeOps.Sys.Signals
   type Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   procedure Register_Tests (T : in out Test_Case);
   function Name (T : Test_Case) return AUnit.Message_String;

   -------------------------------------------------------------------------
   --  Test Scenarios for MakeOps.Sys.Signals (DES-011)
   -------------------------------------------------------------------------

   procedure Test_Initial_State (T : in out AUnit.Test_Cases.Test_Case'Class);

end MakeOps.Tests.Sys_Signals;
