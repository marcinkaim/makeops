<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# ALG-010 Contextual Error Rendering

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `ALG-010` |
| **Status** | `APPROVED` |
| **Date** | 2026-02-28 |
| **Category** | Platform Model |
| **Tags** | DX, Error Handling, Terminal, UX, Memory, Parsing, Lexer |

## 1. Definition & Context
Contextual Error Rendering is the diagnostic mechanism utilized by MakeOps to present parsing and semantic errors to the user. Instead of simply emitting a cryptic error code or a generic message, the system visually reconstructs the exact location of the failure within the configuration file.

In the context of the **MakeOps** project, this model acts as the final bridge between the highly abstract, memory-efficient internal parsers (Level 1 and Level 2) and the human developer. By adhering strictly to the visual taxonomy established in the Logging and DX Model (`PLAT-012`), this mechanism ensures that developers can instantly identify and fix typos, unsupported keys, or structural violations without needing to manually hunt for line numbers.

## 2. Theoretical Basis
The rendering mechanism relies on a "Zero-Allocation Diagnostic Pattern" and dynamic typographic alignment to achieve high-quality output without violating strict memory constraints.

### 2.1. The Zero-Allocation Diagnostic Pattern
To comply with the MakeOps Static Memory Model (`PLAT-006`), the Level 1 Lexer (`ALG-004`) operates strictly as a line-by-line stream processor. It does not buffer the history of parsed lines, nor does it construct an Abstract Syntax Tree (AST). Consequently, when a domain error is raised and propagated to the top-level execution loop, the original text of the erroneous line no longer exists in memory.
To solve this, MakeOps employs a double-read pattern common in modern, high-performance compilers:
1. **The Happy Path:** The file is streamed once. No memory is wasted storing text.
2. **The Fatal Path:** If an error coordinate `(Line_Number, Column_Number)` is returned, the diagnostic engine briefly re-opens the target file, discards lines until it reaches `Line_Number`, extracts the specific raw line, and prints the error context. 
Because MakeOps halts immediately after an error (Fail-Fast), the I/O penalty of re-reading the file is incurred exactly once, at the very end of the process's lifecycle, resulting in zero performance degradation during normal operations.

### 2.2. Visual Alignment and Typography
To construct a visually pleasing and deterministic output, the diagnostic engine must dynamically calculate margins. The width of the left margin (which holds the line number and the vertical pipe `|`) varies depending on the number of digits in the `Line_Number` (e.g., line `9` requires less padding than line `140`). The engine dynamically computes `Margin_Padding` to guarantee that the pointer character (`^`) always aligns perfectly with the exact column index where the lexer or semantic analyzer identified the fault.

### 2.3. Structured Algorithmic Description
The following is a structured definition of the Contextual Error Rendering algorithm. It acts as the final diagnostic barrier, transforming strictly typed domain errors into human-readable, contextual visual output.

**Inputs:**
* `File_Path`: The absolute or relative path to the configuration file where the error occurred (e.g., `makeops.toml`).
* `Error_Type`: The specific domain error enumeration returned by the parsing or orchestration algorithms (e.g., `Malformed_Section_Header`, `Unsupported_Key`).
* `Line_Number`: The 1-based index of the line where the error occurred.
* `Column_Number`: The 1-based index of the character within the raw line where the error originates.

**Outputs:**
* Formatted text emitted strictly to the `stderr` stream, structured according to the Visual Taxonomy defined in `PLAT-012`.

**Procedure `Translate_Error_Message(Error_Type)`:**
1. Check `Error_Type`:
   * **If `Malformed_Section_Header`:** Return `"Malformed section header"`
   * **If `Unsupported_Value_Type`:** Return `"Unsupported value type provided"`
   * **If `Unrecognized_Statement`:** Return `"Unrecognized statement"`
   * **If `Unsupported_Section`:** Return `"Unsupported section declared"`
   * **If `Unsupported_Key`:** Return `"Unsupported key declared"`
   * **If `Unexpected_Array`:** Return `"Arrays are not supported in this context"`
   * **If `Out_Of_Context_Declaration`:** Return `"Key-value pair declared outside of any section"`
   * **If `Invalid_Value_Domain`:** Return `"Value is outside the permitted domain"`
   * **If `Redefinition_Error`:** Return `"Redefinition of an existing block"`
   * **If other:** Return `"Unknown configuration error"`

**Main Execution Flow:**
1. Set `Error_Message := Translate_Error_Message(Error_Type)`
2. Set `Line_Prefix := To_String(Line_Number)`
3. Set `Margin_Padding := Create_String(" ", Line_Prefix.Length)`
4. Set `Raw_Line := Empty_String`
5. Set `Current_Line := 0`
6. Set `File_Stream := Open_File(File_Path)`
7. Loop while `File_Stream` has next line:
   * Set `Read_Line := File_Stream.Get_Next_Line()`
   * Set `Current_Line := Current_Line + 1`
   * If `Current_Line == Line_Number`:
     * Set `Raw_Line := Read_Line`
     * Call `File_Stream.Close()`
     * Break loop
8. Call `Print_To_Stderr("[mko:error] ❌ Configuration Error in " & File_Path & ":" & Line_Prefix)`
9. Call `Print_To_Stderr(Margin_Padding & " | ")`
10. Call `Print_To_Stderr(Line_Prefix & " | " & Raw_Line)`
11. Set `Pointer_Padding := Create_String(" ", Column_Number - 1)`
12. Call `Print_To_Stderr(Margin_Padding & " | " & Pointer_Padding & "^ " & Error_Message)`
13. Call `Print_To_Stderr("[mko:fatal] ❌ Execution aborted.")`

## 3. Engineering Impact

* **Constraints:**
  * The rendering engine MUST strictly output all of its formatted text using the safe `MakeOps.Sys.Terminal` facade targeting `Standard_Error` (`stderr`). This ensures that standard output (`stdout`) remains unpolluted by MakeOps diagnostics while preventing native `Ada.Text_IO` exceptions from leaking into the core logic.
  * The engine MUST safely handle edge cases during the second file read (e.g., if the user deleted or modified the `makeops.toml` file in the millisecond window between parsing and error reporting). In such cases, the engine MUST gracefully degrade to printing the basic error message and coordinates without the visual code snippet, avoiding an unhandled `Name_Error` or `End_Error`.
* **Performance Risks:** None. The secondary file read occurs exclusively on the fatal termination path. The CPU and I/O cost of re-reading a typical DevOps configuration file (which rarely exceeds a few hundred lines) is computationally invisible to the user.
* **Opportunities:** This approach mimics the highly praised Developer Experience (DX) of modern programming languages (like Rust or Elm), elevating MakeOps from a simple task runner to a highly polished, professional development tool while remaining completely loyal to the Deep Tech / Zero-Dependency philosophy.

## 4. References

**Internal Documentation:**
* [1] [PLAT-006: Static Memory Model](./PLAT-006-static-memory-model.md)
* [2] [PLAT-012: Logging and Developer Experience (DX) Model](./PLAT-012-logging-and-dx-model.md)
* [3] [ALG-004: Event-Driven TOML Lexer](./ALG-004-event-driven-toml-lexer.md)
* [4] [ALG-005: Event-Driven Semantic Analyzer](./ALG-005-event-driven-semantic-analyzer.md)
* [5] [ALG-006: Global Config Semantic Analyzer](./ALG-006-global-config-analyzer.md)