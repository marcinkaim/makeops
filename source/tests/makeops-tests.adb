-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

with MakeOps.Tests.Base;
with MakeOps.Tests.Sys_Env;
with MakeOps.Tests.Sys_FS;
with MakeOps.Tests.Sys_Processes;
with MakeOps.Tests.Sys_Terminal;
with MakeOps.Tests.Sys_Signals;
with MakeOps.Tests.Sys_Identity;
with MakeOps.Tests.Sys_Time;
with MakeOps.Tests.Sys_File_Stream;
with MakeOps.Tests.Core_TOML_Lexer;

package body MakeOps.Tests is

   use AUnit.Test_Suites;

   --  Statically instantiate test cases to avoid dynamic allocation
   Base_Tests            : aliased MakeOps.Tests.Base.Test_Case;
   Sys_Env_Tests         : aliased MakeOps.Tests.Sys_Env.Test_Case;
   Sys_FS_Tests          : aliased MakeOps.Tests.Sys_FS.Test_Case;
   Sys_Processes_Tests   : aliased MakeOps.Tests.Sys_Processes.Test_Case;
   Sys_Terminal_Tests    : aliased MakeOps.Tests.Sys_Terminal.Test_Case;
   Sys_Signals_Tests     : aliased MakeOps.Tests.Sys_Signals.Test_Case;
   Sys_Identity_Tests    : aliased MakeOps.Tests.Sys_Identity.Test_Case;
   Sys_Time_Tests        : aliased MakeOps.Tests.Sys_Time.Test_Case;
   Sys_File_Stream_Tests : aliased MakeOps.Tests.Sys_File_Stream.Test_Case;
   Core_TOML_Lexer_Tests : aliased MakeOps.Tests.Core_TOML_Lexer.Test_Case;

   -----------
   -- Suite --
   -----------

   function Suite return Access_Test_Suite is
      Result : constant Access_Test_Suite := new Test_Suite;
   begin
      Result.Add_Test (Base_Tests'Access);
      Result.Add_Test (Sys_Env_Tests'Access);
      Result.Add_Test (Sys_FS_Tests'Access);
      Result.Add_Test (Sys_Processes_Tests'Access);
      Result.Add_Test (Sys_Terminal_Tests'Access);
      Result.Add_Test (Sys_Signals_Tests'Access);
      Result.Add_Test (Sys_Identity_Tests'Access);
      Result.Add_Test (Sys_Time_Tests'Access);
      Result.Add_Test (Sys_File_Stream_Tests'Access);
      Result.Add_Test (Core_TOML_Lexer_Tests'Access);
      return Result;
   end Suite;

end MakeOps.Tests;
