-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

with MakeOps.Sys.Identity.OS_Bindings;

package body MakeOps.Sys.Identity is

   --  We disable SPARK verification for the body because it directly interacts
   --  with the unprovable external C ABI (getuid) defined in OS_Bindings.
   pragma SPARK_Mode (Off);

   ------------------
   -- Is_Root_User --
   ------------------

   function Is_Root_User return Boolean is
      use type MakeOps.Sys.Identity.OS_Bindings.uid_t;
   begin
      --  In POSIX systems, the superuser (root) always has a UID of 0.
      return MakeOps.Sys.Identity.OS_Bindings.c_getuid = 0;
   end Is_Root_User;

end MakeOps.Sys.Identity;
