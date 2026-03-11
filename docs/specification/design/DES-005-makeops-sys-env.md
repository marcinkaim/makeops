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
* **Out of Scope:** This package strictly fetches raw byte strings from the OS. It MUST NOT parse, evaluate, or substitute nested `${...}` variables (this is delegated to the Lazy Variable Substitution algorithm `ALG-002`). It does not modify the OS environment.

## 2. Traceability & Dependencies

* **Implements Requirements:**
    * `REQ-002` (Operation Orchestration: dynamic variable substitution requires OS variable sourcing).
    * `REQ-004` (Global Tool Preferences: reading overrides like `MKO_LOG_LEVEL`).
* **Applies Concepts:**
    * `PLAT-004` (Linux Environment and FS Adapters: Exception Isolation).
    * `PLAT-005` (SPARK Formal Verification: Translating native exceptions to discriminated variant records).
    * `PLAT-006` (Static Memory Model: Enforcing bounded string types for maximum memory safety).
    * `PLAT-014` (Environment Variables Model: Treating OS env values as raw terminal values).
* **Internal Package Dependencies:** None.

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * `Max_Env_Var_Name_Length`: A static constant (64) defining the maximum byte length of an environment variable key (from `PLAT-006`).
    * `Max_Env_Var_Value_Length`: A static constant (32768) defining the maximum byte length of an environment variable value.
    * `Env_Name_String`: A bounded string type (capacity `Max_Env_Var_Name_Length`) for variable keys.
    * `Env_Value_String`: A bounded string type (capacity `Max_Env_Var_Value_Length`) for variable values.
    * `Query_Status`: An enumeration (`Found`, `Not_Found`, `Too_Long`) representing the outcome of the query.
    * `Env_Result`: A discriminated variant record (parameterized by `Query_Status`). If `Found`, it contains the `Env_Value_String`. If `Not_Found` or `Too_Long`, it contains no string data, guaranteeing memory safety and Fail-Fast behavior.
* **Main Subprograms:**
    * `Get`: A function accepting an environment variable name (as a bounded string) and returning an `Env_Result`.
* **Invariants & Contracts (Conceptual):**
    * The package specification (`.ads`) MUST be marked with `pragma SPARK_Mode (On)` to ensure the `Env_Result` data flow can be mathematically proven by the core engine.

## 4. Implementation Guidelines (.adb details)

* **Implementation Scope:** The package body (`.adb`) MUST be marked with `pragma SPARK_Mode (Off)`.
* **OS / Standard Library Interactions:** Use `Ada.Environment_Variables.Exists` first to check presence, then use `Ada.Environment_Variables.Value` to retrieve the content. Check the string length against `Max_Env_Var_Value_Length` to return `Too_Long` instead of relying on Ada string exceptions (Fail-Fast).
* **Exception Trapping:** Wrap the standard library calls in a general exception block (`when others`) to trap any unexpected OS-level I/O or tasking exceptions and return `Not_Found`, strictly guaranteeing the Absence of Runtime Errors (AoRE).

## 5. Verification Strategy

* **Static Proof (GNATprove):** The interface must be fully proven to allow safe consumption by `ALG-002`.
* **AUnit Test Scenarios:**
    * **Happy Path:** Query a known standard Linux variable (e.g., `PATH` or `USER`) and assert the result is `Found`.
    * **Edge Cases:** Query a deliberately non-existent variable (e.g., `MKO_NON_EXISTENT_VAR_123`) and assert the result is `Not_Found` without throwing an exception.
    * **Fail-Fast Boundaries:** Set an environment variable exceeding `Max_Env_Var_Value_Length` (32768 bytes) and assert the result is `Too_Long` to ensure it does not crash or silently truncate data.
