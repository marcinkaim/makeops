<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# PLAT-013 MakeOps TOML Dialect and Grammar Constraints

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `PLAT-013` |
| **Status** | `APPROVED` |
| **Date** | 2026-02-26 |
| **Category** | Platform Model |
| **Tags** | TOML, Parser, Grammar, Dialect, Strings, Deep Tech, AST, Memory |

## 1. Definition & Context
The MakeOps TOML Dialect is a highly restricted, domain-specific subset of the official TOML (Tom's Obvious, Minimal Language) specification. 

In the context of the **MakeOps** project, configuration files (`makeops.toml` and global preferences) must be parsed incredibly fast, with absolute determinism, and without risking memory exhaustion. This document formalizes the exact grammar supported by the MakeOps parser, explicitly defining which standard TOML features are intentionally rejected and providing the architectural justification for these constraints.

## 2. Theoretical Basis
The foundation of this dialect is rooted in the "Deep Tech" philosophy, strict memory constraints, and the nature of operating system process execution.

### 2.1. The Deep Tech Philosophy (Zero Dependencies)
A common approach in modern software is to import a full-featured, third-party library to parse configuration files. MakeOps explicitly rejects this approach. Standard TOML libraries typically dynamically allocate large, generic Abstract Syntax Trees (ASTs) on the heap to accommodate unpredictable data structures. 
By adhering to the Deep Tech philosophy, MakeOps relies exclusively on the Ada 2022 Standard Library and direct Linux kernel bindings. Implementing a custom, specialized lexer (`ALG-004`) eliminates third-party supply chain risks, ensures absolute compatibility with the Static Memory Model (`PLAT-006`), and allows the parsing logic to be mathematically proven using the SPARK formal verification toolset (`PLAT-005`). 

### 2.2. The String-Only Paradigm
The official TOML specification supports complex data types: integers, floats, booleans, and RFC 3339 formatted dates. The MakeOps Dialect rejects all of them.
Because MakeOps acts as a "Pure Execution" orchestrator (`PLAT-001`), it does not perform mathematical or logical operations on user-defined values. Its primary purpose is to substitute variables and pass arguments directly to the Linux `execvp` system call. At the OS ABI level, every command-line argument is simply a raw array of bytes (UTF-8 strings). Therefore, supporting native integers or booleans in the configuration file introduces unnecessary parsing overhead and complex variant types in Ada, with zero operational benefit. In MakeOps TOML, everything must be explicitly defined as a string.
* **Invalid:** `allow_failure = true`
* **Invalid:** `timeout = 60`
* **Valid:** `log_level = "info"`

### 2.3. Supported Grammar Subset
The MakeOps TOML Lexer only recognizes the following syntactical constructs:
1. **Sections:** Denoted by brackets `[section_name]` or `[parent.child]`.
2. **String Key-Value Pairs:** Keys mapped to string literals enclosed in double quotes (e.g., `key = "value"`).
3. **Array of Strings:** Keys mapped to lists of strings enclosed in brackets (e.g., `key = ["val1", "val2"]`). Arrays can span multiple lines.
4. **Comments:** Prefixed with the `#` symbol.

Any attempt to use inline tables, bare numbers, booleans, multi-line string literals (`"""`), or arrays of arrays will result in an immediate syntactical failure.

## 3. Engineering Impact
* **Constraints:** The underlying parsing mechanism (`ALG-004`) MUST strictly enforce this grammar subset. It MUST immediately return an `Invalid_Syntax` error if a value is not enclosed in double quotes or brackets, fulfilling the "Fail-Fast" requirement. Developers MUST NOT attempt to extend the parser to support native numeric or boolean types unless the core POSIX execution strategy fundamentally changes.
* **Performance Risks:** None. By reducing the grammar to such a primitive subset, the parser avoids complex lookahead and backtracking algorithms, resulting in blazing-fast, $O(N)$ linear stream processing.
* **Opportunities:** Constraining the data types entirely to bounded strings (`PLAT-011`) allows the system's core state records (e.g., the Environment Dictionary) to be drastically simplified. This makes the formal mathematical verification (AoRE) of the internal data flow almost trivial.

## 4. References

**Internal Documentation:**
* [1] [PLAT-001: Pure Execution and OS Bindings](./PLAT-001-pure-execution-posix.md)
* [2] [PLAT-005: SPARK Formal Verification and Ada 2022 Constraints](./PLAT-005-spark-formal-verification.md)
* [3] [PLAT-006: Static Memory Model](./PLAT-006-static-memory-model.md)
* [4] [PLAT-011: Text Encoding and Memory Safety](./PLAT-011-text-encoding-model.md)
* [5] [ALG-004: Event-Driven TOML Lexer](./ALG-004-event-driven-toml-lexer.md)
* [6] [REQ-001: Project Configuration Handling](../design/REQ-001-project-configuration.md)