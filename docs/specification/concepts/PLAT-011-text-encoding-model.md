<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# PLAT-011 Text Encoding and Memory Safety

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `PLAT-011` |
| **Status** | `APPROVED` |
| **Date** | 2026-02-25 |
| **Category** | Platform Model |
| **Tags** | UTF-8, POSIX, Ada 2022, String, Encoding, Lexer, Memory |

## 1. Definition & Context
The Text Encoding and Memory Safety model dictates how the MakeOps orchestrator processes, stores, and transmits string data across its internal architecture and operating system boundaries.

In the context of the **MakeOps** project, modern Linux environments (Debian 13) universally employ the UTF-8 encoding standard. However, the native `String` type in Ada 2022 is strictly defined as an array of 8-bit `Character` elements mapped to the Latin-1 (ISO 8859-1) character set. To bridge this gap without introducing severe performance penalties, massive memory bloat (via `Wide_Wide_String`), or complex SPARK verification challenges, the architecture adopts the "Raw Byte Bucket" paradigm.

## 2. Theoretical Basis
This approach relies on the specific mathematical properties of the UTF-8 standard and a deliberate reinterpretation of the Ada `String` type.

### 2.1. The Raw Byte Bucket Paradigm
Instead of interpreting Ada's `String` as an array of semantic, human-readable characters, MakeOps redefines it simply as a transparent buffer of 8-bit bytes (a byte bucket). When the configuration file is read, the raw UTF-8 bytes from the file system are poured directly into this bucket. When the system invokes external processes (via `execvp`), it passes these exact same bytes straight to the kernel without any intermediate decoding or translation. The semantic interpretation of these bytes (e.g., rendering an emoji or a non-Latin letter) is completely delegated to the user's terminal emulator.

### 2.2. The UTF-8 Mathematical Guarantee
Treating UTF-8 strings as raw 8-bit arrays poses a theoretical risk to parsers: could a multi-byte character be accidentally split or misidentified as a syntactical separator? 
By mathematical design, UTF-8 guarantees that this will never happen. The standard ASCII characters (values 0-127) are represented identically in UTF-8. Any multi-byte character (such as `ą`, `🚀`, or `中`) is constructed exclusively using "continuation bytes" whose decimal values strictly fall within the 128-255 range. 
Because the MakeOps Level 1 Lexer (`ALG-004`) only searches for structural ASCII delimiters (like `[`, `]`, `=`, and `"`), it will never falsely match a byte belonging to a multi-byte UTF-8 sequence.

### 2.3. Length Mismatch and Memory Bounds
Because UTF-8 characters can span up to 4 bytes, there is a fundamental disconnect between the *visual length* of a string (glyphs) and its *physical length* (bytes). If a user writes a 5-glyph word containing a multi-byte character, its physical length inside the Ada `String` array might be 6 or 7 elements.

## 3. Engineering Impact

* **Constraints:** All system limits defined in the Static Memory Model (`PLAT-006`)—such as `Max_Command_Length` or `Max_Arg_Length`—MUST be strictly interpreted as **maximum byte limits**, not maximum character limits. Developers MUST NOT use native string-manipulation functions that alter the casing (e.g., `To_Upper`) or reverse the string sequence on user-defined text, as these operations would corrupt multi-byte UTF-8 sequences.
* **Performance Risks:** None. By explicitly avoiding the `Ada.Wide_Wide_Text_IO` and `Wide_Wide_String` packages, the system avoids $O(N)$ string conversion overheads and prevents a $4\times$ memory bloat in the static data segments.
* **Opportunities:** This "dumb pipe" approach provides frictionless interoperability with the POSIX C ABI (`PLAT-001`). It ensures that MakeOps can safely route advanced shell arguments and environmental variables natively, retaining a $100\%$ pure execution environment while significantly simplifying formal mathematical verification (AoRE).

## 4. References

**Internal Documentation:**
* [1] [PLAT-001: Pure Execution and OS Bindings](./PLAT-001-pure-execution-posix.md)
* [2] [PLAT-005: SPARK Formal Verification and Ada 2022 Constraints](./PLAT-005-spark-formal-verification.md)
* [3] [PLAT-006: Static Memory Model](./PLAT-006-static-memory-model.md)
* [4] [ALG-004: Event-Driven TOML Lexer](./ALG-004-event-driven-toml-lexer.md)