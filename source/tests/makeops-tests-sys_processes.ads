-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

with AUnit.Test_Cases;

package MakeOps.Tests.Sys_Processes is

   --  Test case encapsulating all tests for MakeOps.Sys.Processes
   type Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   procedure Register_Tests (T : in out Test_Case);
   function Name (T : Test_Case) return AUnit.Message_String;

   -------------------------------------------------------------------------
   --  Test Scenarios for MakeOps.Sys.Processes
   -------------------------------------------------------------------------

   --  Create_Pipe & Close_FD tests
   procedure Test_Pipe_Lifecycle_Success
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Close_Invalid_FD
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   --  Spawn tests
   procedure Test_Spawn_Valid_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Spawn_Execvp_Failure
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   --  Probe_State tests
   procedure Test_Probe_State_Normal_Exit
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Probe_State_Invalid_PID
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   --  Send_Signal tests
   procedure Test_Send_Signal_Kill
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Send_Signal_Dead_Process
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   --  I/O Multiplexing (Poll_Streams & Read_Stream_Chunk) tests
   procedure Test_IO_Multiplexing_Data_Flow
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_IO_Non_Blocking_Empty_And_EOF
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   --  Additional Edge Cases & Integrations
   procedure Test_Spawn_No_Arguments
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Spawn_Asymmetric_Streams
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Poll_Streams_Zero_Timeout
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Spawn_Max_Arguments
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Poll_Streams_Empty_Array
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   --  Deep Edge Cases & Resiliency
   procedure Test_Probe_State_Signaled_Exit
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Read_Stream_Invalid_FD
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_IO_Multiplexing_Large_Payload
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Poll_Streams_Invalid_FD
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Spawn_Max_Arg_Length
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   --  POSIX Boundary & Semantic Validations
   procedure Test_Probe_State_Non_Zero_Exit
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Create_Pipe_FD_Exhaustion
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Poll_Streams_Timeout_Expiration
     (T : in out AUnit.Test_Cases.Test_Case'Class);

end MakeOps.Tests.Sys_Processes;
