<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# ALG-009 Master Orchestration Pipeline

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `ALG-009` |
| **Status** | `APPROVED` |
| **Date** | 2026-02-26 |
| **Category** | Algorithm |
| **Tags** | Orchestration, Pipeline, DAG, Execution, Fail-Fast |

## 1. Definition & Context
The Master Orchestration Pipeline is the central executive algorithm of the MakeOps core engine. It acts as the "Conductor" that orchestrates the execution lifecycle from raw user arguments to the final process exit code.

In the context of the **MakeOps** project, this pipeline guarantees that graph resolution, variable substitution, path translation, and system execution occur in a strict, mathematically predictable order. It fulfills the functional requirements of `REQ-002` by embedding the "Fail-Fast" behavior and providing a single integration point for various discrete algorithms (`ALG-001`, `ALG-002`, `ALG-008`).

## 2. Theoretical Basis
The orchestration sequence is divided into four strictly separated phases: Initialization, Graph Resolution, Queue Preparation, and Execution Iteration.

### 2.1. Phase 0: Initialization & Parsing
Before any graph operations can occur, the orchestrator must establish its reality. It parses the raw CLI arguments (`ALG-007`), resolves the hierarchical configuration cascade (`ALG-003`), establishes the physical working directory (`PLAT-007`), and parses the project's configuration file into memory. If any syntactical or semantic violations occur during parsing, the pipeline acts as the top-level exception handler, catching the domain errors and delegating them to the Contextual Error Rendering engine (`ALG-010`) before safely aborting execution.

### 2.1. Phase 1: Virtual Root Graph Resolution
Users can provide multiple discrete targets via the CLI (e.g., `mko build test`). To reuse the unmodified Topological Sorting algorithm (`ALG-001`) which requires a single starting point, the pipeline implements the "Virtual Root Pattern". It creates a dummy `Virtual_Root` node whose dependencies (`Adjacency_List`) point to the user's requested targets. Executing `ALG-001` starting from this dummy node naturally resolves the complete, unified dependency sequence for all requested targets. The dummy node is subsequently removed from the result.

### 2.2. Phase 2: Fail-Fast Queue Preparation
Before invoking any external processes, the entire sorted queue must be prepared. The pipeline invokes the Lazy Variable Substitution algorithm (`ALG-002`) on the flat queue. This phase guarantees that any undefined variables or circular variable references will crash the application immediately (Fail-Fast), preventing partial execution or workspace corruption.

### 2.3. Phase 3: Execution Iteration & Pre-Flight Checks
The engine iterates sequentially over the prepared queue. For each operation, it applies the Execution Context heuristics (`PLAT-007`) by prepending the `Configuration_Anchor` to relative paths. Crucially, it verifies the static memory limits (`PLAT-006`) before path concatenation and performs the OS-level `+x` permission check (`PLAT-004`). If all pre-flight checks pass, the process is delegated to the Real-Time I/O Multiplexing Loop (`ALG-008`). Any non-zero exit code immediately aborts the pipeline.

### 2.4. Structured Algorithmic Description
The following is a structured definition of the Master Orchestration Pipeline.

**Inputs:**
* `Operations_Graph`: A dictionary of all parsed operations from the `makeops.toml` file.
* `Target_Operations`: A list of operation names requested by the user via CLI arguments.
* `Environment_Map`: The dictionary of declared variables from `makeops.toml`.
* `Raw_Arguments`: An ordered array of strings representing the CLI arguments passed by the OS.
* `OS_Env`: The system environment variables context.
* `Configuration_Anchor`: The absolute path to the directory containing `makeops.toml`.
* `Global_Config`: The unified configuration record containing `Log_Level`.

**Outputs:**
* `Final_Exit_Code`: `0` (Success) if all operations complete, or the specific non-zero exit code of the failing operation.
* Returns a domain error (e.g., `Cycle_Detected`, `Missing_Variable`, `Path_Too_Long`, `Permission_Denied`) on pre-flight validation failures. Prints contextual errors directly to `stderr` via `ALG-010` during Phase 0.

**Main Execution Flow:**
1. *--- Phase 0: Initialization & Parsing ---*
    * Set `CLI_Result := ALG_007_Parse_CLI(Raw_Arguments)`
    * Check `CLI_Result.System_Action`:
        * **If `Print_Help`:**
            * Call `Print_Help_Manual()`
            * Return `0`
        * **If `Print_Version`:**
            * Call `Print_Version_Info()`
            * Return `0`
    * Set `Global_Config := ALG_003_Resolve_Cascade(CLI_Result.CLI_Config, OS_Env)`
    * Call `OS.chdir(Global_Config.Working_Directory)`
    * Set `Configuration_Anchor := Get_Absolute_Directory_Path(Global_Config.Project_Config)`
    * Set `Target_Operations := CLI_Result.Target_Operations`
    * If `Target_Operations` is empty:
        * Call `Print_Error_Log("No target operations provided")`
        * Call `Print_Help_Manual()`
        * Return `1`
    * Set `Parse_Result := Parse_Project_Configuration(Global_Config.Project_Config)`
    * Check `Parse_Result.Status`:
        * **If `Error`:**
            * Call `ALG_010_Render_Contextual_Error(Global_Config.Project_Config, Parse_Result.Error_Type, Parse_Result.Line_Number, Parse_Result.Column_Number)`
            * Return `1`
        * **If `Success`:**
            * Set `Operations_Graph := Parse_Result.Operations_Graph`
            * Set `Environment_Map := Parse_Result.Environment_Map`
