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

.PHONY: all build release test clean help license-check push

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

# Help command
help:
	@echo "MakeOps Makefile"
	@echo "----------------"
	@echo "make                 - Build development version (mko)"
	@echo "make release         - Build production version (optimized mko)"
	@echo "make test            - Build and run unit tests (AUnit)"
	@echo "make clean           - Remove all build artifacts"
	@echo "make license-check   - Check license compliance"
	@echo "make push            - Push changes to GitHub"

license-check:
	@echo "--- [LICENSE] Ensuring GPLv3 headers compliance ---"
	@$(SCRIPTS_DIR)/ensure_license_headers.sh

push: license-check
	@$(SCRIPTS_DIR)/push_repo.sh
