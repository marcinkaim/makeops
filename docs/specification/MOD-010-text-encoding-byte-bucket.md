<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# MOD-010 Text Encoding and Raw Byte Bucket Model

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `MOD-010` |
| **Status** | `APPROVED` |
| **Date** | 2026-04-23 |
| **Tags** | UTF-8, POSIX, Ada 2022, String, Encoding, Lexer, Memory, Bytes |

## 1. Definition & Context
The Text Encoding and Raw Byte Bucket Model dictates how the MakeOps orchestrator processes, stores, and transmits string data across its internal architecture and operating system boundaries.

In the context of the MakeOps project, modern Linux environments universally employ the UTF-8 encoding standard. However, the native `String` type in Ada 2022 is strictly defined as an array of 8-bit `Character` elements mapped to the Latin-1 (ISO 8859-1) character set. To bridge this gap without introducing severe performance penalties, massive memory bloat (via `Wide_Wide_String`), or complex SPARK verification challenges, the architecture adopts the "Raw Byte Bucket" paradigm. This model defines how we safely handle modern text encoding purely through physical memory management.

## 2. Theoretical Basis
This approach relies on the specific mathematical properties of the UTF-8 standard and a deliberate reinterpretation of the Ada `String` memory layout.

### 2.1. The UTF-8 Mathematical Guarantee
UTF-8 is a variable-width character encoding capable of encoding all valid character code points in Unicode using one to four 8-bit code units. 
The most critical mathematical property of UTF-8 for MakeOps is its strict structural compatibility with ASCII. The first 128 characters (0x00 to 0x7F) are encoded using a single byte. Crucially, any byte with the highest bit set to `0` is guaranteed to be a standalone ASCII character and can **never** appear as a sub-component of a multi-byte sequence. This invariant allows the finite-state machine (FSM) parser to safely scan a raw byte stream for structural TOML characters (e.g., `=`, `[`, `]`, `\n`) without ever needing to decode the surrounding multi-byte user text.

### 2.2. Ada 2022 String Semantics
The standard Ada `String` is simply an array of 8-bit values. Ada provides `Wide_Wide_String` to support 32-bit Unicode characters natively. However, allocating 32 bits per character causes an immediate $4\times$ memory bloat. For an application bound by a strict Static Memory Model, this overhead is unacceptable.

### 2.3. Physical vs. Visual Length
Because UTF-8 characters can span up to 4 bytes, there is a fundamental disconnect between the visual length of a string (the number of printed glyphs) and its physical length (the number of bytes in memory). A user-defined string that looks like 5 characters on screen might consume 8 physical bytes in an array.

## 3. Conceptual Model
MakeOps bypasses complex encoding translations by abstracting strings not as readable text, but as opaque carriers of binary data.

### 3.1. The Raw Byte Bucket Paradigm (Data Structure)
Instead of interpreting Ada's `String` as an array of semantic, human-readable characters, MakeOps redefines it simply as a transparent buffer of 8-bit bytes (a byte bucket). When a configuration file is read, the raw UTF-8 bytes from the file system are poured directly into this bounded bucket.

### 3.2. Lexical Safety Invariant (Domain Rule)
Treating UTF-8 strings as raw 8-bit arrays poses a theoretical risk: could the parser accidentally split a multi-byte character or misidentify half of an emoji as a syntactical separator?
Due to the UTF-8 mathematical guarantee (Section 2.1), this is impossible in MakeOps. The Phase 2 Lexer (`MOD-002`) only searches for structural ASCII delimiters (like `[`, `]`, `=`, and `"`). Since the decimal values of these delimiters (e.g., `=` is 61) strictly fall in the 0-127 range, the Lexer will mathematically never falsely match a continuation byte belonging to a multi-byte UTF-8 sequence (128-255).

### 3.3. OS Boundary Passthrough (Resource Lifecycle)
When the system invokes external processes (via `execvp`), it passes these exact same raw bytes straight to the kernel without any intermediate decoding or translation. MakeOps acts as a "dumb pipe". The semantic interpretation of these bytes (e.g., rendering an emoji or a non-Latin letter) is completely delegated to the user's terminal emulator and the host operating system.

## 4. Engineering Impact
This model significantly constrains string manipulation functions but drastically simplifies the overall system architecture.

* **Constraints:**
    * All system limits defined in the Static Memory Model (`MOD-009`)—such as `Max_Command_Length` or `Max_Arg_Length`—MUST be strictly interpreted as **maximum byte limits**, not maximum character/glyph limits.
    * **The `String'Length` Trap:** Developers MUST treat the native Ada `String'Length` attribute strictly as a byte counter. A single visual glyph (e.g., 'ź' or '🚀') may consume up to 4 elements in the Ada `String` array.
    * Developers MUST NOT use native string-manipulation functions that alter the casing (e.g., `Ada.Characters.Handling.To_Upper`) or reverse the sequence of user-defined text, as these operations blindly act on single bytes and will corrupt multi-byte UTF-8 sequences.
* **Performance/Memory Risks:** By explicitly avoiding the `Ada.Wide_Wide_Text_IO` and `Wide_Wide_String` packages, the system completely avoids $O(N)$ string conversion overheads and prevents a $4\times$ memory bloat in the static data segments.
* **Opportunities:** Frictionless interoperability with the POSIX C ABI (`MOD-007`). C strings are inherently null-terminated arrays of bytes. This model ensures MakeOps can safely route advanced shell arguments natively, retaining a 100% pure execution environment while significantly simplifying formal mathematical verification (AoRE).

## 5. References

**Internal Documentation:**
* [1] [MOD-002: Universal 5-Phase Processing Pipeline](./MOD-002-universal-processing-pipeline.md)
* [2] [MOD-007: Pure Execution OS Boundaries](./MOD-007-pure-execution-os-boundaries.md)
* [3] [MOD-009: SPARK Verification & Static Memory Model](./MOD-009-formal-verification-static-memory.md)

**External Literature:**
* [4] [RFC 3629: UTF-8, a transformation format of ISO 10646](https://datatracker.ietf.org/doc/html/rfc3629)