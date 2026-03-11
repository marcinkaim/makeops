-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

with Ada.Text_IO;

package body MakeOps.Sys.Terminal is
   --  Must be turned off as native I/O operations and exception handling
   --  break the strict Absence of Runtime Errors (AoRE) mathematical proofs.
   pragma SPARK_Mode (Off);

   -----------
   -- Print --
   -----------

   procedure Print (Text : String; Target : Stream_Target) is
   begin
      case Target is
         when Standard_Output =>
            Ada.Text_IO.Put (Ada.Text_IO.Current_Output, Text);
            Ada.Text_IO.Flush (Ada.Text_IO.Current_Output);

         when Standard_Error  =>
            Ada.Text_IO.Put (Ada.Text_IO.Current_Error, Text);
            Ada.Text_IO.Flush (Ada.Text_IO.Current_Error);
      end case;
   exception
      when others =>
         --  Trap Ada.Text_IO.Device_Error, Use_Error, etc.
         --  If the OS pipe is broken (e.g., SIGPIPE context) or the terminal
         --  is detached, we silently ignore the failure to preserve the
         --  exception-free boundary contract.
         null;
   end Print;

   ----------------
   -- Print_Line --
   ----------------

   procedure Print_Line (Text : String; Target : Stream_Target) is
   begin
      case Target is
         when Standard_Output =>
            Ada.Text_IO.Put_Line (Ada.Text_IO.Current_Output, Text);
            Ada.Text_IO.Flush (Ada.Text_IO.Current_Output);

         when Standard_Error  =>
            Ada.Text_IO.Put_Line (Ada.Text_IO.Current_Error, Text);
            Ada.Text_IO.Flush (Ada.Text_IO.Current_Error);
      end case;
   exception
      when others =>
         --  Trap Ada.Text_IO.Device_Error, Use_Error, etc.
         null;
   end Print_Line;

end MakeOps.Sys.Terminal;
