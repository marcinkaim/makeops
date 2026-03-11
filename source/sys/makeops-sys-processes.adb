-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

with Interfaces.C;
with Interfaces.C.Strings;
with MakeOps.Sys.Processes.OS_Bindings;

package body MakeOps.Sys.Processes is
   pragma SPARK_Mode (Off);

   use Interfaces.C;
   use MakeOps.Sys.Processes.OS_Bindings;

   -------------------------------------------------------------------------
   --  Linux POSIX Constants
   --  Target: Debian 13 (Trixie) / x86_64
   -------------------------------------------------------------------------

   --  fcntl commands
   F_GETFL : constant int := 3;
   F_SETFL : constant int := 4;

   --  O_NONBLOCK flag (Octal 04000 -> Decimal 2048 on Linux)
   O_NONBLOCK : constant int := 8#4000#;

   -------------------------------------------------------------------------
   --  Process Management Subprograms
   -------------------------------------------------------------------------

   -----------------
   -- Create_Pipe --
   -----------------

   procedure Create_Pipe
     (Read_FD : out File_Descriptor; Write_FD : out File_Descriptor)
   is
      Pipe_FDs : Pipe_Descriptors;
      Result   : int;
      Flags    : int;
   begin
      --  1. Create the anonymous pipe
      Result := c_pipe (Pipe_FDs);
      if Result = -1 then
         raise MakeOps.Sys.System_Error
           with "Fatal OS failure: pipe() returned -1";
      end if;

      --  POSIX pipe() returns read end in index 0, write end in index 1
      Read_FD := File_Descriptor (Pipe_FDs (0));
      Write_FD := File_Descriptor (Pipe_FDs (1));

      --  2. Set the read end to non-blocking mode (O_NONBLOCK)
      --  First, get current flags
      Flags := c_fcntl (int (Read_FD), F_GETFL, 0);
      if Flags /= -1 then
         --  Then, set new flags with O_NONBLOCK bitwise OR-ed
         declare
            New_Flags : constant int :=
              int
                (Interfaces.C.unsigned (Flags)
                 or Interfaces.C.unsigned (O_NONBLOCK));
         begin
            Result := c_fcntl (int (Read_FD), F_SETFL, New_Flags);
         end;

         if Result = -1 then
            --  If fcntl fails, it is a catastrophic system state
            Result := c_close (int (Read_FD));
            Result := c_close (int (Write_FD));
            raise MakeOps.Sys.System_Error
              with "Fatal OS failure: fcntl() returned -1";
         end if;
      end if;
   end Create_Pipe;

   --------------
   -- Close_FD --
   --------------

   procedure Close_FD (FD : File_Descriptor) is
      Result : int;
      pragma Unreferenced (Result);
   begin
      if FD /= Invalid_FD then
         Result := c_close (int (FD));
      --  We explicitly ignore c_close errors. If the file descriptor
      --  is already closed or invalid,
      --  there is no safe or meaningful recovery action.

      end if;
   end Close_FD;

   -----------
   -- Spawn --
   -----------

   function Spawn
     (Command : Path_String;
      Args    : Arg_List;
      FD_Out  : File_Descriptor;
      FD_Err  : File_Descriptor) return Process_ID
   is
      use Interfaces.C.Strings;

      C_Command : chars_ptr := New_String (Path_Strings.To_String (Command));

      --  Array size: Command (1) + Args'Length + Null_Ptr (1)
      Argv_Len : constant size_t := size_t (Args'Length + 2);
      Argv     : chars_ptr_array (size_t (0) .. Argv_Len - 1);

      PID : pid_t;
      Res : int;
      pragma Unreferenced (Res);

      --  Helper to free memory in the parent process
      procedure Free_Argv;

      --  Helper to free memory in the parent process
      procedure Free_Argv is
      begin
         Free (C_Command);
         for I in 1 .. Args'Length loop
            Free (Argv (size_t (I)));
         end loop;
      end Free_Argv;

      --  Locally imported POSIX _exit to safely terminate
      --  the child if execvp fails
      --  Without this, failing execvp would return to
      --  Ada execution flow in two processes!
      procedure Child_Exit (Code : int)
      with Import, Convention => C, External_Name => "_exit";

      --  Locally imported POSIX open for /dev/null handling
      function c_open (pathname : chars_ptr; flags : int) return int
      with Import, Convention => C, External_Name => "open";

      O_WRONLY : constant int := 1;

   begin
      --  1. Prepare Argv array (C ABI requirement)
      Argv (size_t (0)) := C_Command;
      for I in Args'Range loop
         Argv (size_t (I - Args'First + 1)) :=
           New_String (Arg_Strings.To_String (Args (I)));
      end loop;
      Argv (Argv_Len - 1) := Null_Ptr;

      --  2. Fork the process
      PID := c_fork;

      if PID = -1 then
         --  Fork failed
         Free_Argv;
         raise MakeOps.Sys.System_Error
           with "Fatal OS failure: fork() returned -1";

      elsif PID = 0 then
         --  === CHILD PROCESS ===

         --  Rewire stdout (FD 1)
         if FD_Out /= Invalid_FD then
            Res := c_dup2 (int (FD_Out), 1);
         else
            --  Redirect to /dev/null to discard output
            declare
               Dev_Null : constant chars_ptr := New_String ("/dev/null");
               Null_FD  : constant int := c_open (Dev_Null, O_WRONLY);
            begin
               if Null_FD /= -1 then
                  Res := c_dup2 (Null_FD, 1);
                  Res := c_close (Null_FD);
               end if;
               --  No need to free Dev_Null, process will exec or exit
            end;
         end if;

         --  Rewire stderr (FD 2)
         if FD_Err /= Invalid_FD then
            Res := c_dup2 (int (FD_Err), 2);
         end if;

         --  Execute the binary
         Res := c_execvp (C_Command, Argv'Address);

         --  If c_execvp returns, it means it failed catastrophically
         Child_Exit (1);
         return 0; --  Unreachable, but required by Ada semantics

      else
         --  === PARENT PROCESS ===
         Free_Argv;
         return Process_ID (PID);
      end if;
   end Spawn;

   -----------------
   -- Probe_State --
   -----------------

   function Probe_State (PID : Process_ID) return Process_Result is
      --  Linux POSIX WNOHANG flag
      WNOHANG : constant int := 1;

      Status : aliased int := 0;
      Res    : pid_t;
   begin
      --  Invoke waitpid with WNOHANG to check state asynchronously
      Res := c_waitpid (pid_t (PID), Status'Access, WNOHANG);

      if Res = 0 then
         return (State => Running);
      elsif Res < 0 then
         --  waitpid returned -1 (e.g. ECHILD - no such child,
         --  or permissions issue)
         return (State => OS_Error);
      else
         --  The child has terminated,
         --  decode the status bitmask (POSIX glibc mapping)
         declare
            use type Interfaces.Unsigned_32;
            W_Status : constant Interfaces.Unsigned_32 :=
              Interfaces.Unsigned_32 (Status);
            Term_Sig : constant Integer := Integer (W_Status and 16#7F#);
         begin
            if Term_Sig = 0 then
               --  WIFEXITED is true, extract WEXITSTATUS (bits 8-15)
               return
                 (State     => Exited_Normally,
                  Exit_Code =>
                    MakeOps.Sys.Exit_Code
                      (Integer ((W_Status / 256) and 16#FF#)));
            else
               --  WIFSIGNALED is true, extract WTERMSIG (bits 0-6)
               return (State => Killed_By_Signal, Signal_Number => Term_Sig);
            end if;
         end;
      end if;
   end Probe_State;

   -----------------
   -- Send_Signal --
   -----------------

   procedure Send_Signal (PID : Process_ID; Signal : Integer) is
      Res : int;
      pragma Unreferenced (Res);
   begin
      Res := c_kill (pid_t (PID), int (Signal));
      --  We deliberately ignore the return code. If the process has already
      --  terminated (ESRCH), sending the signal correctly had no effect,
      --  so there's no failure on our part.
   end Send_Signal;

   -------------------------------------------------------------------------
   --  I/O Multiplexing Subprograms
   -------------------------------------------------------------------------

   ------------------
   -- Poll_Streams --
   ------------------

   function Poll_Streams
     (FDs : FD_Array; Timeout_MS : Integer) return FD_Ready_Array
   is
      POLLIN : constant short := 1;
      Result : FD_Ready_Array (FDs'Range) := [others => False];
      Res    : int;
   begin
      if FDs'Length = 0 then
         return Result;
      end if;

      declare
         --  Create the C-compatible array of pollfd structures
         Poll_Array : array (0 .. FDs'Length - 1) of aliased struct_pollfd;
      begin
         --  Initialize pollfd structures
         for I in FDs'Range loop
            declare
               Idx : constant Integer := I - FDs'First;
            begin
               Poll_Array (Idx).fd := int (FDs (I));
               Poll_Array (Idx).events := POLLIN;
               Poll_Array (Idx).revents := 0;
            end;
         end loop;

         --  Invoke the POSIX poll system call
         Res :=
           c_poll (Poll_Array (0)'Access, int (FDs'Length), int (Timeout_MS));

         if Res > 0 then
            --  Evaluate which descriptors are ready to be read
            for I in FDs'Range loop
               declare
                  Idx     : constant Integer := I - FDs'First;
                  Revents : constant short := Poll_Array (Idx).revents;
               begin
                  --  If POLLIN is set, or if an error/hangup occurred
                  --  (POLLERR/POLLHUP), we flag it as ready so
                  --  the read() call can either fetch data or
                  --  gracefully discover the EOF/Error state.
                  if Revents /= 0 then
                     Result (I) := True;
                  end if;
               end;
            end loop;
         end if;
      end;

      return Result;
   end Poll_Streams;

   -----------------------
   -- Read_Stream_Chunk --
   -----------------------

   function Read_Stream_Chunk (FD : File_Descriptor) return Stream_Result is
      --  We use a standard String as our Raw Byte Bucket (PLAT-011)
      Buffer     : aliased String (1 .. Max_Stream_Chunk_Length) :=
        [others => ASCII.NUL];
      Bytes_Read : ssize_t;
   begin
      --  Invoke POSIX read via Thin Binding
      Bytes_Read :=
        c_read
          (fd    => int (FD),
           buf   => Buffer'Address,
           count => size_t (Max_Stream_Chunk_Length));

      if Bytes_Read > 0 then
         --  Data successfully read
         return
           (Status => Data_Available,
            Chunk  =>
              Chunk_Strings.To_Bounded_String
                (Buffer (1 .. Integer (Bytes_Read))));

      elsif Bytes_Read = 0 then
         --  End of file reached (the write end of the pipe was closed)
         return (Status => End_Of_File);

      else
         --  Bytes_Read < 0. Since the pipe is strictly O_NONBLOCK,
         --  this typically means EAGAIN (no data currently available).
         --  Instead of raising exceptions, we gracefully degrade to Empty.
         return (Status => Empty);
      end if;
   end Read_Stream_Chunk;

end MakeOps.Sys.Processes;
