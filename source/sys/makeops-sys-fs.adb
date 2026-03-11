-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

with Ada.Directories;
with Interfaces.C;
with Interfaces.C.Strings;
with MakeOps.Sys.FS.OS_Bindings;

package body MakeOps.Sys.FS is
   pragma SPARK_Mode (Off);

   -----------------------
   -- Check_File_Access --
   -----------------------

   function Check_File_Access (Path : Path_String) return FS_Status is
      use Interfaces.C;
      use Interfaces.C.Strings;

      Native_Path : constant String := Path_Strings.To_String (Path);
      C_Path      : chars_ptr;
      Exists_Res  : int;
      Read_Res    : int;
   begin
      --  Convert Ada string to C-style null-terminated string pointer
      C_Path := New_String (Native_Path);

      --  First, strictly check if the file exists using POSIX F_OK
      Exists_Res := OS_Bindings.c_access (C_Path, OS_Bindings.F_OK);

      if Exists_Res /= 0 then
         Free (C_Path);
         return Not_Found;
      end if;

      --  Next, check if we have read permissions using POSIX R_OK
      Read_Res := OS_Bindings.c_access (C_Path, OS_Bindings.R_OK);
      Free (C_Path);

      if Read_Res = 0 then
         return Success;
      else
         return Permission_Denied;
      end if;
   exception
      when others =>
         --  Catch-all for safety to preserve AoRE boundary
         return Not_Found;
   end Check_File_Access;

   -------------------
   -- Is_Executable --
   -------------------

   function Is_Executable (Path : Path_String) return Boolean is
      use Interfaces.C;
      use Interfaces.C.Strings;

      Native_Path : constant String := Path_Strings.To_String (Path);
      C_Path      : chars_ptr;
      Result      : int;
   begin
      --  Convert Ada string to C-style null-terminated string pointer
      C_Path := New_String (Native_Path);

      --  Call the thin POSIX binding (access) with X_OK mode
      Result := OS_Bindings.c_access (C_Path, OS_Bindings.X_OK);

      --  Free the allocated C string to prevent memory leaks
      Free (C_Path);

      --  access() returns 0 on success (execution permitted)
      return Result = 0;
   exception
      when others =>
         --  If anything fails during translation or execution, safely degrade
         return False;
   end Is_Executable;

   ----------------------
   -- Change_Directory --
   ----------------------

   function Change_Directory (Path : Path_String) return FS_Status is
      use Interfaces.C;
      use Interfaces.C.Strings;

      Native_Path : constant String := Path_Strings.To_String (Path);
      C_Path      : chars_ptr;
      Result      : int;
   begin
      --  Convert Ada bounded string to C string
      C_Path := New_String (Native_Path);

      --  Invoke POSIX chdir
      Result := OS_Bindings.c_chdir (C_Path);
      Free (C_Path);

      --  chdir() returns 0 on success, -1 on error
      if Result = 0 then
         return Success;
      else
         --  Without directly interrogating errno, Not_Found serves as a safe
         --  generic degradation status for failure to enter the directory.
         return Not_Found;
      end if;
   exception
      when others =>
         return Not_Found;
   end Change_Directory;

   ---------------------------
   -- Get_Current_Directory --
   ---------------------------

   function Get_Current_Directory return Path_String is
      use Interfaces.C;
      use Interfaces.C.Strings;

      Buffer_Size : constant size_t := size_t (Max_Command_Length + 1);

      --  Pre-allocate an empty string to serve as a buffer for glibc
      Empty_Str  : constant String (1 .. Max_Command_Length + 1) :=
        [others => ASCII.NUL];
      C_Buf      : chars_ptr := New_String (Empty_Str);
      Result_Ptr : chars_ptr;
      Result_Str : Path_String;
   begin
      --  Invoke POSIX getcwd
      Result_Ptr := OS_Bindings.c_getcwd (C_Buf, Buffer_Size);

      if Result_Ptr /= Null_Ptr then
         --  Convert the populated C string back to an Ada Bounded String
         Result_Str := Path_Strings.To_Bounded_String (Value (C_Buf));
      else
         Result_Str := Path_Strings.Null_Bounded_String;
      end if;

      Free (C_Buf);
      return Result_Str;
   exception
      when others =>
         return Path_Strings.Null_Bounded_String;
   end Get_Current_Directory;

   ---------------------------------
   -- Get_Absolute_Directory_Path --
   ---------------------------------

   function Get_Absolute_Directory_Path
     (File_Path : Path_String) return Path_String
   is
      use Interfaces.C;
      use Interfaces.C.Strings;

      Native_Path : constant String := Path_Strings.To_String (File_Path);
      C_Path      : chars_ptr := New_String (Native_Path);

      Empty_Str  : constant String (1 .. Max_Command_Length + 1) :=
        [others => ASCII.NUL];
      C_Resolved : chars_ptr := New_String (Empty_Str);

      Result_Ptr : chars_ptr;
   begin
      --  Invoke POSIX realpath to resolve symlinks and get absolute path
      Result_Ptr := OS_Bindings.c_realpath (C_Path, C_Resolved);
      Free (C_Path);

      if Result_Ptr = Null_Ptr then
         Free (C_Resolved);
         return Path_Strings.Null_Bounded_String;
      end if;

      declare
         --  Extract the resolved absolute file path
         Resolved_Native : constant String := Value (C_Resolved);
      begin
         Free (C_Resolved);

         --  Extract the containing directory from the absolute file path
         --  using standard Ada.Directories for pure string manipulation.
         return
           Path_Strings.To_Bounded_String
             (Ada.Directories.Containing_Directory (Resolved_Native));
      end;
   exception
      when others =>
         return Path_Strings.Null_Bounded_String;
   end Get_Absolute_Directory_Path;

end MakeOps.Sys.FS;
