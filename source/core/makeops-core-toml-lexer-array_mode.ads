-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--  MakeOps.Core.TOML.Lexer.Array_Mode
--  FSM State Handler for TOML Array Blocks
--
--  This private child package encapsulates the line-parsing logic when the
--  Lexer is currently inside an array assignment (In_Array_Mode = True).
--  It implements a flat, character-by-character Finite State Machine to
--  extract array elements, handle commas, and transition the Lexer_State
--  back to the standard mode upon encountering the closing bracket `]`.
-------------------------------------------------------------------------------

private package MakeOps.Core.TOML.Lexer.Array_Mode
  with SPARK_Mode => On, Preelaborate
is

   -------------------------------------------------------------------------
   --  Execution Primitive
   -------------------------------------------------------------------------

   --  Processes a single line of TOML using a flat character-level FSM
   --  tailored for array contents. Mutates Lexer_State to exit Array_Mode
   --  if `]` is successfully reached.
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
       and then Lexer_State.In_Array_Mode
       and then Line'Last < Integer'Last
       and then Line'Length > 0,
     Post    =>
       (if not Result.Success then Result.Line = Line_Num)
       and then
         (if Lexer_State.In_Array_Mode
          then
            Lexer_State.Array_Start_Line = Lexer_State'Old.Array_Start_Line
            and
              Lexer_State.Array_Start_Column
              = Lexer_State'Old.Array_Start_Column),

     --  Strict Data Flow dependencies for SPARK:
     --  Lexer_State might be updated (e.g., exiting Array Mode).
     --  Listener events (On_Array_Item, On_Array_End) and Result status
     --  depend solely on the line content and the line number.
     Depends =>
       (Lexer_State => (Lexer_State, Line),
        Listener    => (Listener, Line, Line_Num),
        Result      => (Line, Line_Num));

end MakeOps.Core.TOML.Lexer.Array_Mode;
