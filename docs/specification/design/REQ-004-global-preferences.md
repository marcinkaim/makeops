<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# REQ-004 Global Tool Preferences

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `REQ-004` |
| **Status** | `DRAFT` |
| **Date** | 2026-02-20 |
| **Capability Type** | User-Facing |
| **References** | `REQ-000`, `REQ-001`, `REQ-003` |

## 1. Capability Description (The "What" & "Why")
* **Definition:** The ability to configure the default behavior of the `mko` command globally (system-wide) or locally (per-user) without modifying the project-specific configuration.
* **User Value / Rationale:** Allows organizations and individual developers to set sane defaults across all their projects. Users can configure parameters such as the default target filename or their preferred logging verbosity (e.g., always running in a quiet or verbose mode) natively within the Linux ecosystem.
* **Dependencies:** Relies on the TOML parsing engine specified in `REQ-001`. Inherits architectural constraints from `REQ-000`. Extends the configuration options utilized by `REQ-003`.

## 2. Functional Requirements (Behavior)
* **F-004-001:** The system SHALL attempt to read system-wide preferences from `/etc/makeops/config.toml`.
* **F-004-002:** The system SHALL attempt to read user-specific preferences from `$XDG_CONFIG_HOME/makeops/config.toml` (defaulting to `$HOME/.config/makeops/config.toml` if the variable is not set).
* **F-004-003:** The system SHALL allow users to define a default configuration file name (e.g., `default_file = "devops.toml"`) within these configuration files.
* **F-004-004:** The system SHALL allow users to define a default logging level (e.g., `verbosity = "verbose"`, `"normal"`, or `"quiet"`) within these configuration files.
* **F-004-005:** The system SHALL support overriding all configuration parameters via specific environment variables (e.g., `MKO_DEFAULT_FILE`, `MKO_VERBOSITY`).
* **F-004-006:** The system SHALL implement a strict 5-level configuration resolution cascade, applying settings in the following order of precedence (from lowest to highest):
    1. Hardcoded application defaults (File: `makeops.toml`, Verbosity: `normal`).
    2. System-wide configuration file.
    3. User-specific configuration file.
    4. Process environment variables.
    5. Command Line Interface (CLI) flags provided to the `mko` command (`-f`, `--verbose`, `--quiet`).
* **F-004-007:** The system SHALL gracefully ignore missing configuration files at the system or user level, seamlessly falling back to lower-priority defaults without emitting errors.

## 3. System Constraints & Quality Attributes (NFRs)
* **NFR-004-001 (Parser Reusability):** The configuration files MUST strictly use the TOML format to allow the reuse of the custom Ada parser developed for `REQ-001`, thereby adhering to the zero-dependency and deep tech philosophy.
* **NFR-004-002 (Fail-Safe Startup):** I/O errors encountered while attempting to read optional preference files (e.g., permission denied) MUST NOT crash the application; they MUST be logged to `stderr` (if verbosity allows) while the system continues execution using fallback defaults.

## 4. Input / Output Data Model
* **Inputs:**
    * File streams from `/etc/makeops/config.toml` and `~/.config/makeops/config.toml`.
    * Environment variables (e.g., `MKO_DEFAULT_FILE`, `MKO_VERBOSITY`).
    * CLI arguments mapped in `REQ-003`.
* **Outputs:**
    * A resolved, unified internal configuration record (e.g., `Global_Config` in Ada) dictating the current runtime parameters (Target File and Verbosity Level).

## 5. Acceptance Criteria (Definition of Done)
* **AC-004-001:** Setting a custom target file name in the user configuration (`~/.config/makeops/config.toml`) causes `mko` to successfully discover and execute that file in the current directory instead of `makeops.toml`.
* **AC-004-002:** Setting `verbosity = "quiet"` in the system-wide `/etc/makeops/config.toml` suppresses standard MakeOps output across all runs unless explicitly overridden.
* **AC-004-003:** Passing a CLI flag (e.g., `--verbose`) successfully overrides the `quiet` verbosity level defined in the user or system configuration file, proving the cascade hierarchy.
* **AC-004-004:** Setting an environment variable (e.g., `MKO_VERBOSITY=normal`) successfully overrides the value specified in both the system and user configuration files.
* **AC-004-005:** Running the `mko` command on a fresh system without any `/etc/` or `~/.config/` MakeOps directories executes successfully using the hardcoded application defaults (`makeops.toml` and `normal` verbosity).