-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

private with Ada.Real_Time;

-------------------------------------------------------------------------------
--  MakeOps.Sys.Time
--  Monotonic Time and Duration Operations
--
--  This package provides a safe, SPARK-friendly OS adapter for querying
--  a strictly monotonic clock and calculating deterministic durations.
-------------------------------------------------------------------------------

package MakeOps.Sys.Time is
   pragma SPARK_Mode (On);

   -------------------------------------------------------------------------
   --  Types
   -------------------------------------------------------------------------

   --  A strongly typed integer representing a time interval in milliseconds.
   --  We use a 64-bit integer to prevent overflow issues over extremely
   --  long application uptimes or when calculating distant deadlines.
   type Duration_MS is new Long_Long_Integer;

   --  A private type representing an absolute point in monotonic time.
   --  Hiding the implementation details prevents domain logic from performing
   --  unsafe arithmetic directly on the time objects.
   type Timestamp is private;

   -------------------------------------------------------------------------
   --  Operations
   -------------------------------------------------------------------------

   --  Returns the current point in monotonic time.
   --  This clock is immune to system time adjustments (e.g., NTP syncs).
   function Clock return Timestamp;

   --  Calculates the elapsed execution time between two points in time.
   --  Returns the difference in deterministic integer milliseconds.
   function Elapsed_Time
     (Start_Time : Timestamp; End_Time : Timestamp) return Duration_MS;

   --  Calculates a future (or past) point in time by adding an offset
   --  in milliseconds to a base timestamp. Used to calculate deadlines.
   function Add_Milliseconds
     (Base_Time : Timestamp; Offset : Duration_MS) return Timestamp;

   --  Evaluates whether the current monotonic clock has surpassed
   --  the specified deadline.
   function Is_Past (Deadline : Timestamp) return Boolean;

private

   --  Internal representation using Ada's built-in
   --  POSIX-compliant monotonic clock.
   type Timestamp is record
      Internal_Time : Ada.Real_Time.Time;
   end record;

end MakeOps.Sys.Time;
