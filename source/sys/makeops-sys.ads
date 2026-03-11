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

with Ada.Strings.Bounded;

package MakeOps.Sys is
   --  Preelaborate is standard for packages that may eventually interface
   --  with C or hardware, preparing data structures at link-time.
   pragma Preelaborate;

   --  Maximum physical byte length of a file path or executable command
   Max_Command_Length : constant := 4096;

   --  Bounded string type for storing file system paths and commands
   package Path_Strings is new
     Ada.Strings.Bounded.Generic_Bounded_Length (Max => Max_Command_Length);
   subtype Path_String is Path_Strings.Bounded_String;

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
