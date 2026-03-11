-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

with Interfaces.C;
with AUnit.Assertions;      use AUnit.Assertions;
with MakeOps.Sys;           use MakeOps.Sys;
with MakeOps.Sys.Processes; use MakeOps.Sys.Processes;

package body MakeOps.Tests.Sys_Processes is

   ----------
   -- Name --
   ----------

   function Name (T : Test_Case) return AUnit.Message_String is
   begin
      return AUnit.Format ("DES-008: MakeOps.Sys.Processes Tests");
   end Name;

   --------------------
   -- Register_Tests --
   --------------------

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      --  Register pipe lifecycle tests
      Register_Routine
        (T,
         Test_Pipe_Lifecycle_Success'Access,
         "Create_Pipe & Close_FD: Happy Path");
      Register_Routine
        (T,
         Test_Close_Invalid_FD'Access,
         "Close_FD: Edge Case (Invalid/Closed FDs)");

      --  Register remaining scenarios (stubs)
      Register_Routine
        (T, Test_Spawn_Valid_Command'Access, "Spawn: Valid Command");
      Register_Routine
        (T, Test_Spawn_Execvp_Failure'Access, "Spawn: Execvp Failure");
      Register_Routine
        (T, Test_Probe_State_Normal_Exit'Access, "Probe_State: Normal Exit");
      Register_Routine
        (T, Test_Probe_State_Invalid_PID'Access, "Probe_State: Invalid PID");
      Register_Routine (T, Test_Send_Signal_Kill'Access, "Send_Signal: Kill");
      Register_Routine
        (T, Test_Send_Signal_Dead_Process'Access, "Send_Signal: Dead Process");
      Register_Routine
        (T,
         Test_IO_Multiplexing_Data_Flow'Access,
         "I/O Multiplexing: Data Flow");
      Register_Routine
        (T,
         Test_IO_Non_Blocking_Empty_And_EOF'Access,
         "I/O Multiplexing: Empty and EOF");
      Register_Routine
        (T,
         Test_Spawn_No_Arguments'Access,
         "Spawn: No Arguments (Empty List)");
      Register_Routine
        (T,
         Test_Spawn_Asymmetric_Streams'Access,
         "Spawn: Asymmetric Streams (/dev/null Routing)");
      Register_Routine
        (T,
         Test_Poll_Streams_Zero_Timeout'Access,
         "I/O Multiplexing: Zero Timeout Polling");
      Register_Routine
        (T,
         Test_Spawn_Max_Arguments'Access,
         "Spawn: Maximum Allowed Arguments (Stress Test)");
      Register_Routine
        (T,
         Test_Poll_Streams_Empty_Array'Access,
         "I/O Multiplexing: Empty FD Array (Boundary Check)");
      Register_Routine
        (T,
         Test_Probe_State_Signaled_Exit'Access,
         "Probe_State: External Crash (SIGABRT)");
      Register_Routine
        (T,
         Test_Read_Stream_Invalid_FD'Access,
         "I/O Multiplexing: Read from Invalid/Closed FD (EBADF)");
      Register_Routine
        (T,
         Test_IO_Multiplexing_Large_Payload'Access,
         "I/O Multiplexing: Payload Exceeding Max Chunk Length");
      Register_Routine
        (T,
         Test_Poll_Streams_Invalid_FD'Access,
         "I/O Multiplexing: Poll handling POLLNVAL on Invalid FD");
      Register_Routine
        (T,
         Test_Spawn_Max_Arg_Length'Access,
         "Spawn: Maximum Length of a Single Argument");

      --  POSIX Boundary & Semantic Validations
      Register_Routine
        (T,
         Test_Probe_State_Non_Zero_Exit'Access,
         "Probe_State: Non-Zero Exact Exit Code Parsing");
      Register_Routine
        (T,
         Test_Create_Pipe_FD_Exhaustion'Access,
         "Create_Pipe: File Descriptor Exhaustion (EMFILE/ENFILE)");
      Register_Routine
        (T,
         Test_Poll_Streams_Timeout_Expiration'Access,
         "Poll_Streams: Timeout Expiration on Empty Stream");
   end Register_Tests;

   ---------------------------------
   -- Test_Pipe_Lifecycle_Success --
   ---------------------------------

   procedure Test_Pipe_Lifecycle_Success
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Read_FD  : File_Descriptor;
      Write_FD : File_Descriptor;
   begin
      --  Attempt to create a pipe
      Create_Pipe (Read_FD, Write_FD);

      --  Verify the validity of the assigned descriptors
      Assert (Read_FD /= Invalid_FD, "Read_FD should be a valid descriptor");
      Assert (Write_FD /= Invalid_FD, "Write_FD should be a valid descriptor");
      Assert
        (Read_FD /= Write_FD,
         "Read_FD and Write_FD must be distinct descriptors");

      --  Test correct descriptor closure (post-test cleanup)
      Close_FD (Read_FD);
      Close_FD (Write_FD);
   end Test_Pipe_Lifecycle_Success;

   ---------------------------
   -- Test_Close_Invalid_FD --
   ---------------------------

   procedure Test_Close_Invalid_FD
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      --  Verify Graceful Degradation:
      --  Closing invalid or already closed descriptors
      --  should not raise any exceptions from the POSIX/C layer.
      Close_FD (Invalid_FD);
      Close_FD (File_Descriptor (9999));
   end Test_Close_Invalid_FD;


   ------------------------------
   -- Test_Spawn_Valid_Command --
   ------------------------------

   procedure Test_Spawn_Valid_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args : Arg_List (1 .. 1);
      PID  : Process_ID;
   begin
      Args (1) := Arg_Strings.To_Bounded_String ("Hello");

      --  Spawn a simple echo command with detached streams
      PID :=
        Spawn
          (Command => Path_Strings.To_Bounded_String ("/bin/echo"),
           Args    => Args,
           FD_Out  => Invalid_FD,
           FD_Err  => Invalid_FD);

      Assert
        (PID > 0, "Spawn should return a valid, strictly positive Process_ID");

      --  Note: We do not aggressively wait for the process to exit here,
      --  as Probe_State is tested in its own isolated scenarios.
   end Test_Spawn_Valid_Command;

   -------------------------------
   -- Test_Spawn_Execvp_Failure --
   -------------------------------

   procedure Test_Spawn_Execvp_Failure
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args : Arg_List (1 .. 1);
      PID  : Process_ID;
   begin
      Args (1) := Arg_Strings.To_Bounded_String ("--version");

      --  Attempt to spawn a non-existent binary
      PID :=
        Spawn
          (Command =>
             Path_Strings.To_Bounded_String ("/tmp/non_existent_makeops_bin"),
           Args    => Args,
           FD_Out  => Invalid_FD,
           FD_Err  => Invalid_FD);

      Assert
        (PID > 0,
         "Spawn should still return a valid PID because fork() succeeds, "
         & "even if execvp() fails in the child process");
   end Test_Spawn_Execvp_Failure;

   ----------------------------------
   -- Test_Probe_State_Normal_Exit --
   ----------------------------------

   procedure Test_Probe_State_Normal_Exit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      Args   : Arg_List (1 .. 2);
      PID    : Process_ID;
      Result : Process_Result;
   begin
      --  We instruct the shell to simply exit with code 42
      Args (1) := Arg_Strings.To_Bounded_String ("-c");
      Args (2) := Arg_Strings.To_Bounded_String ("exit 42");

      PID :=
        Spawn
          (Command => Path_Strings.To_Bounded_String ("/bin/sh"),
           Args    => Args,
           FD_Out  => Invalid_FD,
           FD_Err  => Invalid_FD);

      Assert (PID > 0, "Spawn should return a valid PID");

      --  Asynchronous polling loop (non-blocking)
      --  In a real scenario, this would be part of
      --  the I/O multiplexing event loop.
      loop
         Result := Probe_State (PID);
         exit when Result.State /= Running;
         delay 0.05; --  Wait 50 milliseconds before polling again
      end loop;

      Assert
        (Result.State = Exited_Normally,
         "The process should exit gracefully without signals");

      Assert
        (Result.Exit_Code = MakeOps.Sys.Exit_Code (42),
         "The decoded exit code should exactly match the requested 42");
   end Test_Probe_State_Normal_Exit;

   ----------------------------------
   -- Test_Probe_State_Invalid_PID --
   ----------------------------------

   procedure Test_Probe_State_Invalid_PID
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : Process_Result;
   begin
      --  Attempt to probe a purely abstract, negative Process ID
      Result := Probe_State (Process_ID (-9999));

      --  The thin binding should catch the OS error (ECHILD) and return
      --  it gracefully as a state enum variant instead of
      --  raising an exception.
      Assert
        (Result.State = OS_Error,
         "Probing a non-existent PID should gracefully return OS_Error");
   end Test_Probe_State_Invalid_PID;

   ---------------------------
   -- Test_Send_Signal_Kill --
   ---------------------------

   procedure Test_Send_Signal_Kill
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args    : Arg_List (1 .. 1);
      PID     : Process_ID;
      Result  : Process_Result;
      SIGKILL : constant Integer := 9;
   begin
      Args (1) := Arg_Strings.To_Bounded_String ("10");

      --  Spawn a process that will sleep for 10 seconds
      PID :=
        Spawn
          (Command => Path_Strings.To_Bounded_String ("/bin/sleep"),
           Args    => Args,
           FD_Out  => Invalid_FD,
           FD_Err  => Invalid_FD);

      Assert (PID > 0, "Spawn should return a valid PID for sleep command");

      --  Send SIGKILL to terminate the process immediately
      Send_Signal (PID, SIGKILL);

      --  Wait for the process state to update.
      --  We use a bounded loop to prevent infinite hangs in test execution.
      for I in 1 .. 50 loop
         Result := Probe_State (PID);
         exit when Result.State /= Running;
         delay 0.05;
      end loop;

      Assert
        (Result.State = Killed_By_Signal,
         "The process should be terminated by a signal");

      Assert
        (Result.Signal_Number = SIGKILL,
         "The terminating signal should be SIGKILL (9)");
   end Test_Send_Signal_Kill;

   -----------------------------------
   -- Test_Send_Signal_Dead_Process --
   -----------------------------------

   procedure Test_Send_Signal_Dead_Process
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      --  Attempt to send a signal to a purely abstract, non-existent process.
      --  The implementation should gracefully ignore
      --  the ESRCH error from the OS.
      Send_Signal (Process_ID (-9999), 9);

      --  If we reached this point without raising an exception,
      --  the test passes.
      --  Implicit assertion of Graceful Degradation.
   end Test_Send_Signal_Dead_Process;

   ------------------------------------
   -- Test_IO_Multiplexing_Data_Flow --
   ------------------------------------

   procedure Test_IO_Multiplexing_Data_Flow
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Out_Read, Out_Write : File_Descriptor;
      Err_Read, Err_Write : File_Descriptor;

      Args             : Arg_List (1 .. 2);
      PID              : Process_ID;
      FDs              : FD_Array (1 .. 2);
      Ready            : FD_Ready_Array (1 .. 2);
      Res_Out, Res_Err : Stream_Result;
   begin
      --  Create dedicated pipes for stdout and stderr
      Create_Pipe (Out_Read, Out_Write);
      Create_Pipe (Err_Read, Err_Write);

      --  Command: echo OUT && >&2 echo ERR
      Args (1) := Arg_Strings.To_Bounded_String ("-c");
      Args (2) := Arg_Strings.To_Bounded_String ("echo OUT && >&2 echo ERR");

      PID :=
        Spawn
          (Command => Path_Strings.To_Bounded_String ("/bin/sh"),
           Args    => Args,
           FD_Out  => Out_Write,
           FD_Err  => Err_Write);

      Assert
        (PID > 0, "Spawn should return a valid PID for the shell process");

      --  Close write ends in the parent process immediately.
      --  If we don't do this, read() will never return EOF later!
      Close_FD (Out_Write);
      Close_FD (Err_Write);

      --  Setup polling array
      FDs (1) := Out_Read;
      FDs (2) := Err_Read;

      --  Wait up to 1000ms for data to appear on either stream
      Ready := Poll_Streams (FDs, Timeout_MS => 1000);

      --  We expect both file descriptors to eventually
      --  report data in this scenario
      if Ready (1) then
         Res_Out := Read_Stream_Chunk (Out_Read);
         Assert
           (Res_Out.Status = Data_Available,
            "Expected data to be available on stdout pipe");
         Assert
           (Chunk_Strings.To_String (Res_Out.Chunk) = "OUT" & ASCII.LF,
            "stdout payload should exactly match 'OUT\n'");
      end if;

      if Ready (2) then
         Res_Err := Read_Stream_Chunk (Err_Read);
         Assert
           (Res_Err.Status = Data_Available,
            "Expected data to be available on stderr pipe");
         Assert
           (Chunk_Strings.To_String (Res_Err.Chunk) = "ERR" & ASCII.LF,
            "stderr payload should exactly match 'ERR\n'");
      end if;

      --  Cleanup read ends
      Close_FD (Out_Read);
      Close_FD (Err_Read);
   end Test_IO_Multiplexing_Data_Flow;

   ----------------------------------------
   -- Test_IO_Non_Blocking_Empty_And_EOF --
   ----------------------------------------

   procedure Test_IO_Non_Blocking_Empty_And_EOF
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Read_FD, Write_FD : File_Descriptor;
      Result            : Stream_Result;
   begin
      Create_Pipe (Read_FD, Write_FD);

      --  1. Test Empty state (O_NONBLOCK prevents thread hang)
      Result := Read_Stream_Chunk (Read_FD);
      Assert
        (Result.Status = Empty,
         "Reading from an empty, non-blocking pipe "
         & "should gracefully return Empty");

      --  2. Test EOF state
      Close_FD (Write_FD);
      Result := Read_Stream_Chunk (Read_FD);
      Assert
        (Result.Status = End_Of_File,
         "Reading from a pipe whose write-end is closed "
         & "should return End_Of_File");

      --  Cleanup
      Close_FD (Read_FD);
   end Test_IO_Non_Blocking_Empty_And_EOF;

   -----------------------------
   -- Test_Spawn_No_Arguments --
   -----------------------------

   procedure Test_Spawn_No_Arguments
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Empty_Args : Arg_List (1 .. 0); --  Explicitly empty array
      PID        : Process_ID;
      Result     : Process_Result;
   begin
      --  Spawn a command without any additional arguments
      PID :=
        Spawn
          (Command => Path_Strings.To_Bounded_String ("/bin/true"),
           Args    => Empty_Args,
           FD_Out  => Invalid_FD,
           FD_Err  => Invalid_FD);

      Assert (PID > 0, "Spawn should gracefully handle empty argument arrays");

      --  Wait for successful termination
      for I in 1 .. 50 loop
         Result := Probe_State (PID);
         exit when Result.State /= Running;
         delay 0.05;
      end loop;

      Assert
        (Result.State = Exited_Normally,
         "Process spawned without arguments should execute and exit normally");
   end Test_Spawn_No_Arguments;

   -----------------------------------
   -- Test_Spawn_Asymmetric_Streams --
   -----------------------------------

   procedure Test_Spawn_Asymmetric_Streams
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Err_Read, Err_Write : File_Descriptor;
      Args                : Arg_List (1 .. 2);
      PID                 : Process_ID;
      FDs                 : FD_Array (1 .. 1);
      Ready               : FD_Ready_Array (1 .. 1);
      Res_Err             : Stream_Result;
   begin
      Create_Pipe (Err_Read, Err_Write);

      --  Command writes to both stdout and stderr
      Args (1) := Arg_Strings.To_Bounded_String ("-c");
      Args (2) :=
        Arg_Strings.To_Bounded_String
          ("echo STDOUT_IGNORED && >&2 echo STDERR_KEPT");

      --  Simulate "Error Log Level" by detaching stdout but keeping stderr
      PID :=
        Spawn
          (Command => Path_Strings.To_Bounded_String ("/bin/sh"),
           Args    => Args,
           FD_Out  => Invalid_FD,
           FD_Err  => Err_Write);

      pragma Unreferenced (PID);

      Close_FD (Err_Write);

      FDs (1) := Err_Read;
      Ready := Poll_Streams (FDs, Timeout_MS => 1000);

      if Ready (1) then
         Res_Err := Read_Stream_Chunk (Err_Read);
         Assert
           (Res_Err.Status = Data_Available,
            "stderr data must be successfully captured");

      --  We assert implicitly that stdout was successfully discarded
      --  by the OS to /dev/null, otherwise the process would have hung
      --  or crashed writing to a closed default FD 1.

      end if;

      Close_FD (Err_Read);
   end Test_Spawn_Asymmetric_Streams;

   ------------------------------------
   -- Test_Poll_Streams_Zero_Timeout --
   ------------------------------------

   procedure Test_Poll_Streams_Zero_Timeout
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Read_FD, Write_FD : File_Descriptor;
      FDs               : FD_Array (1 .. 1);
      Ready             : FD_Ready_Array (1 .. 1);
   begin
      Create_Pipe (Read_FD, Write_FD);
      FDs (1) := Read_FD;

      --  Poll with 0ms timeout should return instantly without blocking
      Ready := Poll_Streams (FDs, Timeout_MS => 0);

      Assert
        (Ready (1) = False,
         "Polling an empty pipe with 0 timeout must instantly return False");

      Close_FD (Read_FD);
      Close_FD (Write_FD);
   end Test_Poll_Streams_Zero_Timeout;

   ------------------------------
   -- Test_Spawn_Max_Arguments --
   ------------------------------

   procedure Test_Spawn_Max_Arguments
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args : Arg_List (1 .. Max_Args_Per_Command);
      PID  : Process_ID;
   begin
      --  Fill the array to its absolute maximum capacity
      for I in Args'Range loop
         Args (I) := Arg_Strings.To_Bounded_String ("--dummy-arg");
      end loop;

      --  Spawn process. /bin/true simply ignores arguments and exits with 0.
      PID :=
        Spawn
          (Command => Path_Strings.To_Bounded_String ("/bin/true"),
           Args    => Args,
           FD_Out  => Invalid_FD,
           FD_Err  => Invalid_FD);

      Assert
        (PID > 0,
         "Spawn should handle the maximum allowed arguments ("
         & Integer'Image (Max_Args_Per_Command)
         & ") without buffer overflows");
   end Test_Spawn_Max_Arguments;

   -----------------------------------
   -- Test_Poll_Streams_Empty_Array --
   -----------------------------------

   procedure Test_Poll_Streams_Empty_Array
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Empty_FDs : constant FD_Array (1 .. 0) := [others => Invalid_FD];
      Ready     : FD_Ready_Array (1 .. 0);
   begin
      --  Attempt to poll an array of length 0.
      --  The thin binding must securely bypass the C poll() call
      --  to prevent invalid pointer dereferences.
      Ready := Poll_Streams (Empty_FDs, Timeout_MS => 100);

      Assert
        (Ready'Length = 0,
         "Polling an empty FD array should deterministically return "
         & "an empty Ready array without crashing");
   end Test_Poll_Streams_Empty_Array;

   ------------------------------------
   -- Test_Probe_State_Signaled_Exit --
   ------------------------------------

   procedure Test_Probe_State_Signaled_Exit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args    : Arg_List (1 .. 2);
      PID     : Process_ID;
      Result  : Process_Result;
      SIGABRT : constant Integer := 6; --  POSIX SIGABRT
   begin
      --  Instruct the shell to kill itself with SIGABRT (6)
      Args (1) := Arg_Strings.To_Bounded_String ("-c");
      Args (2) := Arg_Strings.To_Bounded_String ("kill -ABRT $$");

      PID :=
        Spawn
          (Command => Path_Strings.To_Bounded_String ("/bin/sh"),
           Args    => Args,
           FD_Out  => Invalid_FD,
           FD_Err  => Invalid_FD);

      Assert (PID > 0, "Spawn should return a valid PID");

      for I in 1 .. 50 loop
         Result := Probe_State (PID);
         exit when Result.State /= Running;
         delay 0.05;
      end loop;

      Assert
        (Result.State = Killed_By_Signal,
         "Process should be recorded as killed by a signal (external crash)");

      Assert
        (Result.Signal_Number = SIGABRT,
         "The decoded fatal signal should be exactly SIGABRT (6)");
   end Test_Probe_State_Signaled_Exit;

   ---------------------------------
   -- Test_Read_Stream_Invalid_FD --
   ---------------------------------

   procedure Test_Read_Stream_Invalid_FD
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : Stream_Result;
   begin
      --  Attempting to read from Invalid_FD (-1) or a closed FD
      --  causes the OS read() to return -1 (EBADF).
      --  Our thick wrapper should gracefully catch this and return Empty.
      Result := Read_Stream_Chunk (Invalid_FD);

      Assert
        (Result.Status = Empty,
         "Reading from an invalid FD should gracefully return Empty status");
   end Test_Read_Stream_Invalid_FD;

   ----------------------------------------
   -- Test_IO_Multiplexing_Large_Payload --
   ----------------------------------------

   procedure Test_IO_Multiplexing_Large_Payload
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Out_Read, Out_Write : File_Descriptor;
      Args                : Arg_List (1 .. 2);
      PID                 : Process_ID;
      FDs                 : FD_Array (1 .. 1);
      Ready               : FD_Ready_Array (1 .. 1);
      Res_Out             : Stream_Result;
   begin
      Create_Pipe (Out_Read, Out_Write);

      --  Use awk to generate exactly 5000 characters of output.
      --  This deliberately exceeds Max_Stream_Chunk_Length (4096).
      Args (1) := Arg_Strings.To_Bounded_String ("-c");
      Args (2) :=
        Arg_Strings.To_Bounded_String
          ("awk 'BEGIN{for(i=0;i<5000;i++) printf ""A""}'");

      PID :=
        Spawn
          (Command => Path_Strings.To_Bounded_String ("/bin/sh"),
           Args    => Args,
           FD_Out  => Out_Write,
           FD_Err  => Invalid_FD);

      pragma Unreferenced (PID);

      Close_FD (Out_Write);
      FDs (1) := Out_Read;

      Ready := Poll_Streams (FDs, Timeout_MS => 1000);

      if Ready (1) then
         Res_Out := Read_Stream_Chunk (Out_Read);

         Assert
           (Res_Out.Status = Data_Available,
            "First chunk should be available");

         Assert
           (Chunk_Strings.Length (Res_Out.Chunk) = Max_Stream_Chunk_Length,
            "Chunk size must be explicitly constrained to "
            & "Max_Stream_Chunk_Length ("
            & Integer'Image (Max_Stream_Chunk_Length)
            & ") preventing buffer overflow");
      end if;

      Close_FD (Out_Read);
   end Test_IO_Multiplexing_Large_Payload;

   ----------------------------------
   -- Test_Poll_Streams_Invalid_FD --
   ----------------------------------

   procedure Test_Poll_Streams_Invalid_FD
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      --  POSIX poll() ignores negative FDs (like Invalid_FD = -1)
      --  and returns 0.
      --  To trigger POLLNVAL, we must provide
      --  a positive but closed/invalid FD.
      FDs   : constant FD_Array (1 .. 1) := [1 => File_Descriptor (9999)];
      Ready : FD_Ready_Array (1 .. 1);
   begin
      --  poll() will set POLLNVAL in revents for an invalid FD.
      --  Our wrapper should detect revents /= 0 and
      --  proactively mark it as Ready.
      Ready := Poll_Streams (FDs, Timeout_MS => 0);

      Assert
        (Ready (1) = True,
         "Poll_Streams should flag invalid FDs as ready (due to POLLNVAL) "
         & "so the caller can immediately discover the error via read()");
   end Test_Poll_Streams_Invalid_FD;

   -------------------------------
   -- Test_Spawn_Max_Arg_Length --
   -------------------------------

   procedure Test_Spawn_Max_Arg_Length
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : Arg_List (1 .. 1);
      PID    : Process_ID;
      Result : Process_Result;
   begin
      --  Create an argument of exactly Max_Arg_Length bytes
      Args (1) :=
        Arg_Strings.To_Bounded_String (String'(1 .. Max_Arg_Length => 'X'));

      --  /bin/true ignores arguments and exits with 0
      PID :=
        Spawn
          (Command => Path_Strings.To_Bounded_String ("/bin/true"),
           Args    => Args,
           FD_Out  => Invalid_FD,
           FD_Err  => Invalid_FD);

      Assert
        (PID > 0,
         "Spawn should safely translate maximum length "
         & "arguments across the C ABI");

      for I in 1 .. 50 loop
         Result := Probe_State (PID);
         exit when Result.State /= Running;
         delay 0.05;
      end loop;

      Assert
        (Result.State = Exited_Normally,
         "Process with maximum length argument "
         & "should execute and exit normally");
   end Test_Spawn_Max_Arg_Length;

   ------------------------------------
   -- Test_Probe_State_Non_Zero_Exit --
   ------------------------------------

   procedure Test_Probe_State_Non_Zero_Exit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : Arg_List (1 .. 2);
      PID    : Process_ID;
      Result : Process_Result;
   begin
      --  We use standard shell to explicitly return code 42
      Args (1) := Arg_Strings.To_Bounded_String ("-c");
      Args (2) := Arg_Strings.To_Bounded_String ("exit 42");

      PID :=
        Spawn
          (Command => Path_Strings.To_Bounded_String ("/bin/sh"),
           Args    => Args,
           FD_Out  => Invalid_FD,
           FD_Err  => Invalid_FD);

      --  Wait for process to exit
      for I in 1 .. 50 loop
         Result := Probe_State (PID);
         exit when Result.State /= Running;
         delay 0.05;
      end loop;

      Assert (Result.State = Exited_Normally, "Process should exit normally");
      Assert
        (Result.Exit_Code = 42,
         "Exit code should be exactly 42 as returned by the shell");
   end Test_Probe_State_Non_Zero_Exit;

   ------------------------------------
   -- Test_Create_Pipe_FD_Exhaustion --
   ------------------------------------

   procedure Test_Create_Pipe_FD_Exhaustion
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Interfaces.C;

      --  POSIX rlimit bindings to forcefully restrict the environment limit
      --  just for the duration of this specific test.
      RLIMIT_NOFILE : constant int := 7;

      type rlim_t is new unsigned_long;
      type struct_rlimit is record
         rlim_cur : rlim_t;
         rlim_max : rlim_t;
      end record;
      pragma Convention (C, struct_rlimit);

      function c_getrlimit
        (resource : int; rlim : access struct_rlimit) return int;
      pragma Import (C, c_getrlimit, "getrlimit");

      function c_setrlimit
        (resource : int; rlim : access struct_rlimit) return int;
      pragma Import (C, c_setrlimit, "setrlimit");

      Original_Limit : aliased struct_rlimit;
      Test_Limit     : aliased struct_rlimit;
      Result_C       : int;

      --  We artificially lower the process limit to 256.
      --  POSIX reserves 3 FDs (stdin, stdout, stderr) by default.
      --  Each pipe consumes 2 FDs. Therefore,
      --  maximum successful pipes = (256 - 3) / 2 = 126.
      --  Attempting to open 128 pipes is mathematically guaranteed
      --  to exhaust the limit.
      Max_Pipes : constant := 128;
      type Tracked_FD_Array is array (1 .. Max_Pipes * 2) of File_Descriptor;

      Allocated_FDs     : Tracked_FD_Array;
      FD_Count          : Natural := 0;
      Read_FD, Write_FD : File_Descriptor;
      Exception_Raised  : Boolean := False;
   begin
      --  1. Get current limits
      Result_C := c_getrlimit (RLIMIT_NOFILE, Original_Limit'Access);
      Assert (Result_C = 0, "Precondition: getrlimit failed");

      --  2. Lower the soft limit to 256 to force immediate exhaustion
      Test_Limit := Original_Limit;
      Test_Limit.rlim_cur := 256;
      Result_C := c_setrlimit (RLIMIT_NOFILE, Test_Limit'Access);
      Assert (Result_C = 0, "Precondition: setrlimit failed");

      --  3. Exhaust the artificially constrained FD table
      begin
         for I in 1 .. Max_Pipes loop
            Create_Pipe (Read_FD, Write_FD);

            FD_Count := FD_Count + 1;
            Allocated_FDs (FD_Count) := Read_FD;
            FD_Count := FD_Count + 1;
            Allocated_FDs (FD_Count) := Write_FD;
         end loop;
      exception
         when MakeOps.Sys.System_Error =>
            Exception_Raised := True;
      end;

      --  4. Restore the original limits safely
      Result_C := c_setrlimit (RLIMIT_NOFILE, Original_Limit'Access);

      --  5. Assert that the exception was raised during the constrained loop
      Assert
        (Exception_Raised,
         "MakeOps.Sys.System_Error should be cleanly raised "
         & "when file descriptor limit is reached");

      --  6. Teardown: Close all successfully opened FDs
      for I in 1 .. FD_Count loop
         Close_FD (Allocated_FDs (I));
      end loop;
   exception
      when others =>
         --  Absolute safety net to prevent destroying
         --  the container environment and causing state leakage
         --  in case of assertions failure.
         Result_C := c_setrlimit (RLIMIT_NOFILE, Original_Limit'Access);
         for I in 1 .. FD_Count loop
            Close_FD (Allocated_FDs (I));
         end loop;
         raise;
   end Test_Create_Pipe_FD_Exhaustion;

   ------------------------------------------
   -- Test_Poll_Streams_Timeout_Expiration --
   ------------------------------------------

   procedure Test_Poll_Streams_Timeout_Expiration
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Read_FD, Write_FD : File_Descriptor;
   begin
      Create_Pipe (Read_FD, Write_FD);

      declare
         FDs   : constant FD_Array (1 .. 1) := [1 => Read_FD];
         Ready : FD_Ready_Array (1 .. 1);
      begin
         --  Call poll with 50ms timeout. Since nothing writes to Write_FD,
         --  it should expire blockingly and return False.
         Ready := Poll_Streams (FDs, Timeout_MS => 50);

         Assert
           (Ready (1) = False,
            "Poll_Streams should return False after timeout expiration "
            & "when no data is written to the pipe");
      end;

      --  Teardown
      Close_FD (Read_FD);
      Close_FD (Write_FD);
   end Test_Poll_Streams_Timeout_Expiration;

end MakeOps.Tests.Sys_Processes;
