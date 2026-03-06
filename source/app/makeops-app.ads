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
--  representing the global application state and user interface configuration.
-------------------------------------------------------------------------------

package MakeOps.App is
   --  Preelaborate allows us to define constants/types that might be used
   --  during elaboration, but permits dependencies on non-pure children later.
   pragma Preelaborate;

   --  Global logging level settings for the user interface.
   type Log_Level is (Error, Info, Debug);

end MakeOps.App;
