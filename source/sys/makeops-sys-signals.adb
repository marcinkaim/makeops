-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

with Ada.Interrupts.Names;

package body MakeOps.Sys.Signals is

   --  We disable SPARK verification for the body because hardware interrupts
   --  and native pragmas break the strict, deterministic mathematical models
   --  required by GNATprove.
   pragma SPARK_Mode (Off);

   -------------------------------------------------------------------------
   --  Protected Object: Signal_Handler
   --  Encapsulates the asynchronous abort flag, ensuring thread-safe,
   --  atomic read and write operations without race conditions.
   -------------------------------------------------------------------------

   protected Signal_Handler is
      --  Handler for Ctrl+C (Interrupt)
      procedure Handle_SIGINT;
      pragma Attach_Handler (Handle_SIGINT, Ada.Interrupts.Names.SIGINT);

      --  Handler for Termination request (e.g., from 'kill' command)
      procedure Handle_SIGTERM;
      pragma Attach_Handler (Handle_SIGTERM, Ada.Interrupts.Names.SIGTERM);

      --  Thread-safe getter for the abort status
      function Get_Status return Boolean;
   private
      Is_Aborted : Boolean := False;
   end Signal_Handler;

   protected body Signal_Handler is

      -------------------
      -- Handle_SIGINT --
      -------------------

      procedure Handle_SIGINT is
      begin
         --  Asynchronously flip the abort flag when the OS delivers SIGINT
         Is_Aborted := True;
      end Handle_SIGINT;

      --------------------
      -- Handle_SIGTERM --
      --------------------

      procedure Handle_SIGTERM is
      begin
         --  Asynchronously flip the abort flag when the OS delivers SIGTERM
         Is_Aborted := True;
      end Handle_SIGTERM;

      ----------------
      -- Get_Status --
      ----------------

      function Get_Status return Boolean is
      begin
         --  Safe, locked read of the internal flag
         return Is_Aborted;
      end Get_Status;

   end Signal_Handler;

   ---------------------
   -- Abort_Requested --
   ---------------------

   function Abort_Requested return Boolean is
   begin
      --  Simply delegate the call to the protected object's getter,
      --  keeping the concurrency mechanism fully hidden
      --  from the outside world.
      return Signal_Handler.Get_Status;
   end Abort_Requested;

end MakeOps.Sys.Signals;
