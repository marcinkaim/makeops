-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--  MakeOps.Core.TOML.Lexer.Standard_Mode
--  FSM State Handler for Standard TOML Lines
--
--  This private child package encapsulates the line-parsing logic when the
--  Lexer is in its default state (not inside an array block). It implements
--  a flat, character-by-character Finite State Machine (Micro-FSM) to emit
--  events for sections and key-value assignments. It can also transition the
--  global Lexer_State into Array Mode.
-------------------------------------------------------------------------------

private package MakeOps.Core.TOML.Lexer.Standard_Mode
  with SPARK_Mode => On, Preelaborate
is

   -------------------------------------------------------------------------
   --  Execution Primitive
   -------------------------------------------------------------------------

   --  Processes a single line of TOML using a flat character-level FSM.
   --  May mutate Lexer_State to enter Array_Mode if `[` is encountered
   --  as a value in a Key-Value pair.
   procedure Process_Line
     (Lexer_State : in out State;
      Line        : MakeOps.Core.TOML.TOML_Line;
      Line_Num    : MakeOps.Core.TOML.Line_Number;
      Listener    : in out MakeOps.Core.TOML.Lexer_Listener'Class;
      Result      : out MakeOps.Core.TOML.Lexical_Result)
   with
     Global  => null,
     Pre     =>
       not Result'Constrained
       and then not Lexer_State.In_Array_Mode
       and then Line'Last < Integer'Last
       and then Line'Length > 0,
     Post    =>
       (if not Result.Success then Result.Line = Line_Num)
       and then
         (if Lexer_State.In_Array_Mode
          then Lexer_State.Array_Start_Line = Line_Num),

     --  Strict Data Flow dependencies for SPARK:
     --  Lexer_State might be updated (e.g., entering Array Mode).
     --  Listener events and Result status depend solely on the line content.
     Depends =>
       (Lexer_State => (Lexer_State, Line, Line_Num),
        Listener    => (Listener, Line, Line_Num),
        Result      => (Line, Line_Num));

end MakeOps.Core.TOML.Lexer.Standard_Mode;
