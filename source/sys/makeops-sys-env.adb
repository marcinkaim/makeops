-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

with Ada.Environment_Variables;

package body MakeOps.Sys.Env is
   pragma SPARK_Mode (Off);

   ---------
   -- Get --
   ---------

   function Get (Name : Env_Name_String) return Env_Result is
      --  Convert the bounded string to a standard Ada String required by
      --  the OS binding
      Native_Name : constant String := Env_Name_Strings.To_String (Name);
   begin
      --  First, check existence to avoid exception-driven logic
      if not Ada.Environment_Variables.Exists (Native_Name) then
         return (Status => Not_Found);
      end if;

      declare
         --  Fetch the raw environment variable from the OS.
         Native_Value : constant String :=
           Ada.Environment_Variables.Value (Native_Name);
      begin
         --  Implement Fail-Fast for values exceeding the safe boundary
         if Native_Value'Length > Max_Env_Var_Value_Length then
            return (Status => Too_Long);
         end if;

         return
           (Status => Found,
            Value  => Env_Value_Strings.To_Bounded_String (Native_Value));
      end;
   exception
      when others =>
         --  Trap any other unexpected OS-level IO/Tasking exceptions
         --  to strictly guarantee the Absence of Runtime Errors (AoRE)
         --  boundary.
         return (Status => Not_Found);
   end Get;

end MakeOps.Sys.Env;
