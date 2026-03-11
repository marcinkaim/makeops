-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

with AUnit.Assertions;     use AUnit.Assertions;
with MakeOps.Sys.Terminal; use MakeOps.Sys.Terminal;

package body MakeOps.Tests.Sys_Terminal is

   ------------
   -- Set_Up --
   ------------

   procedure Set_Up (T : in out Test_Case) is
   begin
      --  Create nameless temporary files (automatically deleted when closed)
      Ada.Text_IO.Create (T.Temp_Out, Ada.Text_IO.Out_File);
      Ada.Text_IO.Create (T.Temp_Err, Ada.Text_IO.Out_File);

      --  Redirect current output and error to the temporary files
      Ada.Text_IO.Set_Output (T.Temp_Out);
      Ada.Text_IO.Set_Error (T.Temp_Err);
   end Set_Up;

   ---------------
   -- Tear_Down --
   ---------------

   procedure Tear_Down (T : in out Test_Case) is
   begin
      --  Restore standard streams
      Ada.Text_IO.Set_Output (Ada.Text_IO.Standard_Output);
      Ada.Text_IO.Set_Error (Ada.Text_IO.Standard_Error);

      --  Close and automatically delete temporary files
      if Ada.Text_IO.Is_Open (T.Temp_Out) then
         Ada.Text_IO.Close (T.Temp_Out);
      end if;
      if Ada.Text_IO.Is_Open (T.Temp_Err) then
         Ada.Text_IO.Close (T.Temp_Err);
      end if;
   end Tear_Down;

   ----------
   -- Name --
   ----------

   function Name (T : Test_Case) return AUnit.Message_String is
   begin
      return AUnit.Format ("DES-010: MakeOps.Sys.Terminal Tests");
   end Name;

   --------------------
   -- Register_Tests --
   --------------------

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Test_Print_Valid_Strings'Access,
         "Print: Happy Path (Valid Strings)");

      Register_Routine
        (T,
         Test_Print_Empty_And_Control_Chars'Access,
         "Print: Edge Case (Empty and Control Characters)");

      Register_Routine
        (T,
         Test_Print_Line_Valid_Strings'Access,
         "Print_Line: Happy Path (Valid Strings)");

      Register_Routine
        (T,
         Test_Print_Line_Empty_String'Access,
         "Print_Line: Edge Case (Empty String)");

      Register_Routine
        (T,
         Test_Print_UTF8_And_Emoji'Access,
         "Corner Case: UTF-8 Characters and Emoji");

      Register_Routine
        (T,
         Test_Print_Massive_String'Access,
         "Corner Case: Massive Output (Buffer limits)");

      Register_Routine
        (T,
         Test_Print_Multiline_Strings'Access,
         "Corner Case: Strings containing explicit Newlines");
   end Register_Tests;

   ------------------------------
   -- Test_Print_Valid_Strings --
   ------------------------------

   procedure Test_Print_Valid_Strings
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      --  We execute the print statements. The primary assertion here is
      --  that no exception propagates to the test runner (AoRE guarantee).
      Print ("[Test_Print] stdout works.", Standard_Output);
      Print ("[Test_Print] stderr works.", Standard_Error);

      --  If we reach this point, the routines did not crash.
      Assert (True, "Print routines executed without raising exceptions");
   end Test_Print_Valid_Strings;

   ----------------------------------------
   -- Test_Print_Empty_And_Control_Chars --
   ----------------------------------------

   procedure Test_Print_Empty_And_Control_Chars
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Control_Str : constant String := [1 => ASCII.NUL, 2 => ASCII.CR];
   begin
      --  Test with completely empty string
      Print ("", Standard_Output);

      --  Test with non-printable control characters
      Print (Control_Str, Standard_Error);

      Assert (True, "Print handled empty and control strings gracefully");
   end Test_Print_Empty_And_Control_Chars;

   -----------------------------------
   -- Test_Print_Line_Valid_Strings --
   -----------------------------------

   procedure Test_Print_Line_Valid_Strings
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Print_Line ("[Test_Print_Line] stdout works.", Standard_Output);
      Print_Line ("[Test_Print_Line] stderr works.", Standard_Error);

      Assert (True, "Print_Line routines executed without raising exceptions");
   end Test_Print_Line_Valid_Strings;

   ----------------------------------
   -- Test_Print_Line_Empty_String --
   ----------------------------------

   procedure Test_Print_Line_Empty_String
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      --  Printing an empty line should merely output a newline character
      --  without failing inside the Text_IO buffer logic.
      Print_Line ("", Standard_Output);
      Print_Line ("", Standard_Error);

      Assert (True, "Print_Line handled empty strings gracefully");
   end Test_Print_Line_Empty_String;

   -------------------------------
   -- Test_Print_UTF8_And_Emoji --
   -------------------------------

   procedure Test_Print_UTF8_And_Emoji
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      --  String with Polish diacritics and 4-byte Emoji
      UTF8_Str : constant String := "Zażółć gęślą jaźń 🚀✨";
   begin
      Print (UTF8_Str, Standard_Output);
      Print_Line (UTF8_Str, Standard_Error);

      Assert (True, "UTF-8 and Emoji characters printed without exceptions");
   end Test_Print_UTF8_And_Emoji;

   -------------------------------
   -- Test_Print_Massive_String --
   -------------------------------

   procedure Test_Print_Massive_String
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      --  Allocate a 100,000 character string to test Text_IO buffer boundaries
      Massive_Str : constant String (1 .. 100_000) := [others => 'M'];
   begin
      Print (Massive_Str, Standard_Output);
      Print_Line (Massive_Str, Standard_Error);

      Assert (True, "Massive string output printed without exceptions");
   end Test_Print_Massive_String;

   ----------------------------------
   -- Test_Print_Multiline_Strings --
   ----------------------------------

   procedure Test_Print_Multiline_Strings
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      --  String containing explicit CR and LF characters
      Multiline_Str : constant String :=
        "Line 1" & ASCII.CR & ASCII.LF & "Line 2" & ASCII.LF & "Line 3";
   begin
      Print (Multiline_Str, Standard_Output);
      Print_Line (Multiline_Str, Standard_Error);

      Assert (True, "Multiline string printed without exceptions");
   end Test_Print_Multiline_Strings;

end MakeOps.Tests.Sys_Terminal;
