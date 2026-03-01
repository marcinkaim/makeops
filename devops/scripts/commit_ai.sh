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

echo -e "${BLUE}[INFO] AI-Assisted Commit Process${NC}"

# 1. Pre-flight check: Git Status
STAGED_COUNT=$(( $(git diff --staged --name-only | wc -l) ))
UNSTAGED_COUNT=$(( $(git diff --name-only | wc -l) ))
UNTRACKED_COUNT=$(( $(git ls-files --others --exclude-standard | wc -l) ))

if [ "$STAGED_COUNT" -eq 0 ]; then
    echo -e "${RED}[ERROR] No staged files found!${NC}"
    echo -e "       There is nothing to commit. Use 'git add <file>' first."
    exit 1
fi

if [ "$UNSTAGED_COUNT" -gt 0 ] || [ "$UNTRACKED_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}[WARN] You are making a partial commit.${NC}"
    echo -e "       Staged: ${STAGED_COUNT} | Unstaged: ${UNSTAGED_COUNT} | Untracked: ${UNTRACKED_COUNT}"
fi

# 2. Argument Parsing
INPUT_FILE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --input-file|-f)
      INPUT_FILE="$2"
      shift 2
      ;;
    *)
      echo -e "${RED}[ERROR] Unknown argument: $1${NC}"
      exit 1
      ;;
  esac
done

# 3. Commit Execution
if [ -n "$INPUT_FILE" ]; then
    # Mode A: Read from file
    if [ ! -f "$INPUT_FILE" ]; then
        echo -e "${RED}[ERROR] Input file '$INPUT_FILE' not found!${NC}"
        exit 1
    fi
    echo -e "${BLUE}[INFO] Reading commit message from '$INPUT_FILE'...${NC}"
    
    # 'git commit -F <file>' reads the commit message directly from the specified file
    git commit -F "$INPUT_FILE"
else
    # Mode B: Read from Standard Input (stdin)
    echo -e "${YELLOW}👉 Paste your AI-generated commit message below.${NC}"
    echo -e "${YELLOW}👉 When finished, press [ENTER] and then [CTRL+D] to commit.${NC}"
    echo -e "----------------------------------------------------------------------"
    
    # 'git commit -F -' tells Git to read the commit message from stdin
    if git commit -F - ; then
        echo -e "----------------------------------------------------------------------"
    else
        echo -e "\n${RED}[ERROR] Commit aborted or failed.${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}[SUCCESS] Changes committed successfully!${NC}"