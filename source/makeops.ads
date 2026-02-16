-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--  MakeOps Project - System Engineering Tool
--  Root Package
--
--  This package serves as the root of the namespace hierarchy.
--  It is marked as Pure to allow universal elaboration.
-------------------------------------------------------------------------------

package MakeOps is
   pragma Pure;

   --  Project identity
   Name    : constant String := "MakeOps";
   Version : constant String := "0.1.0-alpha";

end MakeOps;