[![License: GPL-3.0-or-later](https://img.shields.io/badge/License-GPL--3.0--or--later-blue.svg)](LICENSES/GPL-3.0-or-later.txt)
[![REUSE status](https://api.reuse.software/badge/github.com/marcinkaim/makeops)](https://api.reuse.software/info/github.com/marcinkaim/makeops)

# MakeOps

**MakeOps** is a deterministic DevOps task runner designed to orchestrate complex project operations with mathematical precision. Inspired by the utility of GNU Make, MakeOps modernizes the concept by separating configuration from logic.

Instead of embedding shell scripts, MakeOps defines tasks, dependencies, and execution arguments in a strictly typed `makeops.toml` configuration file. It constructs a directed acyclic graph (DAG) of dependencies to execute tasks in the correct order, ensuring a reliable and reproducible operational environment.

**Key Features:**
* **Dependency Resolution:** Automatically resolves and executes task chains defined in `[tasks.TASK_NAME]` sections.
* **Pure Execution:** Disallows embedded shell scripting to enforce security and clarity; executes explicit binaries and scripts with strict argument passing.
* **Configuration Logic:** Supports variable substitution (`${VAR_NAME}`) via a dedicated `[vars]` section.

## 🚀 Technology Stack

MakeOps is built using a **Deep Tech** approach, minimizing external dependencies and leveraging the robustness of the Ada 2022 standard.

* **Language:** Ada 2022 (with SPARK verification subsets) for safety-critical logic.
* **Build System:** GPRbuild (Project Manager & Builder).
* **Testing:** AUnit (xUnit framework for Ada).
* **Runtime:** Static linking with the GNAT Runtime Library (RTL).
* **Platform Target:** Linux (Developed on Debian 13 Trixie, optimized for generic and high-performance hardware).

## 🛠️ Prerequisites

To build and contribute to MakeOps, the following tools are required in your development environment:

* **GNAT Toolchain:** A generic Ada compiler supporting Ada 2022 (e.g., GNAT FSF).
* **GPRbuild:** The project manager for building multi-language systems.
* **GNU Make:** Currently used as the operations facade for bootstrapping the project.
* **Git:** For version control and repository synchronization.

## 🏗️ Build Instructions

This project uses a `Makefile` facade to wrap `gprbuild` commands for ease of use.

**1. Development Build (Default)**
Compiles the project with debug symbols and assertions enabled.
```bash
make
# or explicitly:
make build
```

**2. Production Build**
Compiles the project with full optimizations (Build Mode: `prod`).

```bash
make release
```

**3. Running Tests**
Builds the test suite and executes the AUnit test runner.

```bash
make test
```

**4. Maintenance**
To clean all build artifacts and object files:

```bash
make clean
```

## 🧠 Development Methodology

This project adopts a rigorous, engineering-first approach combining two key philosophies to ensure mathematical correctness and software reliability:

### 1. Knowledge-Based Analysis (KBA)
We believe that understanding precedes specification. Before defining *how* the system behaves, we analyze *what* is mathematically and physically possible based on **First Principles**.
* **Outcome:** Mathematical proofs, algorithmic theories, and hardware constraint models.
* **Location:** `specification/concepts`

### 2. Specification-Driven Development (SDD)
Code is a liability; specification is an asset. We write normative Requirements (`REQ`) and Technical Specifications (`SPEC`) before writing the implementation. This separates the **Design Phase** from the **Coding Phase**.
* **Outcome:** Verifiable requirements and architecture definitions.
* **Location:** `specification/design`

## 📂 Repository Structure

The repository follows a strict separation of concerns, distinguishing between theoretical proofs, normative specifications, and source implementation.

```text
/makeops
├── devops/                     # Operations & DevOps
│   └── scripts/                # Automation scripts (git sync, license check)
├── docs/                       # Project Documentation
│   ├── manual/                 # End-user guides and manuals
│   └── specification/          # The Knowledge Base and Specifications
│       ├── concepts/           # Theoretical Basis: Math, Algorithms (ALG), Platform Constraints (PLAT)
│       └── design/             # Normative Specs: Requirements (REQ), Specifications (SPEC)
├── LICENSES/                   # License texts (REUSE compliance)
├── source/                     # Source Code (Ada 2022)
│   ├── app/                    # Application Entry Point & CLI Drivers
│   ├── core/                   # Core Logic: TOML Parsing, Dependency Graph, Execution Engine
│   ├── sys/                    # System Interface: OS Bindings & Process Management
│   ├── tests/                  # AUnit Test Suites & Scenarios
│   ├── makeops_app.gpr         # Main Application Project Definition
│   └── makeops_tests.gpr       # Unit Testing Project Definition
├── .gitignore                  # Git exclusion rules
├── LICENSE                     # GPLv3 license
├── Makefile                    # Operations Facade (build, test, push)
├── makeops.gpr                 # Master GPR Aggregate Project
├── README.md                   # This document
└── REUSE.toml                  # REUSE Specification
```

## 🔄 Development Workflow

### Syncing with GitHub

This project uses a custom script to handle secure pushing to the remote repository.

1. Create a `.secrets` file in the root directory (this file is git-ignored):
    ```bash
    export GITHUB_USER="your-username"
    export GITHUB_REPO="makeops"
    export GITHUB_TOKEN="your-personal-access-token"
    ```

2. Push changes:
    ```bash
    make push
    ```


## 📜 License

**MakeOps** is Free Software: you can redistribute it and/or modify it under the terms of the **GNU General Public License** as published by the Free Software Foundation, either **version 3** of the License, or (at your option) **any later version**.

This project is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY. See the [`LICENSE`](LICENSES/GPL-3.0-or-later.txt) file for more details.