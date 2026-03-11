-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

pragma Unreserve_All_Interrupts;

-------------------------------------------------------------------------------
--  MakeOps.Sys.Signals
--  System Signal Routing Facade
--
--  This package serves as the safe, thread-aware OS adapter for
--  intercepting and routing hardware interrupts and OS signals (e.g., SIGINT).
-------------------------------------------------------------------------------

package MakeOps.Sys.Signals is
   pragma SPARK_Mode (On);

   --  Returns True if a termination signal (such as SIGINT or SIGTERM)
   --  has been caught since the application started, and False otherwise.
   --  This function guarantees an atomic, thread-safe read without
   --  exposing the underlying concurrency primitives (protected objects).
   function Abort_Requested return Boolean;

end MakeOps.Sys.Signals;
