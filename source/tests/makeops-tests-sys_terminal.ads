-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

with Ada.Text_IO;
with AUnit.Test_Cases;

package MakeOps.Tests.Sys_Terminal is

   --  Test case encapsulating all tests for MakeOps.Sys.Terminal.
   --  Contains file handles for temporary output redirection.
   type Test_Case is new AUnit.Test_Cases.Test_Case with record
      Temp_Out : Ada.Text_IO.File_Type;
      Temp_Err : Ada.Text_IO.File_Type;
   end record;

   procedure Register_Tests (T : in out Test_Case);
   procedure Set_Up (T : in out Test_Case);
   procedure Tear_Down (T : in out Test_Case);

   function Name (T : Test_Case) return AUnit.Message_String;

   -------------------------------------------------------------------------
   --  Test Scenarios for MakeOps.Sys.Terminal (DES-010)
   -------------------------------------------------------------------------

   --  Print tests
   procedure Test_Print_Valid_Strings
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Print_Empty_And_Control_Chars
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   --  Print_Line tests
   procedure Test_Print_Line_Valid_Strings
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Print_Line_Empty_String
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   --  Corner Cases: UTF-8, Massive I/O, Multiline
   procedure Test_Print_UTF8_And_Emoji
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Print_Massive_String
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Print_Multiline_Strings
     (T : in out AUnit.Test_Cases.Test_Case'Class);

end MakeOps.Tests.Sys_Terminal;
