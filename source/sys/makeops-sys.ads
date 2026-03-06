-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--  MakeOps.Sys
--  System Infrastructure Root
--
--  This package acts as the abstraction layer for the Operating System.
--  It defines the base exceptions for OS-level failures and standard exit
--  codes.
-------------------------------------------------------------------------------

package MakeOps.Sys is
   --  Preelaborate is standard for packages that may eventually interface
   --  with C or hardware, preparing data structures at link-time.
   pragma Preelaborate;

   --  Standard POSIX-compliant exit codes.
   type Exit_Code is new Integer;
   Exit_Success : constant Exit_Code := 0;
   Exit_Failure : constant Exit_Code := 1;

   --  Base exception for any failure originating from the OS or Drivers.
   --  All child packages (e.g., Sys.FS, Sys.Net) should raise this
   --  or a derivation of it.
   System_Error : exception;

   --  Generic error code type (mapping to errno on Linux).
   type System_Error_Code is new Integer;

end MakeOps.Sys;
