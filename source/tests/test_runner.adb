-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

with AUnit.Reporter.Text;
with AUnit.Run;
with MakeOps.Tests;

procedure Test_Runner is

   procedure Run is new AUnit.Run.Test_Runner (MakeOps.Tests.Suite);

   Reporter : AUnit.Reporter.Text.Text_Reporter;

begin
   AUnit.Reporter.Text.Set_Use_ANSI_Colors (Reporter, True);
   Run (Reporter);
end Test_Runner;