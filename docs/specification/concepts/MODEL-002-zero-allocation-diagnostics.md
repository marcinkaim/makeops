<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# MODEL-002 Zero-Allocation Diagnostic Pattern

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `MODEL-002` |
| **Status** | `APPROVED` |
| **Date** | 2026-04-02 |
| **Category** | Model |
| **Tags** | Diagnostics, Developer Experience, DX, Zero-AST, Contextual Rendering, Error Handling |

## 1. Definition & Context
The Zero-Allocation Diagnostic Pattern is the unified mechanism MakeOps uses to provide precise, context-aware error reporting (Contextual Error Rendering). Instead of emitting generic error codes, the system visually reconstructs the exact location of a configuration failure—printing the offending line and a highlighted caret pointing to the mistake.

Crucially, it achieves this high-tier Developer Experience (DX) without violating the Zero-AST and $O(1)$ memory constraints of the system. Because MakeOps processes inputs via the flat 5-Phase Pipeline (`MODEL-001`), the original text is discarded immediately after parsing. This model defines the architectural workaround to retrieve and align that context dynamically when a pipeline Applier rejects a value.

## 2. Theoretical Basis
The model relies on the strict separation of the "Hot Path" (successful execution) and the "Cold Path" (fatal error handling), accepting a deliberate I/O penalty exclusively during the Cold Path.

### 2.1. Spatial Coordinate Tracking (Hot Path)
During Phase 2 (Lexical Analysis) and Phase 3 (Parsing), the Frontend does not store the text. Instead, it strictly tracks spatial coordinates. Every event passed down the pipeline carries a lightweight metadata record:
* `File_Path` (Identifier/Hash)
* `Line_Number`
* `Column_Number`
* `Token_Length`

If the pipeline succeeds, this spatial metadata is safely discarded along with the events, maintaining strict $O(1)$ memory usage.

### 2.2. Just-In-Time Context Retrieval (Cold Path)
When any pipeline phase encounters a fatal error, it instantly halts (Fail-Fast) and returns a `Diagnostic_Event` containing the error details and the coordinates. The diagnostic engine then performs a **Just-In-Time (JIT) File Re-open**:
1. It opens the physical file indicated by the coordinates.
2. It streams through the file, discarding lines until it reaches `Line_Number`.
3. It loads the exact raw line into a small, fixed-size static buffer.
4. It immediately closes the file descriptor.

### 2.3. Dynamic Alignment and Typography
To construct a visually pleasing and deterministic output that adheres to the `PLAT-012` taxonomy, the engine dynamically calculates margins. 
The width of the left margin (containing the line number and the vertical pipe `|`) varies based on the string length of the `Line_Number` (e.g., line `9` requires less padding than line `140`). The engine computes this padding dynamically to guarantee that the pointer character (`^`) aligns perfectly with the exact `Column_Number` where the parser identified the fault.

## 3. Engineering Impact
This pattern heavily influences the I/O and data structure design within the application.

* **Constraints:**
    * All Frontends MUST accurately calculate and propagate `Line_Number` and `Column_Number` for every token.
    * The diagnostic engine MUST gracefully degrade (Graceful Degradation). If the JIT File Re-open fails (e.g., the user deleted the file in the millisecond window between parsing and reporting), the engine MUST fallback to printing the raw coordinates without crashing the orchestrator.
    * Diagnostics MUST be emitted exclusively to the `MakeOps.Sys.Terminal` targeting `Standard_Error` (`stderr`) to prevent pollution of standard output.
* **Performance Risks:** Re-opening a file incurs a direct disk I/O cost. However, because this *only* happens on the fatal termination path of a crashing application, the performance hit is entirely irrelevant to the operational throughput of MakeOps.
* **Opportunities:** This approach proves that SPARK-verified, embedded-style memory constraints do not have to result in poor, cryptic error messages. By delegating the heavy lifting to the terminal reporting phase, MakeOps mimics the DX of modern compilers (like Rust or Elm) while remaining completely loyal to the Deep Tech philosophy.

## 4. References

**Internal Documentation:**
* [1] [MODEL-001: 5-Phase Orchestration Pipeline](./MODEL-001-5-phase-pipeline.md)
* [2] [PLAT-006: Static Memory Model](./PLAT-006-static-memory-model.md)
* [3] [PLAT-012: Logging and Developer Experience (DX) Model](./PLAT-012-logging-and-dx-model.md)