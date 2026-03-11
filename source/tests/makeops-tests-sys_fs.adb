-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

with AUnit.Assertions; use AUnit.Assertions;
with MakeOps.Sys;      use MakeOps.Sys;
with MakeOps.Sys.FS;   use MakeOps.Sys.FS;

package body MakeOps.Tests.Sys_FS is

   ----------
   -- Name --
   ----------

   function Name (T : Test_Case) return AUnit.Message_String is
   begin
      return AUnit.Format ("DES-006: MakeOps.Sys.FS Tests");
   end Name;

   --------------------
   -- Register_Tests --
   --------------------

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Test_Check_File_Access_Existing'Access,
         "Check_File_Access: Happy Path (Existing Directory)");
      Register_Routine
        (T,
         Test_Check_File_Access_Missing'Access,
         "Check_File_Access: Edge Case (Missing File)");
      Register_Routine
        (T,
         Test_Check_File_Access_Permission_Denied'Access,
         "Check_File_Access: Edge Case (Permission Denied)");
      Register_Routine
        (T,
         Test_Is_Executable_Valid'Access,
         "Is_Executable: Happy Path (Valid Binary)");
      Register_Routine
        (T,
         Test_Is_Executable_Missing_Permissions'Access,
         "Is_Executable: Edge Case (Missing +x Permissions)");
      Register_Routine
        (T,
         Test_Is_Executable_Missing_File'Access,
         "Is_Executable: Edge Case (Missing File)");
      Register_Routine
        (T, Test_Change_Directory_Success'Access, "Change_Directory: Success");
      Register_Routine
        (T, Test_Change_Directory_Missing'Access, "Change_Directory: Missing");
      Register_Routine
        (T,
         Test_Get_Current_Directory_Valid'Access,
         "Get_Current_Directory: Valid");
      Register_Routine
        (T,
         Test_Get_Current_Directory_Integration'Access,
         "Get_Current_Directory: Integration");
      Register_Routine
        (T,
         Test_Get_Absolute_Directory_Path_Valid'Access,
         "Get_Absolute_Directory_Path: Valid");
      Register_Routine
        (T,
         Test_Get_Absolute_Directory_Path_Missing'Access,
         "Get_Absolute_Directory_Path: Missing");
   end Register_Tests;

   -------------------------------------
   -- Test_Check_File_Access_Existing --
   -------------------------------------

   procedure Test_Check_File_Access_Existing
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      Target : constant Path_String := Path_Strings.To_Bounded_String ("/tmp");
      Result : constant FS_Status := Check_File_Access (Target);
   begin
      Assert
        (Result = Success,
         "Access to standard /tmp directory should return Success");
   end Test_Check_File_Access_Existing;

   ------------------------------------
   -- Test_Check_File_Access_Missing --
   ------------------------------------

   procedure Test_Check_File_Access_Missing
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      Target : constant Path_String :=
        Path_Strings.To_Bounded_String ("/tmp/mko_fake_file_999.xyz");
      Result : constant FS_Status := Check_File_Access (Target);
   begin
      Assert
        (Result = Not_Found,
         "Access to missing file should gracefully degrade to Not_Found");
   end Test_Check_File_Access_Missing;

   ----------------------------------------------
   -- Test_Check_File_Access_Permission_Denied --
   ----------------------------------------------

   procedure Test_Check_File_Access_Permission_Denied
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      --  /etc/shadow is historically completely unreadable
      --  for non-root POSIX users.
      Target : constant Path_String :=
        Path_Strings.To_Bounded_String ("/etc/shadow");
      Result : constant FS_Status := Check_File_Access (Target);
   begin
      Assert
        (Result = Permission_Denied,
         "Check_File_Access must correctly detect lack of read permissions "
         & "for /etc/shadow and return Permission_Denied");
   end Test_Check_File_Access_Permission_Denied;

   ------------------------------
   -- Test_Is_Executable_Valid --
   ------------------------------

   procedure Test_Is_Executable_Valid
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      Target : constant Path_String :=
        Path_Strings.To_Bounded_String ("/bin/sh");
      Result : constant Boolean := Is_Executable (Target);
   begin
      Assert (Result, "/bin/sh should be detected as an executable file");
   end Test_Is_Executable_Valid;

   --------------------------------------------
   -- Test_Is_Executable_Missing_Permissions --
   --------------------------------------------

   procedure Test_Is_Executable_Missing_Permissions
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      Target : constant Path_String :=
        Path_Strings.To_Bounded_String ("/etc/passwd");
      Result : constant Boolean := Is_Executable (Target);
   begin
      Assert
        (not Result, "/etc/passwd should not have execution permissions (+x)");
   end Test_Is_Executable_Missing_Permissions;

   -------------------------------------
   -- Test_Is_Executable_Missing_File --
   -------------------------------------

   procedure Test_Is_Executable_Missing_File
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Target : constant Path_String :=
        Path_Strings.To_Bounded_String ("/tmp/non_existent_binary_999");
      Result : constant Boolean := Is_Executable (Target);
   begin
      Assert
        (not Result,
         "Pre-flight check for a completely missing file should "
         & "gracefully return False");
   end Test_Is_Executable_Missing_File;

   -----------------------------------
   -- Test_Change_Directory_Success --
   -----------------------------------

   procedure Test_Change_Directory_Success
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      Target : constant Path_String := Path_Strings.To_Bounded_String ("/tmp");
      Result : constant FS_Status := Change_Directory (Target);
   begin
      Assert (Result = Success, "Changing directory to /tmp should succeed");
   end Test_Change_Directory_Success;

   -----------------------------------
   -- Test_Change_Directory_Missing --
   -----------------------------------

   procedure Test_Change_Directory_Missing
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      Target : constant Path_String :=
        Path_Strings.To_Bounded_String ("/xyz_invalid_dir_999");
      Result : constant FS_Status := Change_Directory (Target);
   begin
      Assert
        (Result = Not_Found,
         "Changing to a non-existent directory "
         & "should gracefully return Not_Found");
   end Test_Change_Directory_Missing;

   --------------------------------------
   -- Test_Get_Current_Directory_Valid --
   --------------------------------------

   procedure Test_Get_Current_Directory_Valid
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      Result : constant Path_String := Get_Current_Directory;
   begin
      Assert
        (Path_Strings.Length (Result) > 0,
         "Current directory path should not be empty");
   end Test_Get_Current_Directory_Valid;

   --------------------------------------------
   -- Test_Get_Current_Directory_Integration --
   --------------------------------------------

   procedure Test_Get_Current_Directory_Integration
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      Original_Dir : constant Path_String := Get_Current_Directory;
      Target_Dir   : constant Path_String :=
        Path_Strings.To_Bounded_String ("/tmp");
      Change_Res   : FS_Status;
      New_Dir      : Path_String;
   begin
      --  Change to /tmp
      Change_Res := Change_Directory (Target_Dir);
      Assert
        (Change_Res = Success, "Setup: Failed to change directory to /tmp");

      --  Verify new directory
      New_Dir := Get_Current_Directory;
      Assert
        (Path_Strings.To_String (New_Dir) = "/tmp",
         "Current directory should be updated to /tmp");

      --  Restore original directory on successful execution
      Change_Res := Change_Directory (Original_Dir);

   exception
      when others =>
         --  "finally" emulation: restore directory even if an Assert failed,
         --  to prevent state leakage,
         --  and then re-raise the exception to AUnit.
         Change_Res := Change_Directory (Original_Dir);
         raise;
   end Test_Get_Current_Directory_Integration;

   --------------------------------------------
   -- Test_Get_Absolute_Directory_Path_Valid --
   --------------------------------------------

   procedure Test_Get_Absolute_Directory_Path_Valid
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      --  /etc/passwd is a standard POSIX file, its containing directory
      --  is always /etc
      Target     : constant Path_String :=
        Path_Strings.To_Bounded_String ("/etc/passwd");
      Result     : constant Path_String :=
        Get_Absolute_Directory_Path (Target);
      Result_Str : constant String := Path_Strings.To_String (Result);
   begin
      Assert
        (Result_Str = "/etc",
         "Containing directory of /etc/passwd "
         & "should resolve strictly to /etc");
   end Test_Get_Absolute_Directory_Path_Valid;

   ----------------------------------------------
   -- Test_Get_Absolute_Directory_Path_Missing --
   ----------------------------------------------

   procedure Test_Get_Absolute_Directory_Path_Missing
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      Target : constant Path_String :=
        Path_Strings.To_Bounded_String ("/tmp/mko_fake_file_999.xyz");
      Result : constant Path_String := Get_Absolute_Directory_Path (Target);
   begin
      Assert
        (Path_Strings.Length (Result) = 0,
         "Resolving a non-existent file "
         & "should safely return a null bounded string");
   end Test_Get_Absolute_Directory_Path_Missing;

end MakeOps.Tests.Sys_FS;
