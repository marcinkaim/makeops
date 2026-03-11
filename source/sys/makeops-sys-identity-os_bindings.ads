-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

with Interfaces.C;

-------------------------------------------------------------------------------
--  MakeOps.Sys.Identity.OS_Bindings
--  Thin Bindings for POSIX Identity Management
--
--  This private package maps the raw C application binary interface (ABI)
--  required to query the host OS for user identification.
-------------------------------------------------------------------------------

private package MakeOps.Sys.Identity.OS_Bindings is

   --  External C functions cannot be mathematically proven by GNATprove.
   pragma SPARK_Mode (Off);

   -------------------------------------------------------------------------
   --  POSIX Types & Structures
   -------------------------------------------------------------------------

   --  Mapping for POSIX uid_t (User ID)
   type uid_t is new Interfaces.C.unsigned;

   -------------------------------------------------------------------------
   --  Thin bindings to standard POSIX functions (glibc)
   -------------------------------------------------------------------------

   --  uid_t getuid(void);
   function c_getuid return uid_t;
   pragma Import (C, c_getuid, "getuid");

end MakeOps.Sys.Identity.OS_Bindings;
