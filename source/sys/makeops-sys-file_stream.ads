-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--  MakeOps.Sys.File_Stream
--  File Stream Facade
--
--  This package serves as the safe, exception-free OS adapter for reading
--  text files line-by-line. It ensures strictly bounded memory usage and
--  Absence of Runtime Errors (AoRE).
-------------------------------------------------------------------------------

with Ada.Strings.Bounded;
private with Ada.Text_IO;

package MakeOps.Sys.File_Stream is
   pragma SPARK_Mode (On);

   --  Maximum byte length of a single line parsed from configuration files
   Max_Line_Length : constant := 8192;

   --  Bounded string type representing a raw, UTF-8 line buffer
   package Line_Strings is new
     Ada.Strings.Bounded.Generic_Bounded_Length (Max => Max_Line_Length);

   subtype Line_String is Line_Strings.Bounded_String;

   --  Enumeration representing the deterministic outcome of I/O operations
   type Stream_Status is (Success, End_Of_File, I_O_Error);

   --  Discriminated variant record parameterized by Stream_Status.
   --  Provides a safe, exception-free mechanism for returning read outcomes.
   type Read_Result (Status : Stream_Status) is record
      case Status is
         when Success =>
            Line : Line_String;

         when End_Of_File | I_O_Error =>
            null;
      end case;
   end record;

   --  A limited private type safely encapsulating the internal file type
   --  preventing the core logic from interacting directly with native streams.
   type File_Handle is limited private;

   -------------------------------------------------------------------------
   --  Safe File Streaming Operations
   -------------------------------------------------------------------------

   --  Opens a file at the given path for reading text line-by-line.
   --  Returns a Stream_Status indicating if the file was successfully opened.
   procedure Open_File
     (Path   : Path_String;
      Handle : in out File_Handle;
      Status : out Stream_Status);

   --  Reads the stream until a newline character is encountered.
   --  Returns a Read_Result indicating Success (with bounded string data),
   --  End_Of_File, or I_O_Error.
   function Get_Next_Line (Handle : File_Handle) return Read_Result;

   --  Safely closes the file. The caller must guarantee that this is invoked
   --  if Open_File returned Success.
   procedure Close_File (Handle : in out File_Handle);

private

   --  The internal implementation relies on Ada.Text_IO. To satisfy SPARK
   --  contracts without exposing native unprovable I/O side effects to the
   --  public specification, we encapsulate it here.
   type File_Handle is limited record
      File    : Ada.Text_IO.File_Type;
      Is_Open : Boolean := False;
   end record;

end MakeOps.Sys.File_Stream;
