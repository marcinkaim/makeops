-------------------------------------------------------------------------------
--  MakeOps
--  Copyright (C) 2026 Marcin Kaim
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------

--  The body interacts with the OS through native unprovable I/O side effects,
--  therefore it must be excluded from static proof. All native exceptions
--  must be captured and translated to safe return types.
pragma SPARK_Mode (Off);

package body MakeOps.Sys.File_Stream is

   -------------------------------------------------------------------------
   --  Open_File
   -------------------------------------------------------------------------
   procedure Open_File
     (Path   : Path_String;
      Handle : in out File_Handle;
      Status : out Stream_Status)
   is
      --  Extract standard String from the Bounded_String for Ada.Text_IO
      Path_Str : constant String := Path_Strings.To_String (Path);
   begin
      --  Fail-fast if the handle is already open to prevent descriptor leaks
      if Handle.Is_Open then
         Status := I_O_Error;
         return;
      end if;

      Ada.Text_IO.Open
        (File => Handle.File, Mode => Ada.Text_IO.In_File, Name => Path_Str);

      Handle.Is_Open := True;
      Status := Success;
   exception
      --  Map standard OS/File exceptions to our deterministic Stream_Status
      when Ada.Text_IO.Name_Error | Ada.Text_IO.Use_Error =>
         Status := I_O_Error;
      when others =>
         Status := I_O_Error;
   end Open_File;

   -------------------------------------------------------------------------
   --  Get_Next_Line
   -------------------------------------------------------------------------
   function Get_Next_Line (Handle : File_Handle) return Read_Result is
      Buffer : String (1 .. Max_Line_Length);
      Last   : Natural := 0;
   begin
      if not Handle.Is_Open then
         return (Status => I_O_Error);
      end if;

      if Ada.Text_IO.End_Of_File (Handle.File) then
         return (Status => End_Of_File);
      end if;

      Ada.Text_IO.Get_Line (Handle.File, Buffer, Last);

      --  If the line exceeds or exactly matches Max_Line_Length,
      --  Get_Line fills the buffer but may leave the line terminator
      --  (or remainder of the line) unconsumed.
      --  We must flush the stream to the next line to prevent
      --  misalignment during the next read operation.
      if Last = Buffer'Last then
         if not Ada.Text_IO.End_Of_File (Handle.File) then
            Ada.Text_IO.Skip_Line (Handle.File);
         end if;
      end if;

      return
        (Status => Success,
         Line   => Line_Strings.To_Bounded_String (Buffer (1 .. Last)));
   exception
      when Ada.Text_IO.End_Error =>
         return (Status => End_Of_File);
      when others =>
         return (Status => I_O_Error);
   end Get_Next_Line;

   -------------------------------------------------------------------------
   --  Close_File
   -------------------------------------------------------------------------
   procedure Close_File (Handle : in out File_Handle) is
   begin
      if Handle.Is_Open then
         Ada.Text_IO.Close (Handle.File);
         Handle.Is_Open := False;
      end if;
   exception
      when others =>
         --  Even if closing fails at the OS level, we conceptually mark
         --  the file as closed to prevent further operations.
         Handle.Is_Open := False;
   end Close_File;

end MakeOps.Sys.File_Stream;
