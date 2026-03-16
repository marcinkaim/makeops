-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

with MakeOps.Core.TOML.Lexer.Standard_Mode;
with MakeOps.Core.TOML.Lexer.Array_Mode;

package body MakeOps.Core.TOML.Lexer
  with SPARK_Mode => On
is

   -------------------------------------------------------------------------
   --  Initial_State
   -------------------------------------------------------------------------
   function Initial_State return State is
   begin
      --  Returns a deterministically clean FSM state.
      return
        State'
          (In_Array_Mode      => False,
           Array_Start_Line   => 1,
           Array_Start_Column => 1);
   end Initial_State;

   -------------------------------------------------------------------------
   --  Finish
   -------------------------------------------------------------------------
   procedure Finish
     (Lexer_State : in State;
      Listener    : in out Lexer_Listener'Class;
      Result      : out Lexical_Result) is
   begin
      --  If the file ends while we are still inside an array block,
      --  it is a critical dialect violation (Unclosed Array).
      if Lexer_State.In_Array_Mode then
         Result :=
           (Success    => False,
            Error_Type => Unclosed_Array,
            Line       => Lexer_State.Array_Start_Line,
            Column     => Lexer_State.Array_Start_Column);
      else
         Result := (Success => True);
         Listener.On_End_Of_File;
      end if;
   end Finish;

   -------------------------------------------------------------------------
   --  Process_Line
   -------------------------------------------------------------------------
   procedure Process_Line
     (Lexer_State : in out State;
      Line        : TOML_Line;
      Line_Num    : Line_Number;
      Listener    : in out Lexer_Listener'Class;
      Result      : out Lexical_Result) is
   begin
      --  1. SPARK Requirement: Strict initialization of out parameters.
      Result := (Success => True);

      --  2. Safe guard against completely empty slices.
      if Line'Length = 0 then
         return;
      end if;

      --  3. Macro-FSM State Dispatcher
      --  Delegate the character-by-character parsing to
      --  the appropriate Micro-FSM
      if Lexer_State.In_Array_Mode then
         Array_Mode.Process_Line
           (Lexer_State => Lexer_State,
            Line        => Line,
            Line_Num    => Line_Num,
            Listener    => Listener,
            Result      => Result);
      else
         Standard_Mode.Process_Line
           (Lexer_State => Lexer_State,
            Line        => Line,
            Line_Num    => Line_Num,
            Listener    => Listener,
            Result      => Result);
      end if;
   end Process_Line;

end MakeOps.Core.TOML.Lexer;
