-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--  MakeOps.Core
--  Business Logic & Utilities Root
--
--  This package defines the fundamental types and constants for the
--  internal logic of the system. It should remain platform-independent.
-------------------------------------------------------------------------------

package MakeOps.Core is
   pragma Pure;

   --  Universal integer type for internal calculations.
   --  Using a specific type prevents accidental mixing with standard Integer.
   type ID_Type is new Integer range 0 .. Integer'Last;

   --  Common result type for core operations (Functional Core style).
   type Operation_Result is (Success, Failure, Pending);

end MakeOps.Core;