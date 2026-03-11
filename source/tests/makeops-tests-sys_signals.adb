-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

with AUnit.Assertions;    use AUnit.Assertions;
with MakeOps.Sys.Signals; use MakeOps.Sys.Signals;

package body MakeOps.Tests.Sys_Signals is

   ----------
   -- Name --
   ----------

   function Name (T : Test_Case) return AUnit.Message_String is
   begin
      return AUnit.Format ("DES-011: MakeOps.Sys.Signals Tests");
   end Name;

   --------------------
   -- Register_Tests --
   --------------------

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Test_Initial_State'Access,
         "Sanity Check: Initial Abort_Requested state is False");
   end Register_Tests;

   ------------------------
   -- Test_Initial_State --
   ------------------------

   procedure Test_Initial_State (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      --  Verify that under normal, uninterrupted execution,
      --  the signals facade defaults to False.
      --  Testing actual SIGINT routing is deferred to E2E integration tests
      --  to prevent the AUnit test runner from being killed by the OS.
      Assert
        (Abort_Requested = False,
         "Abort_Requested MUST initially return False "
         & "to prevent premature execution halts.");
   end Test_Initial_State;

end MakeOps.Tests.Sys_Signals;
