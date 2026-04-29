<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# MOD-004 Execution Plan Resolution

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `MOD-004` |
| **Status** | `APPROVED` |
| **Date** | 2026-04-06 |
| **Tags** | DAG, Topological Sort, Variable Substitution, Resolver, Execution Queue |

## 1. Definition & Context
Execution Plan Resolution defines the mathematical and logical transformation phase within the MakeOps architecture. It is the domain of the Transformation Sub-Orchestrator (`MakeOps.Core.Project.Operation.Resolver`).

In the context of the MakeOps 5-step Master Orchestration Lifecycle, this model bridges the gap between static domain knowledge (the raw `Project_Config` parsed from TOML) and dynamic physical execution. It is responsible for mathematically proving that the user's defined operations are logically sound, determining their correct sequential order, evaluating dynamic variables, and returning a strictly validated `Execution_Queue` ready for the POSIX engine.

## 2. Theoretical Basis
This phase relies on the mathematics of Directed Acyclic Graphs (DAG) and the principles of late-bound (lazy) string interpolation.

### 2.1. Directed Acyclic Graphs (DAG)
The execution dependencies form a graph $G = (V, E)$, where the set of vertices $V$ represents the discrete operations, and the directed edges $E$ represent the dependencies (`deps`). 
A directed edge $B \to A$ mathematically implies that the completion of $B$ is a temporal prerequisite for $A$. For the graph to be solvable, it must strictly satisfy the acyclicity invariant: there must be no path $v_1 \to v_2 \to \dots \to v_k$ such that $v_1 = v_k$. The presence of a cycle indicates an impossible temporal paradox.

### 2.2. Lazy Evaluation and Interpolation
Variables defined in the project environment can recursively reference each other. To optimize evaluation and handle forward-references, the system employs Lazy Evaluation. Variables are evaluated exclusively if they are present in the command strings of the operations that have actually been queued for execution. To ensure predictable interpolation without infinite recursion, the variable dictionary itself forms an implicit secondary DAG that must be cycle-checked during evaluation.

## 3. Conceptual Model
The Resolver orchestrates two highly encapsulated, mathematically pure mechanisms: the Graph Builder and the Variable Substitution engine.

### 3.1. Topological Sorting and the Virtual Root
To flatten the multi-dimensional DAG into a linear `Execution_Queue`, the Resolver utilizes a Depth-First Search (DFS) topological sort algorithm. 
* **The Virtual Root Pattern:** Because a user can request multiple discrete targets via the CLI (e.g., `mko build test`), the Resolver temporarily injects a `Virtual_Root` node into the graph. Its adjacency list points to all requested targets. Running the DFS from this single root naturally resolves the unified dependency tree.
* **Cycle Detection:** During traversal, nodes transition through three states: `Unvisited` $\to$ `Resolving` $\to$ `Resolved`. If the DFS encounters a node currently in the `Resolving` state (meaning it is already in the active call stack), it mathematically proves a back-edge (cycle) exists, triggering an immediate Fail-Fast abort.

### 3.2. Memoized Variable Substitution
Once the operations are sorted, the Resolver passes the queue to the Variable Substitution engine to evaluate markers (e.g., `${VAR}`).
* **Cycle Prevention:** The engine maintains an internal call stack of currently resolving variables. Encountering the same variable twice in this stack triggers a `Circular_Variable_Reference` abort.
* **Memoization:** Fully resolved variables are cached, guaranteeing $O(1)$ lookup times for subsequent references.
* **Shadowing Hierarchy:** The engine enforces strict namespace priorities. If a variable exists in the project's `makeops.toml` environment, it strictly overrides (shadows) any matching variable from the OS environment (`OS_Env`).
* **Terminal OS Variables:** For security against Interpolation Injection, variables originating from the `OS_Env` are treated as raw terminal bytes. The engine will NEVER recursively evaluate `${...}` markers found inside OS-provided environment variables.

### 3.3. The Resolver Control Flow
1. Accept the raw `Project_Config` and a list of `Target_Operations`.
2. Inject the `Virtual_Root` and invoke the Graph Builder.
3. If cycles or dangling dependencies are found, abort. Otherwise, receive the sorted queue.
4. Pass the sorted queue to the Variable Substitution engine.
5. If missing variables or reference cycles are found, abort. Otherwise, substitute all command strings.
6. Return the finalized `Execution_Queue`.

## 4. Engineering Impact

* **Constraints:** To ensure absolute mathematical purity and satisfy SPARK verification, both algorithms (Graph Builder and Variable Substitution) MUST be encapsulated in `private` child packages (`MakeOps.Core.Project.Operation.Graph_Builder` and `MakeOps.Core.Project.Config.Variable_Substitution`). They MUST be invoked exclusively by the `Resolver`.
* **Memory/Performance Risks:** During variable substitution, the concatenation of strings MUST be mathematically bounds-checked against the `Max_Arg_Length` limit defined in the Static Memory Model. If a substitution would exceed this bound, the engine MUST halt with a `Buffer_Overflow` domain error to guarantee the Absence of Runtime Errors (AoRE).
* **Opportunities:** By fully decoupling this resolution phase from the I/O parsers (Loaders) and the POSIX OS bindings (Executors), the complex DAG and substitution mathematics can be exhaustively unit-tested purely in memory, without ever needing to spawn a real process or read a real file.

## 5. References

**Internal Documentation:**
* [1] [MOD-001: Master Orchestration Lifecycle](./MOD-001-master-orchestration-lifecycle.md)
* [2] [MOD-009: Formal Verification & Static Memory Foundations](./MOD-009-formal-verification-static-memory.md)
* [3] [MOD-014: Environment Namespaces & Shadowing Model](./MOD-014-env-variables-shadowing-model.md)

**External Literature:**
* [4] Cormen, T. H., Leiserson, C. E., Rivest, R. L., & Stein, C. (2009). *Introduction to Algorithms* (3rd ed.). MIT Press. (Chapter 22.4: Topological Sort).