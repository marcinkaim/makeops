################################################################################
#  MakeOps
#  Copyright (C) 2026 Marcin Kaim
#  SPDX-License-Identifier: GPL-3.0-or-later
################################################################################

# MakeOps Project Makefile
# Philosophy: First Principles & Deep Tech

# Configuration
PROJECT_FILE = makeops.gpr
BUILD_DIR = build
SCRIPTS_DIR = devops/scripts

GPR_FLAGS = -j0 -p

.PHONY: all build release test clean diff commit commit-interactive help license-check check-docs push

# Default target
all: build

# ------------------------------------------------------------------------------
# Build Targets
# ------------------------------------------------------------------------------

# Development Build (Default) - Includes debug symbols and assertions
build:
	@echo ">> Building MakeOps (Development Mode)..."
	gprbuild $(GPR_FLAGS) -P $(PROJECT_FILE) -XBUILD_MODE=dev

# Production Build - Optimized for generic deployment or specific hardware
release:
	@echo ">> Building MakeOps (Production Mode - Optimized)..."
	gprbuild $(GPR_FLAGS) -P $(PROJECT_FILE) -XBUILD_MODE=prod

# ------------------------------------------------------------------------------
# Testing
# ------------------------------------------------------------------------------

# Builds and runs the test suite
test: build
	./build/bin/test_runner

# ------------------------------------------------------------------------------
# Maintenance
# ------------------------------------------------------------------------------

# Clean build artifacts
clean:
	@echo ">> Cleaning up..."
	gprclean -P $(PROJECT_FILE)
	rm -rf $(BUILD_DIR)/*

diff:
	@$(SCRIPTS_DIR)/generate_staged_diff.sh

commit:
	@if [ "$(FILE)" != "" ]; then \
		$(SCRIPTS_DIR)/commit_ai.sh --input-file "$(FILE)"; \
	else \
		$(SCRIPTS_DIR)/commit_ai.sh; \
	fi

commit-interactive:
	@$(SCRIPTS_DIR)/commit_interactive.sh

# Help command
help:
	@echo "MakeOps Makefile"
	@echo "----------------"
	@echo "make                     - Build development version (mko)"
	@echo "make release             - Build production version (optimized mko)"
	@echo "make test                - Build and run unit tests (AUnit)"
	@echo "make clean               - Remove all build artifacts"
	@echo "make diff                - Generate changes.diff from staged files"
	@echo "make commit              - Commit staged changes (reads from stdin)"
	@echo "make commit FILE=...     - Commit staged changes using a message from a file"
	@echo "make commit-interactive  - Open CLI wizard to construct a commit message"
	@echo "make license-check       - Check license compliance"
	@echo "make check-docs          - Verify specification docs are APPROVED"
	@echo "make push                - Push changes to GitHub"

license-check:
	@echo "--- [LICENSE] Ensuring GPLv3 headers compliance ---"
	@$(SCRIPTS_DIR)/ensure_license_headers.sh

check-docs:
	@echo "--- [DOCS] Ensuring specification documents are APPROVED ---"
	@$(SCRIPTS_DIR)/check_docs_status.sh

push: check-docs license-check
	@$(SCRIPTS_DIR)/push_repo.sh
