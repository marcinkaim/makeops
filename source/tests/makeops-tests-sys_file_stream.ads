-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

with AUnit.Test_Cases;

package MakeOps.Tests.Sys_File_Stream is

   --  Test case encapsulating tests for MakeOps.Sys.File_Stream
   type Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   procedure Register_Tests (T : in out Test_Case);
   function Name (T : Test_Case) return AUnit.Message_String;

   -------------------------------------------------------------------------
   --  Test Scenarios for MakeOps.Sys.File_Stream (DES-015)
   -------------------------------------------------------------------------

   --  1. Tests for 'Open_File'
   procedure Test_Open_Existing_File
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Open_Nonexistent_File
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Open_Use_Error (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Open_Status_Error
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   --  2. Tests for 'Get_Next_Line'
   procedure Test_Get_Next_Line_Standard
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Get_Next_Line_Empty_EOF
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Get_Next_Line_Unopened
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Get_Next_Line_Truncation
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Get_Next_Line_Exact_Boundary
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Get_Next_Line_Blank_Lines
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Get_Next_Line_No_Trailing_Newline
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Get_Next_Line_Consecutive_EOF
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Get_Next_Line_Exact_Boundary_No_Newline
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Get_Next_Line_Null_Bytes
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   --  3. Tests for 'Close_File'
   procedure Test_Close_Open_File
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Close_Closed_File
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   --  4. POSIX/OS Edge Cases
   procedure Test_Open_Directory (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Open_No_Permission
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Read_Device_File
     (T : in out AUnit.Test_Cases.Test_Case'Class);

end MakeOps.Tests.Sys_File_Stream;
