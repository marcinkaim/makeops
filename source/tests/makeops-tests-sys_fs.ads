-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

with AUnit.Test_Cases;

package MakeOps.Tests.Sys_FS is

   --  Test case encapsulating all tests for MakeOps.Sys.FS
   type Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   procedure Register_Tests (T : in out Test_Case);
   function Name (T : Test_Case) return AUnit.Message_String;

   -------------------------------------------------------------------------
   --  Test Scenarios for MakeOps.Sys.FS
   -------------------------------------------------------------------------

   --  Check_File_Access tests
   procedure Test_Check_File_Access_Existing
     (T : in out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_Check_File_Access_Missing
     (T : in out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_Check_File_Access_Permission_Denied
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   --  Is_Executable tests
   procedure Test_Is_Executable_Valid
     (T : in out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_Is_Executable_Missing_Permissions
     (T : in out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_Is_Executable_Missing_File
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   --  Change_Directory tests
   procedure Test_Change_Directory_Success
     (T : in out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_Change_Directory_Missing
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   --  Get_Current_Directory tests
   procedure Test_Get_Current_Directory_Valid
     (T : in out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_Get_Current_Directory_Integration
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   --  Get_Absolute_Directory_Path tests
   procedure Test_Get_Absolute_Directory_Path_Valid
     (T : in out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_Get_Absolute_Directory_Path_Missing
     (T : in out AUnit.Test_Cases.Test_Case'Class);

end MakeOps.Tests.Sys_FS;
