-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--  MakeOps.Core.TOML
--  MakeOps TOML Dialect Domain Dictionary
--
--  This package serves as the base namespace, domain dictionary, and contract
--  definition for the MakeOps TOML Dialect. It enforces the Zero-Allocation
--  paradigm and defines the Event-Driven subscriber interface.
-------------------------------------------------------------------------------

package MakeOps.Core.TOML
  with SPARK_Mode => On, Preelaborate
is

   -------------------------------------------------------------------------
   --  Spatial Coordinates
   -------------------------------------------------------------------------

   --  A strongly-typed positive integer used to track spatial positions.
   --  This inherently acts as a SPARK contract guaranteeing that coordinates
   --  are always >= 1.
   type Coordinate_Type is new Positive;

   subtype Line_Number is Coordinate_Type;
   subtype Column_Number is Coordinate_Type;

   -------------------------------------------------------------------------
   --  Text Encoding Model (Zero-Allocation)
   -------------------------------------------------------------------------

   --  Represents a full raw line of text injected into the parser.
   subtype TOML_Line is String;

   --  Represents a zero-allocation slice of text (e.g., a key or value)
   --  extracted directly from the TOML_Line buffer.
   subtype TOML_Lexeme is String;

   -------------------------------------------------------------------------
   --  Lexical Errors & Results
   -------------------------------------------------------------------------

   --  Enumeration detailing specific violations of the MakeOps TOML dialect.
   type Syntax_Error_Type is
     (None,
      Malformed_Section_Header,
      Unsupported_Value_Type,
      Unrecognized_Statement,
      Unclosed_Array);

   --  Deterministic variant record returning either Success or an Error
   --  paired with its exact spatial coordinates. Enforces Fail-Fast checks.
   type Lexical_Result (Success : Boolean := True) is record
      case Success is
         when True =>
            null;

         when False =>
            Error_Type : Syntax_Error_Type;
            Line       : Line_Number;
            Column     : Column_Number;
      end case;
   end record;

   -------------------------------------------------------------------------
   --  Event-Driven Architecture (SAX-like Interface)
   -------------------------------------------------------------------------

   --  Abstract interface representing a subscriber to lexical events.
   type Lexer_Listener is interface;

   --  Invoked when a valid [section] header is parsed.
   procedure On_Section_Found
     (Listener : in out Lexer_Listener;
      Name     : TOML_Lexeme;
      Line     : Line_Number;
      Column   : Column_Number)
   is abstract;

   --  Invoked when a standard key-value pair is parsed.
   procedure On_String_Value_Found
     (Listener : in out Lexer_Listener;
      Key      : TOML_Lexeme;
      Value    : TOML_Lexeme;
      Line     : Line_Number;
      Column   : Column_Number)
   is abstract;

   --  Invoked when the opening bracket of an array is encountered.
   procedure On_Array_Start
     (Listener : in out Lexer_Listener;
      Key      : TOML_Lexeme;
      Line     : Line_Number;
      Column   : Column_Number)
   is abstract;

   --  Invoked for each valid string element within an array.
   procedure On_Array_Item
     (Listener : in out Lexer_Listener;
      Value    : TOML_Lexeme;
      Line     : Line_Number;
      Column   : Column_Number)
   is abstract;

   --  Invoked when the closing bracket of an array is encountered.
   procedure On_Array_End
     (Listener : in out Lexer_Listener;
      Line     : Line_Number;
      Column   : Column_Number)
   is abstract;

   --  Invoked when the stream concludes successfully.
   procedure On_End_Of_File (Listener : in out Lexer_Listener) is abstract;

end MakeOps.Core.TOML;
