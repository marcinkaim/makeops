-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

with AUnit.Test_Cases;

package MakeOps.Tests.Base is

   type Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   procedure Register_Tests (T : in out Test_Case);
   function Name (T : Test_Case) return AUnit.Message_String;

   --  Test routines mapped to DES validation strategies
   procedure Test_MakeOps (T : in out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_MakeOps_App (T : in out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_MakeOps_Core (T : in out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_MakeOps_Sys (T : in out AUnit.Test_Cases.Test_Case'Class);

end MakeOps.Tests.Base;
