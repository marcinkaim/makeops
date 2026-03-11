-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

with Interfaces.C;
with Interfaces.C.Strings;

private package MakeOps.Sys.FS.OS_Bindings is
   pragma SPARK_Mode (Off);

   --  POSIX constants for the 'access' mode
   F_OK : constant Interfaces.C.int := 0; --  Check existence
   X_OK : constant Interfaces.C.int := 1; --  Check execute permission
   R_OK : constant Interfaces.C.int := 4; --  Check read permission

   -------------------------------------------------------------------------
   --  Thin bindings to standard POSIX file system functions (glibc)
   -------------------------------------------------------------------------

   --  int access(const char *pathname, int mode);
   function c_access
     (Pathname : Interfaces.C.Strings.chars_ptr; Mode : Interfaces.C.int)
      return Interfaces.C.int;
   pragma Import (C, c_access, "access");

   --  int chdir(const char *path);
   function c_chdir
     (Path : Interfaces.C.Strings.chars_ptr) return Interfaces.C.int;
   pragma Import (C, c_chdir, "chdir");

   --  char *getcwd(char *buf, size_t size);
   function c_getcwd
     (Buf : Interfaces.C.Strings.chars_ptr; Size : Interfaces.C.size_t)
      return Interfaces.C.Strings.chars_ptr;
   pragma Import (C, c_getcwd, "getcwd");

   --  char *realpath(const char *path, char *resolved_path);
   function c_realpath
     (Path          : Interfaces.C.Strings.chars_ptr;
      Resolved_Path : Interfaces.C.Strings.chars_ptr)
      return Interfaces.C.Strings.chars_ptr;
   pragma Import (C, c_realpath, "realpath");

end MakeOps.Sys.FS.OS_Bindings;
