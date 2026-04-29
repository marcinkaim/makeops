<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# MOD-013 MakeOps TOML Dialect Model

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `MOD-013` |
| **Status** | `APPROVED` |
| **Date** | 2026-04-23 |
| **Tags** | TOML, Parser, Grammar, Dialect, Strings, Deep Tech, AST, Memory |

## 1. Definition & Context
The MakeOps TOML Dialect Model defines a highly restricted, domain-specific subset of the official TOML (Tom's Obvious, Minimal Language) specification tailored for deterministic DevOps orchestration.

In the context of the MakeOps architecture, configuration files must be parsed with absolute determinism and zero dynamic memory allocation to satisfy SPARK formal verification requirements. This model formalizes the grammar supported by the custom MakeOps parser, explicitly rejecting complex data types to ensure compatibility with the system's "Pure Execution" and "Static Memory" paradigms.

## 2. Theoretical Basis
The foundation of this dialect is rooted in the Deep Tech philosophy and the specific requirements of POSIX process execution.

### 2.1. The Deep Tech Philosophy (Zero Dependencies)
To eliminate third-party supply chain risks and ensure absolute control over memory behavior, MakeOps rejects the use of general-purpose TOML libraries. Standard libraries typically build dynamic Abstract Syntax Trees (ASTs) on the heap, which conflicts with our Static Memory Model. By implementing a specialized, linear parser within the 5-Phase Processing Pipeline, the system achieves mathematical provability (AoRE).

### 2.2. The String-Only Paradigm
At the Operating System ABI level (POSIX `execvp`), every command-line argument is a raw array of bytes (UTF-8 strings). Consequently, supporting native TOML integers, booleans, or floats introduces unnecessary parsing complexity and runtime overhead with zero operational benefit. In the MakeOps dialect, all user-defined values are treated as strings to be directly substituted and passed to the kernel.

### 2.3. Linear Grammar Constraints
Official TOML allows for deeply nested structures and complex types (dates, inline tables). Such features require non-deterministic lookahead and backtracking algorithms. By restricting the grammar to a flat, predictable subset, the parser can operate as a simple Finite State Machine (FSM) with $O(N)$ time complexity and $O(1)$ memory complexity.

## 3. Conceptual Model
The model enforces a rigid hierarchy and a limited set of syntactical constructs to maintain system invariants.

### 3.1. Supported Syntactical Atoms (Data Structures)
The dialect only recognizes four fundamental constructs:
* **Sections (Tables):** Denoted by brackets `[section_name]` or `[parent.child]`. These define the context for subsequent key-value pairs.
* **String Key-Value Pairs:** Keys mapped to UTF-8 string literals enclosed in double quotes (e.g., `key = "value"`).
* **Arrays of Strings:** Keys mapped to a flat list of string literals enclosed in square brackets (e.g., `key = ["v1", "v2"]`). 
* **Comments:** Lines prefixed with `#`.

### 3.2. Explicitly Disallowed Constructs (Domain Rules)
To ensure Fail-Fast behavior and memory safety, the following standard TOML features are strictly rejected:
* **Native Non-String Types:** Integers, floats, booleans, and dates (e.g., `timeout = 60` or `active = true` are invalid).
* **Complex Collections:** Inline tables, arrays of arrays, or heterogeneous arrays.
* **Multi-line Literals:** Triple-quoted strings (`"""`).
* **Escaped Non-ASCII:** Only standard UTF-8 raw bytes are supported via the "Raw Byte Bucket" paradigm.

### 3.3. Structural Invariants
* **Key Uniqueness:** A key cannot be redefined within the same section.
* **Section Ordering:** While sections can appear in any order, they must be syntactically valid before the Phase 4 Normalizer flattens them into `Pipeline_Event`s.
* **Bounded Buffering:** Every key and value must fit within the static byte limits defined in the Static Memory Model.

## 4. Engineering Impact
This model simplifies the implementation of the TOML Frontend while enforcing project-wide rigor across the processing pipeline.

* **Constraints:**
    * **Phase 2 (Lexer):** MUST operate in strict $O(1)$ memory. It MUST NOT allocate or copy string buffers. It MUST only emit `Token` structures containing spatial coordinates (index, length, line, column) to support Zero-Allocation Diagnostics. It MUST strictly scan for ASCII delimiters, treating the rest of the stream as raw UTF-8 bytes.
    * **Phase 3 (Parser):** MUST strictly enforce the String-Only paradigm. It MUST explicitly reject native TOML numbers, booleans, multiline strings, and nested arrays (arrays of arrays). It MUST be implemented as an iterative Finite State Machine (FSM) without recursion to comply with SPARK stack-usage limits and guarantee AoRE.
    * **Phase 4 (Normalizer):** Before assembling and emitting a context-free `Pipeline_Event`, it MUST validate the byte length of the extracted string against the static memory boundaries (e.g., `Max_Arg_Length` or `Max_Env_Var_Value_Length`). Exceeding these limits MUST trigger an immediate Fail-Fast domain error.
* **Performance/Memory Risks:** The parser avoids complex lookahead, resulting in extremely fast, linear stream processing. However, if a user provides an exceptionally long line without a newline, it may hit the `Max_Line_Length` buffer limit of the underlying `File_Stream` adapter, causing an I/O truncation error.
* **Opportunities:** Constraining the dialect allows the internal configuration records (like the Environment Dictionary) to use a uniform, strictly bounded internal representation. This orthogonality makes the subsequent Lazy Variable Substitution algorithm mathematically trivial to verify using GNATprove.

## 5. References

**Internal Documentation:**
* [1] [MOD-002: Universal 5-Phase Processing Pipeline](./MOD-002-universal-processing-pipeline.md)
* [2] [MOD-004: Execution Plan Resolution](./MOD-004-execution-plan-resolution.md)
* [3] [MOD-009: SPARK Verification & Static Memory Model](./MOD-009-formal-verification-static-memory.md)
* [4] [MOD-010: Text Encoding and Raw Byte Bucket Model](./MOD-010-text-encoding-byte-bucket.md)
* [5] [REQ-001: Project Configuration Handling](./REQ-001-project-configuration.md)

**External Literature:**
* [6] [Official TOML v1.0.0 Specification](https://toml.io/en/v1.0.0)