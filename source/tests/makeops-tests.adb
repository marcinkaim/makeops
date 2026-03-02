-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

with MakeOps.Tests.Base;

package body MakeOps.Tests is

   use AUnit.Test_Suites;

   --  Statically instantiate test cases to avoid dynamic allocation
   Base_Tests : aliased MakeOps.Tests.Base.Test_Case;

   -----------
   -- Suite --
   -----------

   function Suite return Access_Test_Suite is
      Result : constant Access_Test_Suite := new Test_Suite;
   begin
      Result.Add_Test (Base_Tests'Access);
      return Result;
   end Suite;

end MakeOps.Tests;