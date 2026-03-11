-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--  MakeOps.Sys.Env
--  Environment Variables Facade
--
--  This package serves as the safe, exception-free OS adapter for querying
--  host environment variables, providing deterministic degradation.
-------------------------------------------------------------------------------

with Ada.Strings.Bounded;

package MakeOps.Sys.Env is
   pragma SPARK_Mode (On);

   --  Maximum physical byte length of an environment variable key
   Max_Env_Var_Name_Length : constant := 64;

   --  Maximum physical byte length of an environment variable value
   Max_Env_Var_Value_Length : constant := 32768;

   --  Bounded string type for variable keys
   package Env_Name_Strings is new
     Ada.Strings.Bounded.Generic_Bounded_Length
       (Max => Max_Env_Var_Name_Length);
   subtype Env_Name_String is Env_Name_Strings.Bounded_String;

   --  Bounded string type for variable values
   package Env_Value_Strings is new
     Ada.Strings.Bounded.Generic_Bounded_Length
       (Max => Max_Env_Var_Value_Length);
   subtype Env_Value_String is Env_Value_Strings.Bounded_String;

   --  Enumeration representing the outcome of the OS query
   type Query_Status is (Found, Not_Found, Too_Long);

   --  Discriminated variant record guaranteeing memory safety.
   type Env_Result (Status : Query_Status := Not_Found) is record
      case Status is
         when Found =>
            Value : Env_Value_String;

         when Not_Found | Too_Long =>
            null;
      end case;
   end record;

   --  Safely interrogates the underlying Linux environment for the presence
   --  and value of a specific variable without raising native exceptions.
   function Get (Name : Env_Name_String) return Env_Result;

end MakeOps.Sys.Env;
