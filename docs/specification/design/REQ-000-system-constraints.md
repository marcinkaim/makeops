<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# REQ-000 System Constraints

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `REQ-000` |
| **Status** | `APPROVED` |
| **Date** | 2026-02-20 |
| **Capability Type** | System-Internal |
| **References** | N/A (Root Document) |

## 1. Capability Description (The "What" & "Why")
* **Definition:** Global architectural, technological, and legal constraints imposed on the entire MakeOps system.
* **User Value / Rationale:** Centralizing non-functional platform requirements in one place prevents redundancy in other specification documents. This ensures mathematical correctness, security (Deep Tech approach), and the consistency of the technology stack.
* **Dependencies:** None. This is the root document from which all other Capability specifications (`REQ-001`+) inherit their base constraints.

## 2. Functional Requirements (Behavior)
*Since this is a global constraints document, functional behaviors are limited to the most general rules of system interaction with the target platform.*

* **F-000-001:** The system SHALL communicate with the operating system through standard exit codes (e.g., `Exit_Success`, `Exit_Failure`) defined in the `makeops-app.ads` package.
* **F-000-002:** The system SHALL execute operations via explicit binary and script invocations with strictly passed arguments, without utilizing embedded shell scripts.

## 3. System Constraints & Quality Attributes (NFRs)
*Fundamental technological and architectural constraints for the entire project.*

* **NFR-000-001 (Programming Language):** The source code MUST be written in the Ada 2022 standard.
* **NFR-000-002 (Security and Verification):** Critical logic MUST utilize SPARK verification subsets to statically prove the absence of runtime errors.
* **NFR-000-003 (Target Platform):** The system MUST compile and be fully operational on Linux, specifically targeting Debian 13 "Trixie".
* **NFR-000-004 (Dependencies and Linking):** The system MUST be statically linked with the GNAT Runtime Library (RTL) without unnecessary external dependencies.
* **NFR-000-005 (External Tools):** The system MUST use GPRbuild for project management and the AUnit framework for unit testing.
* **NFR-000-006 (Licensing):** All source code MUST be licensed under GPL-3.0-or-later and MUST be fully compliant with the REUSE specification.
* **NFR-000-007 (Executable Naming):** The compiled binary of the MakeOps application MUST be named `mko` to provide a concise, Unix-like command-line interface.

## 4. Input / Output Data Model
*A high-level black-box perspective of the system.*

* **Inputs:**
  * The `makeops.toml` configuration file.
  * Command Line Interface (CLI) arguments passed via the `mko` command.
  * Operating system environment variables.
* **Outputs:**
  * Standard output and error streams (stdout, stderr).
  * Operating system process exit codes (POSIX).
  * Child process invocations.

## 5. Acceptance Criteria (Definition of Done)
*Global metrics verifying the quality and compliance of the architecture.*

* **AC-000-001:** The project compiles flawlessly using a GNAT toolchain supporting Ada 2022 via the operational facade (`make build`).
* **AC-000-002:** All unit tests run successfully and return a passing result when invoking `make test`.
* **AC-000-003:** The `ensure_license_headers.sh` script confirms the correctness and presence of GPLv3 license headers in all applicable source files.
* **AC-000-004:** SPARK static proofs (GNATprove) for declared contracts (in `.ads` files) guarantee the absence of runtime errors in the core logic (`makeops-core.ads`).
* **AC-000-005:** The build process produces a final executable binary specifically named `mko` in the target artifact directory.