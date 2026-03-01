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
CYAN="\033[0;36m"
NC="\033[0m" # No Color

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   MakeOps Interactive Commit Wizard${NC}"
echo -e "${BLUE}====================================================${NC}"

# 1. Pre-flight check: Git Status
STAGED_COUNT=$(( $(git diff --staged --name-only | wc -l) ))
if [ "$STAGED_COUNT" -eq 0 ]; then
    echo -e "${RED}[ERROR] No staged files found!${NC}"
    echo -e "       There is nothing to commit. Use 'git add <file>' first."
    exit 1
fi

# 2. Temporary file for the commit message
TMP_MSG=$(mktemp)
# Ensure cleanup on script exit
trap 'rm -f "$TMP_MSG"' EXIT

# --- WIZARD STEPS ---

# Step 1: Category
VALID_CATEGORIES="DOC SRC OPS TST"
CATEGORY=""
while true; do
    echo -e "\n${CYAN}1. Primary change category:${NC} [${VALID_CATEGORIES}]"
    read -r -p "Category: " input_cat
    # Convert to uppercase
    input_cat=$(echo "$input_cat" | tr '[:lower:]' '[:upper:]')
    
    if [[ " $VALID_CATEGORIES " =~ " $input_cat " ]]; then
        CATEGORY="$input_cat"
        break
    else
        echo -e "${RED}[ERROR] Invalid category. Please choose one of: $VALID_CATEGORIES${NC}"
    fi
done

# Step 2: Title
TITLE=""
MAX_TITLE_LEN=72
PREFIX_LEN=$(( ${#CATEGORY} + 2 )) # e.g., "DOC: " is 5 chars
ALLOWED_LEN=$(( MAX_TITLE_LEN - PREFIX_LEN ))

while true; do
    echo -e "\n${CYAN}2. Commit title (concise, imperative mood).${NC}"
    echo -e "Characters left: ${YELLOW}${ALLOWED_LEN}${NC}"
    read -r -p "Title: " TITLE
    
    if [ -z "$TITLE" ]; then
        echo -e "${RED}[ERROR] Title cannot be empty.${NC}"
    elif [ ${#TITLE} -gt $ALLOWED_LEN ]; then
        echo -e "${RED}[ERROR] Title is too long by $(( ${#TITLE} - ALLOWED_LEN )) characters.${NC}"
    else
        break
    fi
done

# Step 3: Description
echo -e "\n${CYAN}3. Summary description (1-3 sentences).${NC}"
read -r -p "Description: " DESCRIPTION

# Step 4: Scope of Work (Bullet points)
echo -e "\n${CYAN}4. SCOPE OF WORK (List of changes).${NC}"
echo -e "Enter sequential bullet points (e.g., ${YELLOW}[SRC] Refactor module X${NC})."
echo -e "Leave an ${YELLOW}empty line${NC} and press ENTER to finish the list."

declare -a BULLETS
while true; do
    read -r -p "* " bullet
    if [ -z "$bullet" ]; then
        if [ ${#BULLETS[@]} -eq 0 ]; then
            echo -e "${RED}[ERROR] You must provide at least one bullet point.${NC}"
            continue
        fi
        break
    fi
    BULLETS+=("$bullet")
done

# Step 5: Metadata
echo -e "\n${CYAN}5. Project metadata.${NC}"
read -r -p "Version (e.g., 0.1.0-alpha): " VERSION
read -r -p "Platform (e.g., Linux (Debian 13)): " PLATFORM

# --- ASSEMBLE MESSAGE ---

echo "${CATEGORY}: ${TITLE}" > "$TMP_MSG"
echo "" >> "$TMP_MSG"
echo "${DESCRIPTION}" >> "$TMP_MSG"
echo "" >> "$TMP_MSG"
echo "SCOPE OF WORK:" >> "$TMP_MSG"
for b in "${BULLETS[@]}"; do
    echo "* $b" >> "$TMP_MSG"
done
echo "" >> "$TMP_MSG"
echo "VERSION: ${VERSION}" >> "$TMP_MSG"
echo "PLATFORM: ${PLATFORM}" >> "$TMP_MSG"

# --- REVIEW & CONFIRM ---

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${YELLOW}COMMIT PREVIEW:${NC}"
echo -e "${BLUE}----------------------------------------------------${NC}"
cat "$TMP_MSG"
echo -e "${BLUE}====================================================${NC}"

read -r -p "Do you want to save this commit? [Y/n]: " confirm
confirm=${confirm:-Y} # Default to Y if user just presses Enter

if [[ "$confirm" =~ ^[Yy] ]]; then
    echo -e "\n${BLUE}[INFO] Executing git commit...${NC}"
    if git commit -F "$TMP_MSG"; then
        echo -e "${GREEN}[SUCCESS] Commit successfully created!${NC}"
    else
        echo -e "${RED}[ERROR] An error occurred during commit.${NC}"
        exit 1
    fi
else
    echo -e "\n${YELLOW}[WARN] Operation aborted by user. Changes remain staged.${NC}"
    exit 0
fi