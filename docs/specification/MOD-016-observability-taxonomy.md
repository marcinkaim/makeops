<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# MOD-016 Observability and Visual Taxonomy Model

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `MOD-016` |
| **Status** | `APPROVED` |
| **Date** | 2026-04-23 |
| **Tags** | UX, DX, Logging, Terminal, ANSI, Emoji, Observability |

## 1. Definition & Context
The Observability and Visual Taxonomy Model defines the visual and structural formatting of standard output (`stdout`) and standard error (`stderr`) streams emitted by the MakeOps orchestrator. 

In the context of the MakeOps project, achieving a modern, predictable, and highly "grep-able" Developer Experience (DX) is critical. While other models define *when* streams are visible based on configuration, this model defines *how* they are rendered. It strictly standardizes diagnostic prefixes, visual anchors (UTF-8 Emoji), color coding (via ANSI escape sequences), and error formatting to provide an intuitive human-machine interface without violating static memory boundaries.

## 2. Theoretical Basis
The model is built upon principles of terminal usability, log-level rounding heuristics, and cognitive load reduction.

### 2.1. The "Neutral Happy Path" Principle
To prevent the "Rainbow Terminal" anti-pattern—where an excess of colors makes logs difficult to parse—MakeOps limits color usage. The baseline execution path remains visually neutral. It relies on clear, consistent text prefixes and standard UTF-8 Emoji markers for rapid visual scanning. ANSI colors (specifically Red and Bold text) are strictly reserved for critical halts and domain violations.

### 2.2. Semantic Classes vs. Configuration Levels (Ceiling Rounding)
Users interact with three discrete configuration levels. The system employs a "Ceiling Rounding" heuristic to map internal semantic classes onto these tiers, ensuring that only relevant information reaches the terminal:

* **Level: `error` (Quiet Mode)**
    * **`Fatal`**: Unrecoverable system errors (e.g., DAG Cycles). Emitted to `stderr`.
    * **`Error`**: Standard failures (e.g., Syntax errors). Emitted to `stderr`.
    * *(All lower classes and child `stdout` streams are completely suppressed).*
* **Level: `info` (Default Mode)**
    * Includes everything from `error`, plus:
    * **`Warn`**: Non-critical issues (e.g., missing optional files). Emitted to `stderr`.
    * **`Info` / `Run`**: Standard lifecycle events (e.g., starting an operation). Emitted to `stderr`.
    * **`Done` / `Success`**: Positive confirmations of completed tasks. Emitted to `stderr`.
    * *(Child `stdout` and `stderr` streams are fully visible).*
* **Level: `debug` (Verbose Mode)**
    * Includes everything from `info`, plus:
    * **`Debug`**: Highly granular internal machinery logs (e.g., variable substitutions, path resolutions). Emitted to `stderr`.

### 2.3. Stream Separation Standard
In POSIX systems, `stdout` is intended for data output, while `stderr` is intended for out-of-band diagnostics and errors. Blurring these lines breaks shell pipelines (e.g., `mko build | grep "warning"`). MakeOps adheres to strict POSIX stream hygiene to maintain composability with standard Unix tools.

## 3. Conceptual Model
The model enforces strict routing rules and a static taxonomy matrix for all terminal outputs.

### 3.1. Log Routing and Muting (Control Flow)
* **MakeOps Native Diagnostics:** All logs generated internally by MakeOps (e.g., "Starting operation", "Syntax Error") are routed exclusively to `stderr`. 
* **Child Process Streams:** When executing target binaries, their `stdout` is routed to the terminal's `stdout`, and their `stderr` is routed to the terminal's `stderr`.
* **Visibility Filtering:** Muting occurs during the routing phase based on the global `Log_Level`. For example, in `error` mode, all native MakeOps informational logs and child `stdout` streams are physically discarded (routed to `/dev/null`) before they reach the terminal.

### 3.2. Visual Taxonomy Matrix (Data Formatting)
All native MakeOps logs MUST adhere to this strict formatting taxonomy:

