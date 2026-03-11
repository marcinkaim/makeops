-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--  MakeOps.Sys.Terminal
--  Terminal Standard Streams Facade
--
--  This package serves as the safe, exception-free OS adapter for
--  terminal standard streams (stdout and stderr).
-------------------------------------------------------------------------------

package MakeOps.Sys.Terminal is
   pragma SPARK_Mode (On);

   --  Defines the destination stream for the output.
   type Stream_Target is (Standard_Output, Standard_Error);

   --  Writes the text to the specified stream without appending
   --  a newline character. Guarantees Absence of Runtime Errors (AoRE).
   procedure Print (Text : String; Target : Stream_Target);

   --  Writes the text to the specified stream and appends
   --  a newline character. Guarantees Absence of Runtime Errors (AoRE).
   procedure Print_Line (Text : String; Target : Stream_Target);

end MakeOps.Sys.Terminal;
