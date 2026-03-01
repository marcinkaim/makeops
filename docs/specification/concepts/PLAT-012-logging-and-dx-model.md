<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# PLAT-012 Logging and Developer Experience (DX) Model

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `PLAT-012` |
| **Status** | `APPROVED` |
| **Date** | 2026-02-26 |
| **Category** | Platform Model |
| **Tags** | UX, DX, Logging, Terminal, ANSI, Emoji, Observability |

## 1. Definition & Context
The Logging and Developer Experience (DX) Model defines the visual and structural taxonomy of standard output (`stdout`) and standard error (`stderr`) streams emitted by the MakeOps orchestrator. 

In the context of the **MakeOps** project, while `REQ-003` defines *when* certain streams are permitted to be visible based on the global configuration, it does not define *how* they are rendered. To provide a modern, predictable, and highly "grep-able" Developer Experience, MakeOps must strictly standardize its diagnostic prefixes, visual anchors (Emoji), color coding (via ANSI escape sequences), and error formatting. This model bridges the gap between raw text emission and an intuitive human-machine interface.

## 2. Theoretical Basis
The model relies on mapping a broad spectrum of internal semantic events to a highly constrained set of configuration levels, alongside a rigid visual typography system based on the "Neutral Happy Path" principle.

### 2.1. Semantic Classes vs. Configuration Levels
MakeOps strictly exposes only three configuration levels to the user via the CLI: `error`, `info`, and `debug` (as defined in `REQ-003`). However, internally, the system encounters a wider variety of semantic states. The architecture employs a "Ceiling Rounding" heuristic to map these internal semantic classes to the user's configured log level:

* **Configured Level: `error` (Quiet Mode)**
  * **`Fatal`**: Unrecoverable system errors (e.g., DAG Cycles). Emitted to `stderr`.
  * **`Error`**: Standard failures (e.g., Syntax errors). Emitted to `stderr`.
  * *(All lower classes and child `stdout` streams are completely suppressed).*
* **Configured Level: `info` (Default Mode)**
  * Includes everything from `error`, plus:
  * **`Warn`**: Non-critical issues (e.g., missing optional files, deferred from `ALG-003`). Emitted to `stderr`.
  * **`Info` / `Run`**: Standard lifecycle events (e.g., starting an operation). Emitted to `stderr`.
  * **`Done` / `Success`**: Positive confirmations of completed tasks. Emitted to `stderr`.
  * *(Child `stdout` and `stderr` streams are fully visible).*
* **Configured Level: `debug` (Verbose Mode)**
  * Includes everything from `info`, plus:
  * **`Debug`**: Highly granular internal machinery logs (e.g., variable substitutions, path resolutions). Emitted to `stderr`.

*Note: All MakeOps-native diagnostic logs are routed to `stderr`. Only the `stdout` of spawned child processes is routed to the terminal's `stdout`.*

### 2.2. Visual Taxonomy: The "Neutral Happy Path"
To prevent the "Rainbow Terminal" anti-pattern, MakeOps uses colors sparingly. The baseline execution path is kept visually neutral, relying on clear prefixes and UTF-8 Emoji markers for quick visual scanning. Colors are strictly reserved for critical halts.

| Semantic Class | Prefix Tag | Visual Treatment (Color & Emoji) | Typical Use Case |
| :--- | :--- | :--- | :--- |
| **Fatal** | `[mko:fatal]` | **Red (Bold)** + ❌ | Immediate application abort (e.g., OS failure). |
| **Error** | `[mko:error]` | Red + ❌ | Syntax, Semantic, or Graph validation failures. |
| **Warn** | `[mko:warn]` | Default Text + ⚠️ | Missing optional configs, deprecated syntax. |
| **Info** | `[mko:info]` | Default Text | Application state (e.g., applying configuration). |
| **Run** | `[mko:run]` | Default Text | Announcing the start of a DAG target. |
| **Done** | `[mko:done]` | Default Text + ✅ | Announcing the successful completion of a task. |
| **Debug** | `[mko:debug]` | Gray (Dim) | Internal state transitions, variable evaluation. |

### 2.3. Child Process Stream Decoration
When executing external commands (via `PLAT-001`), MakeOps intercepts the child's raw streams. To prevent logs from bleeding together, MakeOps decorates these streams in real-time (`PLAT-002`):
1. **Prefixing:** Every line emitted by the child is prefixed with the padded target name (e.g., `[build]    Compiling source.c...`).
2. **Error Highlighting:** Any line intercepted from the child's `stderr` pipe is automatically colored **Red** (or Yellow) to instantly alert the developer.

### 2.4. Contextual Error Rendering (Fail-Fast)
For parsing and domain logic errors (`ALG-004`, `ALG-005`, `ALG-001`), MakeOps mandates Contextual Rendering. Errors must display the file name, line number, and a visual pointer to the exact failure point.

**Example Rendering:**
```text
[mko:error] ❌ Syntax Error in makeops.toml:12
   | 
12 |   deps = ["test" "lint"]
   |                 ^ Missing comma in array
[mko:fatal] ❌ Execution aborted.
```

**Example Successful Flow:**

```text
[mko:info] Resolving dependency graph for target: release
[mko:run]  Starting operation: lint
[lint]     Checking formatting...
[mko:done] ✅ Operation 'lint' completed in 0.5s.
[mko:run]  Starting operation: build
[build]    Compiling source/main.c...
[mko:done] ✅ Operation 'build' completed in 1.2s.
```

## 3. Engineering Impact

* **Constraints:**
    * The `MakeOps.App.Logging` package MUST implement the prefixing, ANSI coloring, and UTF-8 Emoji integration. It MUST explicitly rely on the "Raw Byte Bucket" paradigm (`PLAT-011`) to stream multi-byte emojis directly to the kernel without utilizing `Wide_Wide_String` types.
    * **Memory Limits:** To satisfy the strict memory constraints (`PLAT-006`), log messages constructed dynamically MUST be bounded by a statically defined `Max_Log_Message_Length`. Developers MUST account for the fact that a single emoji consumes up to 4 bytes of this buffer.
* **Opportunities:** By keeping the happy path neutral and tagging events strictly with bracketed prefixes (`[mko:*]`), the output is highly accessible, easy to read on any terminal theme, and easily filterable using standard POSIX tools (`grep`, `awk`).

## 4. References

**Internal Documentation:**

* [1] [REQ-003: Execution Observability](../design/REQ-003-execution-observability.md)
* [2] [PLAT-002: Real-Time Log Streaming and I/O Multiplexing](./PLAT-002-realtime-log-streaming.md)
* [3] [PLAT-006: Static Memory Model](./PLAT-006-static-memory-model.md)
* [4] [ALG-003: Hierarchical Configuration Cascade](./ALG-003-configuration-cascade.md)
* [5] [ALG-008: Real-Time I/O Multiplexing Loop](./ALG-008-io-multiplexing-loop.md)
* [6] [PLAT-011: Text Encoding and Memory Safety](./PLAT-011-text-encoding-model.md)
