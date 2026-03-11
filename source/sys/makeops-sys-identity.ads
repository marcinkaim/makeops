-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--  MakeOps.Sys.Identity
--  System Identity and Security Context
--
--  This package serves as a safe, SPARK-verifiable OS adapter for querying
--  the operating system user identity and security context.
-------------------------------------------------------------------------------

package MakeOps.Sys.Identity is
   pragma SPARK_Mode (On);

   --  Returns True if the current process is executing with superuser
   --  (root) privileges (i.e., OS User ID is 0), and False otherwise.
   --  This function strictly guarantees Absence of Runtime Errors (AoRE).
   function Is_Root_User return Boolean;

end MakeOps.Sys.Identity;
