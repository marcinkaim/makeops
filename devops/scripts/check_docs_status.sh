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

echo -e "${BLUE}[INFO] Starting Specification Documents Status Check...${NC}"

# Target directory containing the Knowledge Base and Specifications
TARGET_DIR="docs/specification"

# Pre-flight check: ensure the directory exists before scanning
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${YELLOW}[WARN] Directory $TARGET_DIR does not exist. Skipping check.${NC}"
    exit 0
fi

FAILED_COUNT=0
CHECKED_COUNT=0

# Read all markdown files recursively in the target directory.
# We use process substitution '< <(...)' to run the while loop in the current
# shell context. This ensures that the counter variables update correctly.
while IFS= read -r -d '' file; do
    CHECKED_COUNT=$((CHECKED_COUNT + 1))
    
    # Extract the line containing the Status attribute from the markdown table.
    # Expected format: | **Status** | `APPROVED` |
    # We append '|| true' to prevent 'set -e' from halting the script if grep finds nothing.
    STATUS_LINE=$(grep -E '^\|\s*\*\*Status\*\*\s*\|' "$file" || true)
    
    if [[ -z "$STATUS_LINE" ]]; then
        echo -e "${RED}[ERROR]${NC} $file: Missing '**Status**' attribute in the document metadata."
        FAILED_COUNT=$((FAILED_COUNT + 1))
        continue
    fi

    # Evaluate the status value. We explicitly look for the `APPROVED` literal.
    if [[ ! "$STATUS_LINE" =~ \`APPROVED\` ]]; then
        echo -e "${RED}[ERROR]${NC} $file: Document is not APPROVED."
        echo -e "       Found status line: $STATUS_LINE"
        FAILED_COUNT=$((FAILED_COUNT + 1))
    fi

done < <(find "$TARGET_DIR" -type f -name "*.md" -print0)

echo -e "${BLUE}[INFO] Scan complete. Checked $CHECKED_COUNT files.${NC}"

# Final evaluation and exit code routing
if [ "$FAILED_COUNT" -gt 0 ]; then
    echo -e "${RED}[ERROR] $FAILED_COUNT document(s) failed the status check.${NC}"
    echo -e "Only APPROVED documents are allowed to be tracked in the repository."
    echo -e "Please finalize DRAFTs, remove DEPRECATED files, or stash your changes."
    exit 1
else
    echo -e "${GREEN}[SUCCESS] All specification documents are strictly APPROVED.${NC}"
    exit 0
fi