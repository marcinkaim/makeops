-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

package body MakeOps.Tests is

   use AUnit.Test_Suites;

   -----------
   -- Suite --
   -----------

   function Suite return Access_Test_Suite is
      Result : constant Access_Test_Suite := new Test_Suite;
   begin
      return Result;
   end Suite;

end MakeOps.Tests;