-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--  MakeOps.Core.TOML.Lexer
--  Event-Driven TOML Lexical Analyzer
--
--  This package serves as the stateless, zero-allocation lexical analyzer
--  for the MakeOps TOML Dialect. It pushes parsed events to subscribers
--  implementing the Lexer_Listener interface.
-------------------------------------------------------------------------------

package MakeOps.Core.TOML.Lexer
  with SPARK_Mode => On, Preelaborate
is

   -------------------------------------------------------------------------
   --  Lexer State (Data-Driven FSM)
   -------------------------------------------------------------------------

   --  The internal deterministic state machine memory of the parsing process.
   --  It is completely private to prevent unauthorized mutations outside
   --  the bounds of the SPARK flow contracts.
   type State is private;

   function Is_In_Array_Mode (Lexer_State : State) return Boolean
   with Ghost, Global => null;

   function Get_Array_Start_Line
     (Lexer_State : State) return MakeOps.Core.TOML.Line_Number
   with Ghost, Global => null;

   function Get_Array_Start_Column
     (Lexer_State : State) return MakeOps.Core.TOML.Column_Number
   with Ghost, Global => null;

   --  Returns a clean, reset state record. Allows the orchestrator to reuse
   --  the lexer for multiple files sequentially.
   function Initial_State return State
   with
     Global => null, -- Strictly guarantees no hidden side-effects
     Post   =>
       not Is_In_Array_Mode (Initial_State'Result)
       and Get_Array_Start_Line (Initial_State'Result) = 1
       and Get_Array_Start_Column (Initial_State'Result) = 1;

   -------------------------------------------------------------------------
   --  Execution Primitives
   -------------------------------------------------------------------------

   --  The core push-based execution unit.
   --  Accepts a raw TOML line and dispatches events to the Listener.
   procedure Process_Line
     (Lexer_State : in out State;
      Line        : MakeOps.Core.TOML.TOML_Line;
      Line_Num    : MakeOps.Core.TOML.Line_Number;
      Listener    : in out MakeOps.Core.TOML.Lexer_Listener'Class;
      Result      : out MakeOps.Core.TOML.Lexical_Result)
   with
     --  Guarantee that this procedure relies strictly on its parameters.
     Global  => null,
     Pre     => not Result'Constrained and then Line'Last < Integer'Last,
     Post    =>
       (if not Result.Success then Result.Line = Line_Num)
       and then
         (if Is_In_Array_Mode (Lexer_State)
          then
            (if Is_In_Array_Mode (Lexer_State'Old)
             then
               Get_Array_Start_Line (Lexer_State)
               = Get_Array_Start_Line (Lexer_State'Old)
               and
                 Get_Array_Start_Column (Lexer_State)
                 = Get_Array_Start_Column (Lexer_State'Old)
             else Get_Array_Start_Line (Lexer_State) = Line_Num)),

     --  Strict Data Flow dependencies:
     --  1. Lexer_State may change based on the processed line.
     --  2. Listener callbacks depend on the current state and line contents.
     --  3. Result (Success/Error) depends on
     --     the exact line structure and state.
     Depends =>
       (Lexer_State => (Lexer_State, Line, Line_Num),
        Listener    => (Listener, Lexer_State, Line, Line_Num),
        Result      => (Lexer_State, Line, Line_Num));

   --  Invoked by the orchestrator upon reaching the End-Of-File (EOF).
   --  Validates that the state machine is not left in an invalid state
   --  (e.g., an unclosed array) and triggers the On_End_Of_File event.
   procedure Finish
     (Lexer_State : in State;
      Listener    : in out MakeOps.Core.TOML.Lexer_Listener'Class;
      Result      : out MakeOps.Core.TOML.Lexical_Result)
   with
     Global  => null,
     Pre     => not Result'Constrained,
     Post    =>
       (if Is_In_Array_Mode (Lexer_State)
        then
          not Result.Success
          and Result.Error_Type = MakeOps.Core.TOML.Unclosed_Array
          and Result.Line = Get_Array_Start_Line (Lexer_State)
          and Result.Column = Get_Array_Start_Column (Lexer_State)
        else Result.Success),

     --  Data Flow guarantees that Finish operates only on what remains
     --  in the state, not on new textual inputs.
     Depends => (Listener => (Listener, Lexer_State), Result => Lexer_State);

private

   --  The internal physical representation of the FSM.
   --  It intentionally DOES NOT store the TOML_Lexeme (String) to maintain
   --  the Zero-Allocation and Bounded State constraints. The subscriber
   --  (Listener) is responsible for retaining keys across multiple lines.
   type State is record
      In_Array_Mode : Boolean := False;

      --  Spatial coordinates are retained to provide pinpoint accuracy
      --  for errors that span multiple lines (e.g., Unclosed_Array at EOF).
      Array_Start_Line   : MakeOps.Core.TOML.Line_Number := 1;
      Array_Start_Column : MakeOps.Core.TOML.Column_Number := 1;
   end record;

   function Is_In_Array_Mode (Lexer_State : State) return Boolean
   is (Lexer_State.In_Array_Mode);

   function Get_Array_Start_Line
     (Lexer_State : State) return MakeOps.Core.TOML.Line_Number
   is (Lexer_State.Array_Start_Line);

   function Get_Array_Start_Column
     (Lexer_State : State) return MakeOps.Core.TOML.Column_Number
   is (Lexer_State.Array_Start_Column);

end MakeOps.Core.TOML.Lexer;
