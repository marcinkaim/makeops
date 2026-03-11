-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

with Interfaces.C;
with Interfaces.C.Strings;
with System;

private package MakeOps.Sys.Processes.OS_Bindings is
   pragma SPARK_Mode (Off);

   use Interfaces.C;

   -------------------------------------------------------------------------
   --  POSIX Types & Structures
   -------------------------------------------------------------------------

   --  Mapping for POSIX ssize_t (used by read)
   type ssize_t is new Interfaces.C.ptrdiff_t;

   --  Mapping for POSIX pid_t (used by fork, waitpid, kill)
   type pid_t is new Interfaces.C.int;

   --  Array type to hold the two file descriptors returned by pipe()
   type Pipe_Descriptors is array (0 .. 1) of aliased Interfaces.C.int;
   pragma Convention (C, Pipe_Descriptors);

   --  Mapping for the POSIX struct pollfd
   type struct_pollfd is record
      fd      : Interfaces.C.int;
      events  : Interfaces.C.short;
      revents : Interfaces.C.short;
   end record;
   pragma Convention (C, struct_pollfd);

   -------------------------------------------------------------------------
   --  Thin bindings to standard POSIX functions (glibc)
   -------------------------------------------------------------------------

   --  int pipe(int pipefd[2]);
   function c_pipe (pipefd : out Pipe_Descriptors) return Interfaces.C.int;
   pragma Import (C, c_pipe, "pipe");

   --  pid_t fork(void);
   function c_fork return pid_t;
   pragma Import (C, c_fork, "fork");

   --  int execvp(const char *file, char *const argv[]);
   --  We use System.Address for the argv array
   --  to pass chars_ptr_array cleanly.
   function c_execvp
     (file : Interfaces.C.Strings.chars_ptr; argv : System.Address)
      return Interfaces.C.int;
   pragma Import (C, c_execvp, "execvp");

   --  int dup2(int oldfd, int newfd);
   function c_dup2
     (oldfd : Interfaces.C.int; newfd : Interfaces.C.int)
      return Interfaces.C.int;
   pragma Import (C, c_dup2, "dup2");

   --  int fcntl(int fd, int cmd, int arg);
   function c_fcntl
     (fd : Interfaces.C.int; cmd : Interfaces.C.int; arg : Interfaces.C.int)
      return Interfaces.C.int;
   pragma Import (C, c_fcntl, "fcntl");

   --  int poll(struct pollfd *fds, nfds_t nfds, int timeout);
   function c_poll
     (fds     : access struct_pollfd;
      nfds    : Interfaces.C.int;
      timeout : Interfaces.C.int) return Interfaces.C.int;
   pragma Import (C, c_poll, "poll");

   --  ssize_t read(int fd, void *buf, size_t count);
   function c_read
     (fd : Interfaces.C.int; buf : System.Address; count : Interfaces.C.size_t)
      return ssize_t;
   pragma Import (C, c_read, "read");

   --  pid_t waitpid(pid_t pid, int *wstatus, int options);
   function c_waitpid
     (pid     : pid_t;
      wstatus : access Interfaces.C.int;
      options : Interfaces.C.int) return pid_t;
   pragma Import (C, c_waitpid, "waitpid");

   --  int kill(pid_t pid, int sig);
   function c_kill
     (pid : pid_t; sig : Interfaces.C.int) return Interfaces.C.int;
   pragma Import (C, c_kill, "kill");

   --  int close(int fd);
   function c_close (fd : Interfaces.C.int) return Interfaces.C.int;
   pragma Import (C, c_close, "close");

end MakeOps.Sys.Processes.OS_Bindings;
