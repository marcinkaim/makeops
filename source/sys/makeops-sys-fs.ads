-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--  MakeOps.Sys.FS
--  File System Facade
--
--  This package serves as the safe, exception-free OS adapter for file
--  system interactions, path resolution, and pre-flight executability checks.
-------------------------------------------------------------------------------

package MakeOps.Sys.FS is
   pragma SPARK_Mode (On);

   --  Enumeration representing the deterministic outcome of
   --  file system queries
   type FS_Status is (Success, Not_Found, Permission_Denied);

   -------------------------------------------------------------------------
   --  Safe File System Operations
   -------------------------------------------------------------------------

   --  Checks if a file exists and is accessible.
   --  Used to safely probe optional preference files (Graceful Degradation).
   function Check_File_Access (Path : Path_String) return FS_Status;

   --  Pre-flight executability check to mathematically verify if a resolved
   --  binary path has POSIX execution (+x) permissions.
   function Is_Executable (Path : Path_String) return Boolean;

   --  Safely changes the current working directory of the process.
   --  Used to establish the Execution Context via --workdir CLI flag.
   function Change_Directory (Path : Path_String) return FS_Status;

   --  Retrieves the absolute path of the current working directory.
   function Get_Current_Directory return Path_String;

   --  Resolves the absolute directory path of a given file.
   --  Used to establish the Configuration Anchor.
   function Get_Absolute_Directory_Path
     (File_Path : Path_String) return Path_String;

end MakeOps.Sys.FS;
