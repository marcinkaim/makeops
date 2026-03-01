<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# ALG-002 Lazy Variable Substitution

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `ALG-002` |
| **Status** | `APPROVED` |
| **Date** | 2026-02-22 |
| **Category** | Algorithm |
| **Tags** | Variable Substitution, Lazy Evaluation, Memoization, String Interpolation, Cycle Detection |

## 1. Definition & Context
Variable substitution (or string interpolation) is the computational process of identifying predefined markers within a text string and replacing them with their corresponding values mapped in a dictionary or environment context. 

In the **MakeOps** project, this algorithm is responsible for evaluating dynamic arguments (`${VAR_NAME}`) defined in the configuration. Because MakeOps strictly enforces "Pure Execution" without an underlying shell, it must handle variable expansion internally to guarantee deterministic behavior, prevent shell-like word splitting, and safely retrieve values from both the project configuration and the operating system environment.

## 2. Theoretical Basis
The substitution process is designed around two core theoretical principles: Lazy Evaluation and implicit Directed Acyclic Graph (DAG) cycle detection.

### 2.1. Lazy Evaluation and Memoization
Rather than resolving all variables globally upon parsing, the system employs a late-binding (lazy) approach. Variables are evaluated exclusively if they are present in the exact commands required by the pre-computed execution queue. To optimize performance and prevent redundant string operations, the algorithm utilizes memoization—caching fully resolved variables so subsequent lookups execute in $O(1)$ time.

### 2.2. Implicit Dependency Graph and Cycle Prevention
Because variables can recursively reference other variables (e.g., `BIN_DIR = "${BASE_DIR}/bin"`), the environment dictionary implicitly forms a secondary Directed Acyclic Graph. To prevent infinite recursion caused by circular references (e.g., `A = "${B}"` and `B = "${A}"`), the algorithm uses a tracking set (a call stack) of currently resolving variables. Encountering a variable that is already in this tracking set constitutes mathematical proof of a cycle, instantly triggering an error.

### 2.3. Structured Algorithmic Description
The following is a structured definition of the lazy variable substitution logic.

**Inputs:**
* `Operation_Queue`: A list of target operations pending evaluation (Output from ALG-001).
* `Environment`: A dictionary of raw variables parsed from `makeops.toml`.
* `OS_Env`: The system environment variables context.
* `Evaluated_Cache`: A dictionary to store fully resolved variables (Memoization). Initially empty.
* `Call_Stack`: A set of variable names currently in the resolution chain (Cycle detection). Initially empty.

**Outputs:**
* The `Operation_Queue` where all `Cmd` and `Args` elements are fully evaluated.
* An error `Missing_Variable` if an undeclared variable is referenced.
* An error `Circular_Variable_Reference` if variables infinitely reference each other.

**Procedure `Substitute_String(Input_String)`:**
1. Set `Result := Empty_String`
2. Set `Cursor := 0`
3. Loop while `Cursor < Input_String.Length`:
   * Check substring at `Cursor`:
     * **If exactly `$$`:** * Call `Result.Append("$")`
       * Set `Cursor := Cursor + 2`
     * **If matches `${VAR_NAME}` pattern:**
       * Set `Resolved_Sub := Resolve_Variable(VAR_NAME)`
       * Call `Result.Append(Resolved_Sub)`
       * Set `Cursor := Cursor + Pattern_Length`
     * **If other characters:**
       * Call `Result.Append(Input_String[Cursor])`
       * Set `Cursor := Cursor + 1`
4. Return `Result`

**Procedure `Resolve_Variable(Var_Name)`:**
1. If `Var_Name` exists in `Evaluated_Cache`:
   * Return `Evaluated_Cache[Var_Name]`
2. If `Var_Name` exists in `Call_Stack`:
   * Return Error: `Circular_Variable_Reference`
3. Call `Call_Stack.Add(Var_Name)`
4. Set `Resolved_Value := Empty_String`
5. Check variable source:
   * **If `Var_Name` exists in `OS_Env`:**
     * Set `Resolved_Value := OS_Env.Get(Var_Name)`
   * **If `Var_Name` exists in `Environment`:**
     * Set `Raw_Value := Environment[Var_Name]`
     * Set `Resolved_Value := Substitute_String(Raw_Value)`
   * **If missing everywhere:**
     * Return Error: `Missing_Variable`
6. Call `Call_Stack.Remove(Var_Name)`
7. Set `Evaluated_Cache[Var_Name] := Resolved_Value`
8. Return `Resolved_Value`

**Main Execution Flow (Phase 2: Preparation):**
1. For each `Operation` in `Operation_Queue` loop:
   * Set `Operation.Cmd := Substitute_String(Operation.Raw_Cmd)`
   * For each `Arg` in `Operation.Args` loop:
     * Set `Arg := Substitute_String(Arg)`
2. Return `Operation_Queue`

## 3. Engineering Impact

* **Constraints:** The algorithm MUST output exact string replacements without altering the size of the argument arrays, satisfying the pure execution requirement. It MUST adhere to a strict "fail-fast" policy, immediately halting execution if an undeclared variable is referenced, rather than silently substituting an empty string. Furthermore, to satisfy SPARK verification and the Absence of Runtime Errors (AoRE) requirement regarding the static memory limits (`PLAT-006`), the algorithm MUST verify the target string length prior to concatenation. If a variable substitution would exceed a static limit (e.g., `Max_Arg_Length`), the system MUST immediately return a controlled domain error (e.g., `Buffer_Overflow`) to prevent an unhandled `Constraint_Error`.
* **Performance Risks:** Deeply nested recursive variable definitions could theoretically consume significant stack memory. However, practical DevOps configurations rarely exceed a nesting depth of 3-5 levels, making this risk negligible in the domain context.
* **Opportunities:** The decoupling of the variable resolution algorithm from the initial graph traversal allows the system to seamlessly merge local `[environment]` variables with live operating system environment variables, providing robust overriding capabilities right before the process execution.

## 4. References

**Internal Documentation:**
* [1] [REQ-001: Project Configuration Handling](../design/REQ-001-project-configuration.md)
* [2] [REQ-002: Operation Orchestration & Execution](../design/REQ-002-operation-orchestration.md)
* [3] [ALG-001: Topological Sorting and Cycle Detection](./ALG-001-topological-sort.md)