2. *--- Phase 1: Virtual Root Graph Resolution ---*
    * Set `Virtual_Root := Create_Empty_Node()`
    * Set `Virtual_Root.Adjacency_List := Target_Operations`
    * Call `Operations_Graph.Add("virtual_root", Virtual_Root)`
    * Set `Sorted_Queue := ALG_001_Topological_Sort(Operations_Graph, "virtual_root")`
    * Call `Sorted_Queue.Remove("virtual_root")`
3. *--- Phase 2: Fail-Fast Queue Preparation ---*
    * Set `Prepared_Queue := ALG_002_Substitute_Variables(Sorted_Queue, Environment_Map, OS_Env)`
4. *--- Phase 3: Execution Iteration ---*
    * For each `Operation` in `Prepared_Queue` loop:
        * Call `Print_Run_Log(Operation.ID)`
        * Set `Raw_Cmd := Operation.Cmd`
        * Check `Raw_Cmd`:
            * **If starts with `"/"`:**
                * Set `Translated_Cmd := Raw_Cmd`
            * **If does not contain `"/"`:**
                * Set `Translated_Cmd := Raw_Cmd`
            * **If contains `"/"` but does not start with `"/"`:**
                * Set `Combined_Length := Configuration_Anchor.Length + Raw_Cmd.Length + 1`
                * If `Combined_Length > Max_Command_Length`:
                    * Return Error: `Path_Too_Long`
                * Set `Translated_Cmd := Combine_Paths(Configuration_Anchor, Raw_Cmd)`
        * If `Translated_Cmd` contains `"/"`:
            * Set `Is_Executable := FS_Adapter.Check_Executable(Translated_Cmd)`
            * If `Is_Executable == False`:
                * Return Error: `Permission_Denied`
        * Set `FD_Out := Not_Set`
        * Check `Global_Config.Log_Level`:
            * **If `Info` or `Debug`:**
                * Set `FD_Out := Create_Pipe()`
        * Set `FD_Err := Create_Pipe()`
        * Set `Child_PID := Spawn_Process(Translated_Cmd, Operation.Args, FD_Out, FD_Err)`
        * Set `Exit_Code := ALG_008_Multiplexing_Loop(Child_PID, FD_Out, FD_Err, Grace_Period_MS)`
        * Call `Close_Pipes(FD_Out, FD_Err)`
        * Check `Exit_Code`:
            * **If 0:**
                * Call `Print_Done_Log(Operation.ID)`
            * **If other:**
                * Call `Print_Error_Log(Operation.ID, Exit_Code)`
                * Return `Exit_Code`
5. Return `0`

## 3. Engineering Impact

* **Constraints:** The pipeline MUST strictly adhere to the phase ordering. It MUST NOT perform on-the-fly variable evaluation during Phase 3. The `Virtual_Root` injection MUST be handled completely in memory and MUST NOT permanently mutate the global configuration state. All domain errors returned during the phases MUST be handled explicitly by the application's top-level execution logic (such as invoking `ALG-010` in Phase 0) to provide clean, contextual logs (`PLAT-012`) before exiting, completely avoiding the use of native Ada exception handlers for control flow.
* **Performance Risks:** Processing the configuration parsing, graph traversal, and string substitutions entirely in memory (Phases 0, 1, and 2) operates in $O(N)$ time. In the context of standard DevOps configurations, this consumes negligible CPU cycles compared to the actual OS-level process execution (Phase 3).
* **Opportunities:** By isolating the orchestration logic into this sequential pipeline, Phase 3 can be easily mocked during unit testing (`MakeOps.Tests`). We can test the entire parsing, graph resolution, cycle detection, variable substitution, and path translation logic mathematically without ever invoking `fork()` or `execvp()`.

## 4. References

**Internal Documentation:**

* [1] [REQ-002: Operation Orchestration & Execution](../design/REQ-002-operation-orchestration.md)
* [2] [ALG-001: Topological Sorting and Cycle Detection](./ALG-001-topological-sort.md)
* [3] [ALG-002: Lazy Variable Substitution](./ALG-002-lazy-variable-substitution.md)
* [4] [ALG-008: Real-Time I/O Multiplexing Loop](./ALG-008-io-multiplexing-loop.md)
* [5] [PLAT-004: OS Boundary Facades and Exception Isolation](./PLAT-004-isolated-os-boundaries.md)
* [6] [PLAT-006: Static Memory Model](./PLAT-006-static-memory-model.md)
* [7] [PLAT-007: Execution Context Model](./PLAT-007-execution-context-model.md)
* [8] [ALG-010: Contextual Error Rendering](./ALG-010-contextual-error-rendering.md)
