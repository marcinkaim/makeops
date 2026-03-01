#!/bin/bash

################################################################################
#  MakeOps
#  Copyright (C) 2026 Marcin Kaim
#  SPDX-License-Identifier: GPL-3.0-or-later
################################################################################


set -euo pipefail

# --- Colors ---
GREEN="\033[0;32m"
BLUE="\033[0;34m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
NC="\033[0m" # No Color

echo -e "${BLUE}[INFO] Generating diff for staged changes...${NC}"

# 1. Gather repository statistics
# Using arithmetic evaluation $(( ... )) safely strips any leading/trailing whitespace from 'wc -l' output.
STAGED_COUNT=$(( $(git diff --staged --name-only | wc -l) ))
UNSTAGED_COUNT=$(( $(git diff --name-only | wc -l) ))
UNTRACKED_COUNT=$(( $(git ls-files --others --exclude-standard | wc -l) ))

# 2. Pre-flight check: Are there any staged files?
if [ "$STAGED_COUNT" -eq 0 ]; then
    echo -e "${RED}[ERROR] No staged files found!${NC}"
    echo -e "       There is nothing to commit."
    echo -e "       Use 'git add <file>' to stage your changes first."
    exit 1
fi

# 3. Generate the diff file
# The '>' operator ensures the file is overwritten if it already exists.
OUTPUT_FILE="changes.diff"
git diff --staged > "$OUTPUT_FILE"

# 4. Output Summary
echo -e "${GREEN}[SUCCESS] Diff successfully saved to '${OUTPUT_FILE}'.${NC}"
echo -e "       --- Git Status Summary ---"
echo -e "       Staged files:    ${STAGED_COUNT}"
echo -e "       Unstaged files:  ${UNSTAGED_COUNT}"
echo -e "       Untracked files: ${UNTRACKED_COUNT}"
echo -e "       --------------------------"

# 5. Warn about partial commits
if [ "$UNSTAGED_COUNT" -gt 0 ] || [ "$UNTRACKED_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}[WARN] You have unstaged or untracked files in your workspace.${NC}"
    echo -e "       Only the ${STAGED_COUNT} staged file(s) are included in '${OUTPUT_FILE}'."
    echo -e "       Ensure this partial commit is intentional before proceeding."
fi