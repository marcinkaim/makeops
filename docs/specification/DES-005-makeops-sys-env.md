<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# DES-005 MakeOps.Sys.Env Package Design

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `DES-005` |
| **Status** | `APPROVED` |
| **Date** | 2026-03-03 |
| **Target Package** | `MakeOps.Sys.Env` |

## 1. Scope & Responsibility

* **Goal:** Serves as the safe, exception-free OS adapter for querying host environment variables.
* **Responsibility:**
    * Interrogates the underlying Linux environment for the presence and value of specific variables.
    * Implements Graceful Degradation by returning a deterministic "Not Found" state instead of crashing when a variable is missing.
* **Out of Scope:** This package strictly fetches raw byte strings from the OS. It MUST NOT parse, evaluate, or substitute nested `${...}` variables (this is delegated to the variable substitution engine within the Execution Plan Resolution model `MOD-004`). It does not modify the OS environment.

## 2. Traceability & Dependencies

* **Implements Requirements:**
    * `REQ-002` (Operation Orchestration & Execution):
        * `F-002-004`: Requires sourcing dynamic environment variables from the OS to safely substitute them into operational commands.
    * `REQ-004` (Global Tool Preferences):
        * `F-004-005`: Demands the ability to read environmental overrides (e.g., `MKO_LOG_LEVEL`) to configure the application behavior.
* **Applies Concepts:**
    * `MOD-009` (Formal Verification & Static Memory Foundations): Dictates the translation of unpredictable native exceptions into deterministic variant records and mandates the use of bounded strings to enforce memory safety.
    * `MOD-011` (Isolated OS Boundaries and Exception Handling): Provides the strategy for Exception Isolation and Graceful Degradation using the Dual-Pragma boundary pattern.
    * `MOD-014` (Environment Variables & Shadowing Model): Establishes the rules for extracting the `OS_Env` namespace safely.
* **Intra-Project Dependencies:**
    * `None`: This package operates as an independent, foundational OS adapter and does not depend on any other packages within the project's namespace.
* **Standard Library Dependencies:**
    * `Ada.Strings.Bounded`: Utilized in the specification to instantiate `Env_Name_Strings` and `Env_Value_Strings`, enforcing the strict static memory model (Zero-Allocation) for variable keys and values.
    * `Ada.Environment_Variables`: Utilized exclusively in the package body to perform the actual OS environment queries (`Exists` and `Value`). This dependency is safely encapsulated within the `pragma SPARK_Mode (Off)` boundary to trap native exceptions and guarantee Graceful Degradation.

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * `Max_Env_Var_Name_Length` / `Max_Env_Var_Value_Length`: Static bounds defining the maximum physical byte lengths for keys (64 bytes) and values (32768 bytes).
    * `Env_Name_String` / `Env_Value_String`: Bounded string types enforcing the predefined static memory limits.
    * `Query_Status`: An enumeration (`Found`, `Not_Found`, `Too_Long`) representing the deterministic outcome of the OS query.
    * `Env_Result`: A discriminated variant record parameterized by `Query_Status`. It safely encapsulates the `Value` only when the status is `Found`, guaranteeing memory safety and Fail-Fast behavior without exposing invalid states.
* **Main Subprograms:**
    * `Get`: Safely interrogates the underlying Linux environment for the presence and value of a specific variable. It accepts an `Env_Name_String` and deterministically returns an `Env_Result`.
* **Formal Contracts & Invariants (SPARK):**
    * The package specification MUST be marked with the `pragma SPARK_Mode (On)` constraint.
    * It maintains no mutable global state. The overarching invariant is defined by the `Env_Result` structure, which mathematically guarantees that querying the OS will resolve to a predictable state without ever propagating an exception to the verified orchestration engine.

## 4. Implementation Guidelines (.adb details)

* **Algorithmic Flow & Models:** The implementation prioritizes avoiding exception-driven control flow, relying on proactive existence checks before interacting with volatile OS environment variables.
    * `Get`: Must first verify the variable's existence using native checks (e.g., `Ada.Environment_Variables.Exists`) to prevent baseline exceptions. Upon fetching the raw value, it must perform an immediate Fail-Fast boundary check against `Max_Env_Var_Value_Length`. If the value exceeds this static limit, it must return a `Too_Long` status rather than attempting truncation. All underlying operations must be wrapped in a global exception trap (`when others`) that silently degrades to a `Not_Found` status to strictly guarantee the Absence of Runtime Errors (AoRE).
* **Memory & SPARK Constraints:** The bounded strings rigorously enforce the Static Memory Model (Zero-Allocation). Constraint errors during the conversion of native OS strings to bounded strings are mathematically prevented by the upfront length validation check.
* **Boundary & Exception Handling:** The package body MUST be marked with `pragma SPARK_Mode (Off)` to isolate the unprovable interactions with `Ada.Environment_Variables`. All standard library calls must be encapsulated within a general exception trap (`when others`) that returns a safe `Not_Found` status, strictly enforcing the Absence of Runtime Errors (AoRE) at the OS boundary.