<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# MATH-001 Directed Acyclic Graph Model

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `MATH-001` |
| **Status** | `APPROVED` |
| **Date** | 2026-02-21 |
| **Category** | Math Theory |
| **Tags** | DAG, Graph Theory, Dependencies, Operations, Topological Sort |

## 1. Definition & Context
A Directed Acyclic Graph (DAG) is a conceptual mathematical model representing a collection of discrete objects (vertices) and the directional relationships (edges) between them, with the strict condition that it is impossible to start at any vertex and follow a consistently-directed sequence of edges that loops back to the starting vertex. 

In the context of the **MakeOps** project, the DAG is the fundamental mathematical structure used to model project execution dependencies. It guarantees a deterministic and logical execution order for user-defined operations, ensuring that all prerequisites of a task are met before the task itself is invoked.

## 2. Theoretical Basis
Formally, we define our execution graph as $G = (V, E)$, where $V$ is the set of vertices and $E$ is the set of directed edges.

### 2.1. Vertices ($V$) - Operations
The set $V$ represents all unique operations defined by the user in the configuration file (under `[operations.<name>]` sections). 
* **Identity:** Each vertex $v \in V$ is uniquely identified by its operation name.
* **State & Metadata:** Each vertex encapsulates its execution parameters, specifically the binary command (`cmd`) and its arguments (`args`). 
* **Execution Invariant:** Mathematically, regardless of the in-degree (number of incoming edges), each vertex $v$ can be visited (executed) exactly once per graph traversal.

### 2.2. Edges ($E$) - Dependencies
The set $E$ represents the precedence constraints derived from the `deps` arrays.
* **Directionality:** If operation $A$ depends on operation $B$ ($B$ is listed in the `deps` of $A$), we define a directed edge from $B$ to $A$, denoted as $(B, A) \in E$ or $B \to A$.
* **Semantic Meaning:** The direction $B \to A$ symbolizes the flow of time and "readiness". It mathematically implies: *The completion of $B$ is a prerequisite that unlocks the possibility of executing $A$.*

### 2.3. Acyclicity (The Non-Cyclic Invariant)
For $G$ to be a valid DAG, it must satisfy the acyclicity property.
* **Definition:** There must be no path $v_1 \to v_2 \to \dots \to v_k$ such that $v_1 = v_k$. 
* **Domain Context:** If a cycle exists (e.g., $A \to B \to A$), the system represents an impossible temporal paradox where an operation is a prerequisite for itself. Such a graph is unsolvable and invalid.

## 3. Engineering Impact

* **Constraints:** The system architecture must actively enforce the acyclicity invariant. During the parsing or resolution phase, the internal engine MUST reject configurations that contain cycles, satisfying the requirement NFR-001-002.
* **Algorithm Selection:** The formalization of $B \to A$ as a readiness flow dictates the choice of traversal algorithms. The system must utilize algorithms capable of topological sorting (e.g., Kahn's algorithm or Depth-First Search with cycle detection) to yield a valid linear execution sequence.
* **Data Structures:** The abstract set $V$ will translate to a Hash Map or Dictionary in Ada, mapping string identifiers to Operation record types. The set $E$ will map to adjacency lists associated with each vertex record.
* **Opportunities (Future-Proofing):** By strictly adhering to a mathematical DAG model, the system intrinsically supports future parallel execution optimizations. Vertices with an in-degree of $0$ can be executed concurrently without violating causality.

## 4. References

**Internal Documentation:**
* [1] [REQ-001: Project Configuration Handling](../design/REQ-001-project-configuration.md)
* [2] [REQ-002: Operation Orchestration & Execution](../design/REQ-002-operation-orchestration.md)

**External Literature:**
* [3] Cormen, T. H., Leiserson, C. E., Rivest, R. L., & Stein, C. (2009). *Introduction to Algorithms* (3rd ed.). MIT Press. (Section 22.4: Topological sort; Section 22.5: Strongly connected components).