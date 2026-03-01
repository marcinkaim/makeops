<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# ALG-003 Hierarchical Configuration Cascade

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `ALG-003` |
| **Status** | `APPROVED` |
| **Date** | 2026-02-22 |
| **Category** | Algorithm |
| **Tags** | Configuration, Cascade, Bottom-Up, Fail-Fast, Observability |

## 1. Definition & Context
The hierarchical configuration cascade is the deterministic algorithm used to resolve the final runtime preferences of the MakeOps tool (`mko`). It evaluates settings across a strict 5-level precedence hierarchy: Hardcoded Defaults $\to$ System-wide Config $\to$ User-specific Config $\to$ Environment Variables $\to$ CLI Flags.

In the context of the **MakeOps** project, this algorithm ensures that while individual projects remain deterministic, users and automated environments (like CI/CD pipelines) can safely impose global operational preferences (such as the default `Project_Config` to target, or the `Log_Level`) without modifying the source-controlled project repositories.

## 2. Theoretical Basis
The algorithmic design strictly separates the impure data acquisition phase (I/O, parsing) from the pure logical merging phase. This separation is governed by two theoretical mechanisms: Bottom-Up Merging and Deferred Observability.

### 2.1. Bottom-Up Merging with Partial Structures
To safely overlay sparse configuration data, layers 2 through 5 are modeled as "Partial Configurations" where any given field may hold a `Not_Set` state. The cascade utilizes a Bottom-Up mutation strategy: it initializes a complete base record using Layer 1 (Hardcoded Defaults) and sequentially overlays subsequent layers. An overwrite operation for a specific field only occurs if the overlaying layer explicitly defines a value (i.e., is not `Not_Set`), thus guaranteeing that the final configuration record is mathematically complete and free of missing data.

### 2.2. Fail-Fast Parsing vs. Deferred Observability
The algorithm enforces a strict bifurcation in error handling:
1. **Structural Integrity (Fail-Fast):** If a configuration source contains malformed syntax or unrecognized values (e.g., a typo in a log level), the parsing subroutines immediately abort execution.
2. **Environmental Absence (Deferred Observability):** If optional configuration files (e.g., `/etc/makeops/config.toml`) are missing or unreadable due to permissions, the system does not crash. However, because the final `Log_Level` is unknown until the entire cascade resolves, the system buffers these non-critical I/O warnings. The buffer is only flushed to standard error at the very end of the process, and only if the finalized settings permit it.

### 2.3. Structured Algorithmic Description
The following is a structured definition of the hierarchical configuration cascade.

**Inputs:**
* `System_Config_Path`: Path to `/etc/makeops/config.toml`
* `User_Config_Path`: Path to `~/.config/makeops/config.toml`
* `CLI_Arguments`: Raw arguments provided via the command line.
* `OS_Env`: The system environment variables context.

**Outputs:**
* `Final_Config`: A fully resolved configuration record containing `Log_Level`, `Project_Config`, and `Allow_Root` fields (none of which are `Not_Set`).
* An error `Invalid_Syntax` or `Invalid_Value` if malformed data or typos are encountered during loading (Fail-Fast).

**Procedure `Merge_Layers(Config_Layers)`:**
*Note: `Config_Layers` is an array of 5 `Partial_Config` records.*
1. Set `Merged := Config_Layers[1]`
2. For each `Layer_Index` in `2 .. 5` loop:
   * Set `Current_Layer := Config_Layers[Layer_Index]`
   * Check `Current_Layer.Log_Level`:
     * **If `Not_Set`:** Proceed to next step.
     * **If other:** Set `Merged.Log_Level := Current_Layer.Log_Level`
   * Check `Current_Layer.Project_Config`:
     * **If `Not_Set`:** Proceed to next step.
     * **If other:** Set `Merged.Project_Config := Current_Layer.Project_Config`
   * Check `Current_Layer.Allow_Root`:
     * **If `Not_Set`:** Proceed to next step.
     * **If other:** Set `Merged.Allow_Root := Current_Layer.Allow_Root`
3. Return `Merged`

**Main Execution Flow:**
1. Set `Warnings_Buffer := Empty_List`
2. Set `Config_Layers := Empty_Array` (size 5)
3. *Level 1: Hardcoded Defaults*
   * Set `Config_Layers[1] := Create_Default_Config()` 
     *(Implicitly sets Log_Level := Info, Project_Config := "makeops.toml", Allow_Root := False)*
4. *Level 2: System-wide Configuration*
   * Set `Config_Layers[2] := Load_Toml_Config(System_Config_Path, Warnings_Buffer)`
5. *Level 3: User-specific Configuration*
   * Set `Config_Layers[3] := Load_Toml_Config(User_Config_Path, Warnings_Buffer)`
6. *Level 4: Environment Variables*
   * Set `Config_Layers[4] := Load_Env_Config(OS_Env)`
7. *Level 5: CLI Flags*
   * Set `Config_Layers[5] := Load_CLI_Config(CLI_Arguments)`
8. *Cascade Resolution:*
   * Set `Final_Config := Merge_Layers(Config_Layers)`
9. *Flush Warnings (Observability Enforcement):*
   * Check `Final_Config.Log_Level`:
     * **If `Error`:** Proceed to step 10.
     * **If other:** * For each `Warning` in `Warnings_Buffer` loop:
         * Call `Print_To_Stderr(Warning)`
10. Return `Final_Config`

## 3. Engineering Impact

* **Constraints:** The implementation MUST utilize a domain-specific generic `Optional` (or `Maybe`) type wrapper in Ada to safely represent the `Not_Set` state in partial configuration records. The merging logic MUST remain side-effect free.
* **Performance Risks:** Minimal. While file system I/O is inherently slow, evaluating a maximum of two lightweight TOML files during process initialization introduces a negligible overhead ($O(1)$ time complexity bounded by constant file sizes).
* **Opportunities:** By isolating the `Merge_Layers` procedure from the `Load_*` routines, the core cascade logic becomes completely independent of the file system or operating system bindings. This allows for exhaustive, deterministic unit testing of the precedence rules purely in memory.

## 4. References

**Internal Documentation:**
* [1] [REQ-003: Execution Observability](../design/REQ-003-execution-observability.md)
* [2] [REQ-004: Global Tool Preferences](../design/REQ-004-global-preferences.md)