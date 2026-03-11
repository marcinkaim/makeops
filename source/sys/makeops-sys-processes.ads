-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--  MakeOps.Sys.Processes
--  Process and IPC Lifecycle Management Facade
--
--  This package serves as the authoritative, pure-execution, safe adapter
--  for spawning, monitoring, and reaping operating system processes.
--  It acts as a Thick Wrapper around unsafe POSIX C bindings.
-------------------------------------------------------------------------------

with Ada.Strings.Bounded;

package MakeOps.Sys.Processes is
   pragma SPARK_Mode (On);

   -------------------------------------------------------------------------
   --  Constants & Bounded Types (Static Memory Model)
   -------------------------------------------------------------------------

   --  Maximum byte length of a single evaluated argument
   Max_Arg_Length : constant := 1024;

   --  Maximum number of arguments per execution
   Max_Args_Per_Command : constant := 32;

   --  Bounded string type for storing command arguments
   package Arg_Strings is new
     Ada.Strings.Bounded.Generic_Bounded_Length (Max => Max_Arg_Length);
   subtype Arg_String is Arg_Strings.Bounded_String;

   --  Array of arguments to be passed to the spawned process
   type Arg_List is array (Positive range <>) of Arg_String
   with Dynamic_Predicate => Arg_List'Length <= Max_Args_Per_Command;

   --  Maximum buffer length for a single stream read chunk
   Max_Stream_Chunk_Length : constant := 4096;

   package Chunk_Strings is new
     Ada.Strings.Bounded.Generic_Bounded_Length
       (Max => Max_Stream_Chunk_Length);
   subtype Chunk_String is Chunk_Strings.Bounded_String;

   -------------------------------------------------------------------------
   --  Core Domain Types
   -------------------------------------------------------------------------

   --  Strongly typed integer representing the OS process identifier (PID)
   type Process_ID is new Integer;

   --  Strongly typed integer representing an open OS file descriptor
   type File_Descriptor is new Integer;

   --  Static constant representing an unassigned or closed pipe
   Invalid_FD : constant File_Descriptor := -1;

   --  Array types for polling multiple file descriptors
   type FD_Array is array (Positive range <>) of File_Descriptor;
   type FD_Ready_Array is array (Positive range <>) of Boolean;

   -------------------------------------------------------------------------
   --  Process Lifecycle States & Results
   -------------------------------------------------------------------------

   --  Enumeration representing the instantaneous state of a child process
   type Process_State is
     (Running, Exited_Normally, Killed_By_Signal, OS_Error);

   --  Discriminated variant record securely holding the execution result
   type Process_Result (State : Process_State := Running) is record
      case State is
         when Exited_Normally =>
            Exit_Code : MakeOps.Sys.Exit_Code;

         when Killed_By_Signal =>
            Signal_Number : Integer;

         when Running | OS_Error =>
            null;
      end case;
   end record;

   -------------------------------------------------------------------------
   --  Stream I/O States & Results
   -------------------------------------------------------------------------

   --  Enumeration representing the outcome of a non-blocking stream read
   type Stream_Status is (Data_Available, End_Of_File, Empty);

   --  Discriminated variant record containing the stream read status and data
   type Stream_Result (Status : Stream_Status := Empty) is record
      case Status is
         when Data_Available =>
            Chunk : Chunk_String;

         when End_Of_File | Empty =>
            null;
      end case;
   end record;

   -------------------------------------------------------------------------
   --  Process Management Subprograms
   -------------------------------------------------------------------------

   --  Creates an anonymous pipe.
   --  Returns a reading and writing File_Descriptor pair.
   --  The read-end is implicitly set to O_NONBLOCK.
   procedure Create_Pipe
     (Read_FD : out File_Descriptor; Write_FD : out File_Descriptor);

   --  Ensures the safe, deterministic closure of a file descriptor.
   procedure Close_FD (FD : File_Descriptor);

   --  Executes fork and execvp. Rewires streams to the provided FDs,
   --  and returns the child's Process_ID.
   function Spawn
     (Command : Path_String;
      Args    : Arg_List;
      FD_Out  : File_Descriptor;
      FD_Err  : File_Descriptor) return Process_ID;

   --  Wraps waitpid with WNOHANG. Returns the instantaneous state
   --  of the child without blocking the calling thread.
   function Probe_State (PID : Process_ID) return Process_Result;

   --  Wraps the POSIX kill function to send a specific signal (e.g., SIGKILL)
   --  to a Process_ID.
   procedure Send_Signal (PID : Process_ID; Signal : Integer);

   -------------------------------------------------------------------------
   --  I/O Multiplexing Subprograms
   -------------------------------------------------------------------------

   --  Wraps the POSIX poll function. Accepts an array of File_Descriptors
   --  and a timeout (in milliseconds). Returns an array of booleans indicating
   --  which FDs are ready for reading.
   function Poll_Streams
     (FDs : FD_Array; Timeout_MS : Integer) return FD_Ready_Array
   with Post => Poll_Streams'Result'Length = FDs'Length;

   --  Wraps non-blocking read. Fetches available data from a File_Descriptor
   --  into a safe Stream_Result variant record.
   function Read_Stream_Chunk (FD : File_Descriptor) return Stream_Result;

end MakeOps.Sys.Processes;
