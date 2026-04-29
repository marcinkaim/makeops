<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# MOD-017 Zero-Allocation Diagnostic Pattern

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `MOD-017` |
| **Status** | `APPROVED` |
| **Date** | 2026-04-24 |
| **Tags** | Diagnostics, Developer Experience, DX, Zero-AST, Contextual Rendering, Error Handling |

## 1. Definition & Context
The Zero-Allocation Diagnostic Pattern is the unified mechanism MakeOps uses to provide precise, context-aware error reporting (Contextual Error Rendering). 

In modern developer tools (like Rust or Elm), when a syntax or domain error occurs, the compiler prints the exact offending line of code and a pointer to the mistake. MakeOps achieves this high-tier Developer Experience (DX) without violating its strict $O(1)$ Static Memory constraints. Because MakeOps processes inputs via a flat 5-Phase Pipeline without building an Abstract Syntax Tree (Zero-AST), the original text is discarded immediately after parsing. This model defines the architectural workaround required to retrieve and align that textual context dynamically when a pipeline Applier rejects a value.

## 2. Theoretical Basis
The pattern relies on the strict separation of execution paths and the acceptance of isolated I/O penalties.

### 2.1. The Hot Path vs. Cold Path Dichotomy
In performance-critical systems, execution is divided into the "Hot Path" (the standard, successful execution sequence representing 99% of runs) and the "Cold Path" (fatal error handling and abort sequences). Optimization and strict memory constraints must prioritize the Hot Path. Memory should never be allocated or held in reserve simply to generate a pretty error message for an event that rarely happens.

### 2.2. AST vs. Event Streaming Memory Profiles
Traditional parsers easily point to errors because they load the entire file into a dynamic Abstract Syntax Tree (AST) on the heap. They retain the exact string value of every token. In an event-streaming architecture (like MakeOps's 5-Phase Pipeline), tokens are ephemeral. Once the Lexer reads a token and the Parser validates it, the string data is discarded to keep RAM usage strictly $O(1)$. 

## 3. Conceptual Model
To recreate the visual context without holding the file in memory, MakeOps employs spatial tracking and a Just-In-Time (JIT) extraction maneuver.

### 3.1. Spatial Coordinate Tracking (Data Structures)
During Phase 2 (Lexical Analysis) and Phase 3 (Parsing), the Frontend does NOT store the actual text of the tokens. Instead, every event passed down the pipeline carries a lightweight, fixed-size spatial metadata record containing:
* `File_Path` (Identifier/Hash)
* `Line_Number` (Integer)
* `Column_Number` (Integer)
* `Token_Length` (Integer)

During the Hot Path, this metadata flows through the pipeline and is safely discarded if the processing succeeds, ensuring absolute compliance with $O(1)$ RAM limits.

### 3.2. JIT File Re-open (Behavior & Control Flow)
When any pipeline phase encounters a fatal error, the system enters the Cold Path. It issues a `Diagnostic_Event` containing the error details and the spatial coordinates. The diagnostic engine then executes a Just-In-Time (JIT) File Re-open sequence:
1. **Interrupt:** The orchestration pipeline halts (Fail-Fast).
2. **Open:** The engine opens a new physical file descriptor for `File_Path`.
3. **Discard:** It streams through the file, actively discarding bytes until it reaches the exact `Line_Number`.
4. **Capture:** It loads that single, specific raw line into a static bounded buffer (`MakeOps.Sys.File_Stream`).
5. **Close:** It immediately closes the file descriptor.

### 3.3. Dynamic Typography and Alignment (Heuristics)
To construct a visually pleasing and deterministic output, the engine dynamically calculates typography margins to align the error pointer (`^`) exactly with the `Column_Number`. The width of the left margin (containing the line number and a vertical pipe `|`) varies based on the string length of the `Line_Number` (e.g., line `9` requires less padding than line `140`). 

**Example of Contextual Error Rendering target:**
```text
[mko:error] ❌ Syntax Error in makeops.toml:12
   | 
12 |   deps = ["test" "lint"]
   |                 ^ Missing comma in array
[mko:fatal] ❌ Execution aborted.
```

In the above example, the engine dynamically calculates the 4-space left padding for the empty margin (`   | `) to match the width of `"12 | "`, and pads the pointer `^` exactly to the `Column_Number` where the Lexer recorded the missing comma.

## 4. Engineering Impact
This pattern shifts the complexity of error reporting from memory allocation to precise terminal I/O.

* **Constraints:**
    * All Frontends MUST accurately calculate and propagate `Line_Number` and `Column_Number` for every token.
    * The diagnostic engine MUST implement Graceful Degradation. If the JIT File Re-open fails (e.g., the user deleted the file in the millisecond window between parsing and reporting), the engine MUST fallback to printing the raw integer coordinates without crashing.
    * Diagnostics MUST be emitted exclusively via `MakeOps.Sys.Terminal` targeting `Standard_Error` (`stderr`).
* **Performance/Memory Risks:** Re-opening a file incurs a direct disk I/O cost. However, because this *only* occurs on the fatal termination path (Cold Path), the performance hit is entirely irrelevant to the operational throughput of MakeOps.
* **Opportunities:** This approach proves that SPARK-verified, embedded-style memory constraints do not mandate poor, cryptic error messages. By delegating the heavy lifting to the terminal reporting phase via JIT extraction, MakeOps mimics the high DX of modern compilers while remaining completely loyal to the Deep Tech philosophy.

## 5. References

**Internal Documentation:**
* [1] [MOD-002: Universal 5-Phase Processing Pipeline](./MOD-002-universal-processing-pipeline.md)
* [2] [MOD-009: SPARK Verification & Static Memory Model](./MOD-009-formal-verification-static-memory.md)
* [3] [MOD-011: Isolated OS Boundaries and Exception Handling](./MOD-011-isolated-os-boundaries.md)
* [4] [MOD-016: Observability and Visual Taxonomy Model](./MOD-016-observability-taxonomy.md)

**External Literature:**
* [5] Patterson, D. A., & Hennessy, J. L. (2013). *Computer Organization and Design: The Hardware/Software Interface*. Morgan Kaufmann. (Principles of "Hot Path" vs "Cold Path" instruction optimization).
* [6] [Rust RFC 1644: Diagnostic Guidelines](https://rust-lang.github.io/rfcs/1644-rustc-error-format.html) (The modern industry standard for contextual error rendering).