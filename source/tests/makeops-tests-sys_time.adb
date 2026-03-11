-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

with AUnit.Assertions; use AUnit.Assertions;
with MakeOps.Sys.Time; use MakeOps.Sys.Time;

package body MakeOps.Tests.Sys_Time is

   ----------
   -- Name --
   ----------

   function Name (T : Test_Case) return AUnit.Message_String is
   begin
      return AUnit.Format ("DES-014: MakeOps.Sys.Time Tests");
   end Name;

   --------------------
   -- Register_Tests --
   --------------------

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Clock_Monotonicity'Access, "1. Clock: Monotonicity Check");
      Register_Routine
        (T,
         Test_Clock_Stability_Polling'Access,
         "2. Clock: Rapid Polling Stability");
      Register_Routine
        (T,
         Test_Elapsed_Time_Standard'Access,
         "3. Elapsed_Time: Standard Measurement");
      Register_Routine
        (T,
         Test_Elapsed_Time_Inverted'Access,
         "4. Elapsed_Time: Inverted Time Points");
      Register_Routine
        (T,
         Test_Add_Milliseconds_Forward'Access,
         "5. Add_Milliseconds: Forward Offset");
      Register_Routine
        (T,
         Test_Add_Milliseconds_Negative'Access,
         "6. Add_Milliseconds: Negative and Zero Offset");
      Register_Routine
        (T,
         Test_Is_Past_Future_Deadline'Access,
         "7. Is_Past: Future Deadline");
      Register_Routine
        (T,
         Test_Is_Past_Expired_Deadline'Access,
         "8. Is_Past: Expired Deadline");
   end Register_Tests;

   -----------------------------
   -- Test_Clock_Monotonicity --
   -----------------------------

   procedure Test_Clock_Monotonicity
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      T1, T2 : Timestamp;
      Dur    : Duration_MS;
   begin
      T1 := Clock;
      delay 0.05; --  Wait for roughly 50 milliseconds
      T2 := Clock;

      Dur := Elapsed_Time (T1, T2);

      Assert (Dur >= 0, "Clock must not go backwards (strictly monotonic).");
      --  We expect roughly 50ms, but OS scheduling varies, so we check > 0
      Assert (Dur >= 10, "Elapsed time should reflect the delayed pause.");
   end Test_Clock_Monotonicity;

   ----------------------------------
   -- Test_Clock_Stability_Polling --
   ----------------------------------

   procedure Test_Clock_Stability_Polling
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Current : Timestamp;
   begin
      --  Poll the clock 10,000 times in a tight loop to ensure no ABI
      --  crashes or performance hiccups happen at the boundary.
      for I in 1 .. 10_000 loop
         Current := Clock;
      end loop;

      pragma Unreferenced (Current);

      Assert (True, "Survived 10,000 rapid clock polls without exception.");
   end Test_Clock_Stability_Polling;

   --------------------------------
   -- Test_Elapsed_Time_Standard --
   --------------------------------

   procedure Test_Elapsed_Time_Standard
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      T1, T2 : Timestamp;
      Dur    : Duration_MS;
   begin
      T1 := Clock;
      --  Simulate a point in time exactly 500ms in the future
      T2 := Add_Milliseconds (T1, 500);

      Dur := Elapsed_Time (T1, T2);

      Assert
        (Dur = 500, "Elapsed_Time should compute exactly 500ms difference.");
   end Test_Elapsed_Time_Standard;

   --------------------------------
   -- Test_Elapsed_Time_Inverted --
   --------------------------------

   procedure Test_Elapsed_Time_Inverted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      T1, T2 : Timestamp;
      Dur    : Duration_MS;
   begin
      T1 := Clock;
      T2 := Add_Milliseconds (T1, 500);

      --  Invert the order: End_Time is earlier than Start_Time
      Dur := Elapsed_Time (Start_Time => T2, End_Time => T1);

      Assert
        (Dur = -500, "Inverted elapsed time should return exactly -500ms.");
   end Test_Elapsed_Time_Inverted;

   -----------------------------------
   -- Test_Add_Milliseconds_Forward --
   -----------------------------------

   procedure Test_Add_Milliseconds_Forward
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Base, Future : Timestamp;
      Dur          : Duration_MS;
   begin
      Base := Clock;
      Future := Add_Milliseconds (Base, 10_000);

      Dur := Elapsed_Time (Base, Future);

      Assert
        (Dur = 10_000, "Future timestamp should be exactly 10,000ms ahead.");
   end Test_Add_Milliseconds_Forward;

   ------------------------------------
   -- Test_Add_Milliseconds_Negative --
   ------------------------------------

   procedure Test_Add_Milliseconds_Negative
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Base, Past, Zero_Off : Timestamp;
      Dur_Past, Dur_Zero   : Duration_MS;
   begin
      Base := Clock;

      Past := Add_Milliseconds (Base, -5_000);
      Zero_Off := Add_Milliseconds (Base, 0);

      Dur_Past := Elapsed_Time (Base, Past);
      Dur_Zero := Elapsed_Time (Base, Zero_Off);

      Assert
        (Dur_Past = -5_000,
         "Adding negative offset should result in time in the past.");
      Assert
        (Dur_Zero = 0,
         "Adding zero offset should result in the exact same time.");
   end Test_Add_Milliseconds_Negative;

   ----------------------------------
   -- Test_Is_Past_Future_Deadline --
   ----------------------------------

   procedure Test_Is_Past_Future_Deadline
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Deadline : Timestamp;
   begin
      --  Set a deadline 60 seconds from now
      Deadline := Add_Milliseconds (Clock, 60_000);

      Assert
        (not Is_Past (Deadline),
         "A future deadline must not be evaluated as past.");
   end Test_Is_Past_Future_Deadline;

   -----------------------------------
   -- Test_Is_Past_Expired_Deadline --
   -----------------------------------

   procedure Test_Is_Past_Expired_Deadline
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Deadline : Timestamp;
   begin
      --  Set a deadline 100 milliseconds in the past
      Deadline := Add_Milliseconds (Clock, -100);

      Assert
        (Is_Past (Deadline),
         "An expired deadline must evaluate to true immediately.");
   end Test_Is_Past_Expired_Deadline;

end MakeOps.Tests.Sys_Time;
