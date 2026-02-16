-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--  MakeOps.App
--  Application Layer Root
--
--  This package defines the context for the executable application,
--  including exit codes and user interface configuration states.
-------------------------------------------------------------------------------

package MakeOps.App is
   --  Preelaborate allows us to define constants/types that might be used
   --  during elaboration, but permits dependencies on non-pure children later.
   pragma Preelaborate;

   --  Standard POSIX-compliant exit codes.
   type Exit_Code is new Integer;
   Exit_Success : constant Exit_Code := 0;
   Exit_Failure : constant Exit_Code := 1;

   --  Global verbosity settings for the user interface.
   type Verbosity_Level is (Silent, Normal, Verbose, Debug);

end MakeOps.App;