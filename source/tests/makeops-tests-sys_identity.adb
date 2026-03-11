-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

with AUnit.Assertions; use AUnit.Assertions;
with MakeOps.Sys.Identity;

package body MakeOps.Tests.Sys_Identity is

   ----------
   -- Name --
   ----------

   function Name (T : Test_Case) return AUnit.Message_String is
   begin
      return AUnit.Format ("DES-012: MakeOps.Sys.Identity Tests");
   end Name;

   --------------------
   -- Register_Tests --
   --------------------

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Test_Sanity_Check_Execution'Access,
         "Sanity Check: Is_Root_User executes without exceptions");
   end Register_Tests;

   ---------------------------------
   -- Test_Sanity_Check_Execution --
   ---------------------------------

   procedure Test_Sanity_Check_Execution
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : Boolean;
   begin
      --  According to DES-012, we cannot assert whether the result is True
      --  or False because the test runner might be executed as root in CI.
      --  The goal of this test is merely to verify that the C ABI boundary
      --  does not crash (Absence of Runtime Errors).
      Result := MakeOps.Sys.Identity.Is_Root_User;

      pragma Unreferenced (Result);

      --  If we reached this line without raising PROGRAM_ERROR or SIGSEGV,
      --  the thin C binding and the thick Ada wrapper worked safely.
      Assert (True, "Is_Root_User executed successfully across C ABI.");
   end Test_Sanity_Check_Execution;

end MakeOps.Tests.Sys_Identity;