| Semantic Class | Prefix Tag | Visual Treatment (Color & Emoji) | Typical Use Case |
| :--- | :--- | :--- | :--- |
| **Fatal** | `[mko:fatal]` | **Red (Bold)** + ❌ | Immediate application abort (e.g., OS failure). |
| **Error** | `[mko:error]` | Red + ❌ | Syntax, Semantic, or Graph validation failures. |
| **Warn** | `[mko:warn]` | Default Text + ⚠️ | Missing optional configs, deferred warnings. |
| **Info** | `[mko:info]` | Default Text | Application state (e.g., applying configuration). |
| **Run** | `[mko:run]` | Default Text | Announcing the start of a DAG target. |
| **Done** | `[mko:done]` | Default Text + ✅ | Successful completion of a task. |
| **Debug** | `[mko:debug]` | Gray (Dim) | Internal state transitions, DAG sorting. |

### 3.3. Child Process Stream Decoration
To prevent logs from parallel or sequential operations from bleeding together, MakeOps intercepts and decorates child streams in real-time:
1. **Prefixing:** Every line emitted by the child is prefixed with the padded target name (e.g., `[build]    Compiling source.c...`).
2. **Error Highlighting:** Any line intercepted from the child's `stderr` pipe is automatically colored **Red** (or Yellow) to instantly alert the developer.

### 3.4. Execution Success Feedback (Happy Path)
To maintain a high standard of DX, the successful execution of an operation chain must be informative yet non-intrusive. The "Happy Path" follows a predictable rhythmic pattern of Announcement (`run`), Execution (decorated child output), and Confirmation (`done`).

**Example of a successful execution sequence:**
```text
[mko:info] Resolving dependency graph for target: release
[mko:run]  Starting operation: lint
[lint]     Checking formatting...
[mko:done] ✅ Operation 'lint' completed in 0.5s.
[mko:run]  Starting operation: build
[build]    Compiling source/main.c...
[mko:done] ✅ Operation 'build' completed in 1.2s.
```

## 4. Engineering Impact
This taxonomy directly dictates the implementation of the `MakeOps.App.Logger` package and constrains memory allocations.

* **Constraints:**
    * The `MakeOps.App.Logger` package MUST implement the prefixing, ANSI coloring, and UTF-8 Emoji integration.
    * It MUST explicitly rely on the "Raw Byte Bucket" paradigm to stream multi-byte emojis directly to the OS terminal without utilizing `Wide_Wide_String` types.
    * **Memory Limits:** To satisfy the strict Static Memory Model, log messages constructed dynamically MUST be bounded by a statically defined capacity (e.g., `Max_Log_Message_Length`). Developers MUST account for the fact that a single UTF-8 emoji consumes up to 4 physical bytes of this bounded buffer.
* **Performance/Memory Risks:** String concatenation for stream decoration is extremely fast but requires careful bound checks. If a child process emits an abnormally long line without a newline, the Logger MUST safely truncate or wrap it to prevent buffer overflow.
* **Opportunities:** By keeping the happy path neutral and tagging events strictly with bracketed prefixes (`[mko:*]`), the output is highly accessible, easy to read on any terminal theme (dark or light), and easily filterable using standard POSIX tools.

## 5. References

**Internal Documentation:**
* [1] [MOD-003: Hierarchical Configuration Cascade](./MOD-003-hierarchical-configuration-cascade.md)
* [2] [MOD-005: Asynchronous Execution and Multiplexing](./MOD-005-asynchronous-execution.md)
* [3] [MOD-009: SPARK Verification & Static Memory Model](./MOD-009-formal-verification-static-memory.md)
* [4] [MOD-010: Text Encoding and Raw Byte Bucket Model](./MOD-010-text-encoding-byte-bucket.md)
* [5] [REQ-003: Execution Observability](./REQ-003-execution-observability.md)

**External Literature:**
* [6] [ECMA-48: Control Functions for Coded Character Sets (ANSI Escape Codes)](https://www.ecma-international.org/publications-and-standards/standards/ecma-48/)