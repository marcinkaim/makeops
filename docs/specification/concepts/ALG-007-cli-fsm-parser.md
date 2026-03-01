<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# ALG-007 CLI Finite State Machine Parser

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `ALG-007` |
| **Status** | `APPROVED` |
| **Date** | 2026-02-24 |
| **Category** | Algorithm |
| **Tags** | CLI, FSM, Parser, Arguments, State Machine, Developer Experience |

## 1. Definition & Context
The CLI Finite State Machine (FSM) Parser is the algorithmic component responsible for processing the raw array of command-line arguments passed by the operating system into structured, actionable configuration data. 

In the context of the **MakeOps** project, this algorithm provides a "forgiving" Developer Experience (DX) by allowing users to naturally mix option flags and target operations. Simultaneously, it maintains a mathematically trivial state machine that avoids complex branching, ensuring that the parsing logic can be easily and formally verified using the SPARK toolset.

## 2. Theoretical Basis
The parsing strategy rejects traditional POSIX rigidity in favor of modern CLI patterns, utilizing a highly constrained state machine.

### 2.1. Forgiving Developer Experience (DX)
Strict POSIX standards require all option flags to precede positional arguments (e.g., `mko -w ./src build test`). However, modern developers frequently append flags as an afterthought (e.g., `mko build test -w ./src`). To support this natural workflow, the parser treats the argument array as a continuous stream, dynamically switching context between reading options and queuing operations, without enforcing a rigid global order.

### 2.2. The Two-State Normalization
Because the Command Line Interface Model (`PLAT-008`) normalizes all operational modifiers into key-value pairs and eliminates mutually exclusive boolean flags, the parsing algorithm requires only two fundamental states:
1. `Expecting_Key_Or_Operation`: The default state. It evaluates whether the incoming string is an option flag (starting with `-`) or a positional target operation.
2. `Expecting_Value`: The suspended state. It blindly accepts the next string in the array as the argument for the previously stored key, subsequently reverting to the default state.

### 2.3. Structured Algorithmic Description
The following is a structured definition of the two-state Finite State Machine (FSM) used to parse the raw Command Line Interface (CLI) arguments.

**Inputs:**
* `Raw_Arguments`: An ordered array of strings representing the arguments passed to the executable by the operating system.

**Outputs:**
* `CLI_Config`: A `Partial_Config` record containing `Working_Directory`, `Project_Config`, `Log_Level`, and `Allow_Root` (initially all `Not_Set`).
* `Target_Operations`: A list of strings representing the positional arguments (operations to execute).
* `System_Action`: An enumeration indicating if the application should `Execute_Normal`, `Print_Help`, or `Print_Version`.
* An error `Invalid_CLI_Argument` if an invalid flag, invalid log level, or dangling key is encountered.

**Internal State:**
* `Current_State`: The current FSM state. Valid states: `Expecting_Key_Or_Operation`, `Expecting_Value` (initially `Expecting_Key_Or_Operation`).
* `Pending_Key`: A string storing the option flag that is awaiting its value (initially empty).

**Main Execution Flow:**
1. Set `CLI_Config := Create_Empty_Partial_Config()`
2. Set `Target_Operations := Empty_List`
3. Set `System_Action := Execute_Normal`
4. Set `Current_State := Expecting_Key_Or_Operation`
5. Set `Pending_Key := Empty_String`
6. For each `Arg` in `Raw_Arguments` loop:
   * Check `Current_State`:
     * **If `Expecting_Value`:**
       * Check `Pending_Key`:
         * **If `"-w"` or `"--workdir"`:**
           * Set `CLI_Config.Working_Directory := Arg`
         * **If `"-p"` or `"--project-config"`:**
           * Set `CLI_Config.Project_Config := Arg`
         * **If `"-l"` or `"--log-level"`:**
           * Check `Arg`:
             * **If `"error"` or `"info"` or `"debug"`:**
               * Set `CLI_Config.Log_Level := Arg`
             * **If other:**
               * Return Error: `Invalid_CLI_Argument` ("Invalid log level value")
       * Set `Current_State := Expecting_Key_Or_Operation`
       * Set `Pending_Key := Empty_String`
     * **If `Expecting_Key_Or_Operation`:**
       * If `Arg` starts with `"-"`:
         * Check `Arg`:
           * **If `"-h"` or `"--help"`:**
             * Set `System_Action := Print_Help`
             * Return `(CLI_Config, Target_Operations, System_Action)`
           * **If `"--version"`:**
             * Set `System_Action := Print_Version`
             * Return `(CLI_Config, Target_Operations, System_Action)`
           * **If `"--allow-root"`:**
             * Set `CLI_Config.Allow_Root := True`
           * **If `"-w"` or `"--workdir"` or `"-p"` or `"--project-config"` or `"-l"` or `"--log-level"`:**
             * Set `Pending_Key := Arg`
             * Set `Current_State := Expecting_Value`
           * **If other:**
             * Return Error: `Invalid_CLI_Argument` ("Unrecognized CLI flag")
       * Else:
         * Call `Target_Operations.Append(Arg)`
7. Check `Current_State`:
   * **If `Expecting_Value`:**
     * Return Error: `Invalid_CLI_Argument` ("Missing value for the last provided flag")
8. Return `(CLI_Config, Target_Operations, System_Action)`

## 3. Engineering Impact
* **Constraints:** The parser MUST strictly validate the domain of the `--log-level` values (Fail-Fast). It MUST output a `Partial_Config` record containing `Not_Set` fields for any omitted flags, fulfilling the interface requirements of the Hierarchical Configuration Cascade (`ALG-003`).
* **Performance Risks:** Negligible. The algorithm iterates over the OS-provided argument array exactly once ($O(N)$ time complexity).
* **Opportunities:** The total absence of look-ahead logic, backtracking, or nested conditionals ensures that the FSM is highly predictable. This specific design enables the SPARK prover to mathematically guarantee the Absence of Runtime Errors (AoRE), such as array index out of bounds, almost instantaneously.

## 4. References

**Internal Documentation:**
* [1] [PLAT-008: Command Line Interface Model](./PLAT-008-cli-interface-model.md)
* [2] [ALG-003: Hierarchical Configuration Cascade](./ALG-003-configuration-cascade.md)
* [3] [PLAT-005: SPARK Formal Verification and Ada 2022 Constraints](./PLAT-005-spark-formal-verification.md)
* [4] [PLAT-010: Security Context and Root Privileges](./PLAT-010-security-context-and-privileges.md)