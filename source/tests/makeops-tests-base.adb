-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

with AUnit.Assertions; use AUnit.Assertions;
with MakeOps.App; use MakeOps.App;
with MakeOps.Core; use MakeOps.Core;
with MakeOps.Sys; use MakeOps.Sys;

package body MakeOps.Tests.Base is

   pragma Warnings (Off, "-gnatwc"); -- Suppress warnings for static conditions

   function Name (T : Test_Case) return AUnit.Message_String is
   begin
      return AUnit.Format ("Base Packages (Cluster 0) Tests");
   end Name;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (
         T,
         Test_MakeOps'Access,
         "SPEC-000: MakeOps Identity constraints");
      Register_Routine (
         T,
         Test_MakeOps_App'Access,
         "SPEC-001: App Exit Codes and Log Levels");
      Register_Routine (
         T,
         Test_MakeOps_Core'Access,
         "SPEC-002: Core Types Sanity");
      Register_Routine (
         T,
         Test_MakeOps_Sys'Access,
         "SPEC-003: Sys Error Code Bounds");
   end Register_Tests;

   procedure Test_MakeOps (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (MakeOps.Version'Length > 0, "MakeOps.Version cannot be empty");
      Assert (MakeOps.Name = "MakeOps", "MakeOps.Name must be correct");
   end Test_MakeOps;

   procedure Test_MakeOps_App (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (
         MakeOps.App.Error < MakeOps.App.Info,
         "Error level must be less than Info level");
      Assert (
         MakeOps.App.Info < MakeOps.App.Debug,
         "Info level must be less than Debug level");
   end Test_MakeOps_App;

   procedure Test_MakeOps_Core (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (
         MakeOps.Core.Success /= MakeOps.Core.Failure,
         "Result states must be distinct");
   end Test_MakeOps_Core;

   procedure Test_MakeOps_Sys (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Dummy_Code : MakeOps.Sys.System_Error_Code;
   begin
      Dummy_Code := 1;

      --  Should hold positive POSIX errno like EPERM (1)
      Assert (
         Dummy_Code > 0,
         "System_Error_Code can hold positive integer bounds");

      --  POSIX Exit Codes mapped in Sys layer
      Assert (
         MakeOps.Sys.Exit_Success = 0,
         "Exit_Success must strictly be 0 (POSIX)");
      Assert (
         MakeOps.Sys.Exit_Failure /= 0,
         "Exit_Failure must indicate an error");
   end Test_MakeOps_Sys;

end MakeOps.Tests.Base;