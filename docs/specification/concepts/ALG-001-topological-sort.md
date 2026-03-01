<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# ALG-001 Topological Sorting and Cycle Detection

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `ALG-001` |
| **Status** | `APPROVED` |
| **Date** | 2026-02-21 |
| **Category** | Algorithm |
| **Tags** | DAG, Topological Sort, DFS, Cycle Detection, Graph Theory |

## 1. Definition & Context
Topological sorting is an algorithmic process of arranging the vertices of a Directed Acyclic Graph (DAG) into a linear sequence such that for every directed edge $U \to V$, vertex $U$ comes before vertex $V$ in the ordering. Cycle detection is the concurrent process of proving that the graph contains no closed loops.

In the context of the **MakeOps** project, this combined algorithm is the computational heart of the orchestration engine. It translates the mathematical graph model (`MATH-001`) into a deterministic execution queue, ensuring that all prerequisite operations are completed before their dependents begin, while strictly rejecting invalid, circular configurations.

## 2. Theoretical Basis
The algorithm utilizes a Depth-First Search (DFS) traversal augmented with a 3-state tracking mechanism. Instead of classical color-coding (White, Gray, Black), it uses domain-agnostic states representing the resolution phase of each node.

### 2.1. Node Lifecycle and State Semantics
The lifecycle of any single node during the algorithm's execution is strictly linear: `Unvisited` $\to$ `Resolving` $\to$ `Resolved`. The algorithm leverages these states not as a complex state machine, but as memory markers to dictate the control flow when a node is encountered during traversal.

* **`Unvisited`:** The initial state. It indicates that the node has not yet been discovered by any branch of the Depth-First Search. Encountering this state triggers the algorithm to begin analyzing the node's dependencies.
* **`Resolving`:** The active state. It indicates that the node is currently in the recursive call stack. The algorithm is currently traveling down its dependency chain. **Crucial property:** If the algorithm encounters a node that is already in the `Resolving` state, it proves the existence of a back-edge (a cycle).
* **`Resolved`:** The terminal state. It indicates that the node, and its entire downstream sub-graph of dependencies, have been fully validated and appended to the final execution queue. **Crucial property:** If the algorithm encounters a node in this state, it safely skips it, guaranteeing that no operation is queued or analyzed more than once, even if multiple operations depend on it.

### 2.2. Structured Algorithmic Description
The following is a language-agnostic, structured definition of the traversal logic.

**Inputs:**
* `Graph`: A dictionary mapping a `Node_ID` to a `Graph_Node` structure. Each node contains a `State` (initially `Unvisited`) and an `Adjacency_List` (dependencies).
* `Start_Node`: The `Node_ID` from which the traversal begins.

**Outputs:**
* `Sorted_List`: A linear sequence of `Node_ID`s sorted topologically (post-order).
* An error `Cycle_Detected` if a closed loop is found.

**Procedure `Visit_Node(Current_ID)`:**
1. Set `Node := Graph[Current_ID]`
2. Check `Node.State`:
   * **If `Resolving`:** Abort traversal. Return Error: `Cycle_Detected` (a back-edge to a node currently in the call stack has been found).
   * **If `Resolved`:** Return and terminate this branch (the node and its downstream subgraph have already been fully processed).
   * **If `Unvisited`:** Proceed to step 3.
3. Set `Node.State := Resolving` and update `Node` in `Graph`
4. For each `Dependency_ID` in `Node.Adjacency_List` loop:
   * Call `Visit_Node(Dependency_ID)`
5. Set `Node.State := Resolved` and update `Node` in `Graph`
6. Call `Sorted_List.Append(Current_ID)`

**Main Execution Flow:**
1. Set `Sorted_List := Empty_List`
2. Call `Visit_Node(Start_Node)`
3. Return `Sorted_List`

### 2.3. Traversal Control Flow
The following diagram illustrates the recursive decision tree and iteration loop executed by the `Visit_Node` procedure when it evaluates a node's state.

```text
 +-------------------------------------------------------+
 |                Visit_Node(Current_ID)                 |
 +-------------------------------------------------------+
                             |
                             v
               +---------------------------+
               |    Check Node.State       |
               +---------------------------+
                 /           |           \
                /            |            \
     +-------------+   +------------+   +-------------+
     | Resolving   |   | Resolved   |   | Unvisited   |
     +-------------+   +------------+   +-------------+
           |                 |                 |
           v                 v                 v
  +----------------+   +------------+   +--------------------+
  | RETURN ERROR   |   |   RETURN   |   | State := Resolving |
  | Cycle Detected |   | Skip (Done)|   +--------------------+
  +----------------+   +------------+            |
                                                 v
                                        +--------------------+
                                  +---->|  For each Dep_ID   |----+
                                  |     |  in Adjacency_List |    |
                                  |     +--------------------+    |
                                  |              |                |
                                  |     (Has next|Dep_ID)         | (Empty / Done)
                                  |              v                |
                                  |     +--------------------+    |
                                  +-----| Visit_Node(Dep_ID) |    |
                                        +--------------------+    |
                                                                  v
                                                        +--------------------+
                                                        | State := Resolved  |
                                                        +--------------------+
                                                                  |
                                                                  v
                                                        +--------------------+
                                                        | Append Current_ID  |
                                                        | to Sorted_List     |
                                                        +--------------------+
```

## 3. Engineering Impact
* **Constraints:**
   * The algorithm MUST be strictly isolated from the execution environment. The topological sort must be fully computed and validated before any system process is spawned.
   * **Virtual Root Pattern (Multiple Targets):** To support the execution of multiple independent targets from a single CLI invocation (e.g., `mko build test`), the orchestration layer MUST construct a temporary "Virtual Root" node prior to invoking this algorithm. This virtual node will have no command of its own, but its `Adjacency_List` will contain all the targeted operations. Passing this single virtual node as the `Start_Node` allows the unmodified DFS algorithm to natively resolve the combined dependency tree while guaranteeing the exactly-once execution invariant.
* **Opportunities:** By outputting a flat `Sorted_List`, the algorithmic complexity is entirely removed from the system execution layer. The orchestrator merely needs to iterate over the resulting list linearly ($O(N)$), executing commands sequentially.
* **Performance Risks:** Because this is a recursive DFS implementation, heavily chained dependencies could theoretically lead to call stack exhaustion. However, in the domain context of DevOps configurations (MakeOps), the maximum graph depth is orders of magnitude smaller than typical OS thread stack limits.

## 4. References

**Internal Documentation:**
* [1] [MATH-001: Directed Acyclic Graph Model](../concepts/MATH-001-dag-model.md)
* [2] [REQ-001: Project Configuration Handling](../design/REQ-001-project-configuration.md)
* [3] [REQ-002: Operation Orchestration & Execution](../design/REQ-002-operation-orchestration.md)

**External Literature:**
* [4] Cormen, T. H., Leiserson, C. E., Rivest, R. L., & Stein, C. (2009). *Introduction to Algorithms* (3rd ed.). MIT Press. (Section 22.4: Topological sort; Section 22.5: Strongly connected components).