-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

package body MakeOps.Sys.Time is

   --  We disable SPARK verification for the body because Ada.Real_Time.Clock
   --  reads volatile state from the operating system (hardware clock),
   --  which violates the mathematical purity required by GNATprove.
   pragma SPARK_Mode (Off);

   --  Make operators available for Ada.Real_Time types
   use type Ada.Real_Time.Time;
   use type Ada.Real_Time.Time_Span;

   -----------
   -- Clock --
   -----------

   function Clock return Timestamp is
   begin
      --  Return the current monotonic time wrapped in our private type
      return (Internal_Time => Ada.Real_Time.Clock);
   end Clock;

   ------------------
   -- Elapsed_Time --
   ------------------

   function Elapsed_Time
     (Start_Time : Timestamp; End_Time : Timestamp) return Duration_MS
   is
      Span : constant Ada.Real_Time.Time_Span :=
        End_Time.Internal_Time - Start_Time.Internal_Time;

      --  Convert Time_Span to standard Ada Duration (which is in seconds)
      Dur : constant Duration := Ada.Real_Time.To_Duration (Span);
   begin
      --  Convert fixed-point Duration (seconds) to integer milliseconds.
      return Duration_MS (Dur * 1_000.0);
   end Elapsed_Time;

   ----------------------
   -- Add_Milliseconds --
   ----------------------

   function Add_Milliseconds
     (Base_Time : Timestamp; Offset : Duration_MS) return Timestamp
   is
      --  Convert the 64-bit millisecond integer back to Duration (seconds).
      --  This prevents overflow issues that might occur if we passed a huge
      --  Integer to Ada.Real_Time.Milliseconds directly.
      Dur : constant Duration := Duration (Offset) / 1_000.0;

      --  Convert Duration to Time_Span for safe addition
      Span : constant Ada.Real_Time.Time_Span :=
        Ada.Real_Time.To_Time_Span (Dur);
   begin
      return (Internal_Time => Base_Time.Internal_Time + Span);
   end Add_Milliseconds;

   -------------
   -- Is_Past --
   -------------

   function Is_Past (Deadline : Timestamp) return Boolean is
   begin
      --  If the current monotonic clock is strictly greater than the deadline,
      --  the deadline has passed.
      return Ada.Real_Time.Clock > Deadline.Internal_Time;
   end Is_Past;

end MakeOps.Sys.Time;
