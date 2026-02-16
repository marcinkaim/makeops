#!/bin/bash

################################################################################
#  MakeOps
#  Copyright (C) 2026 Marcin Kaim
#  SPDX-License-Identifier: GPL-3.0-or-later
################################################################################

set -euo pipefail

# --- Configuration ---
SECRETS_FILE=".secrets"
REMOTE_NAME="origin"

# --- Colors ---
GREEN="\033[0;32m"
BLUE="\033[0;34m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
NC="\033[0m" # No Color

echo -e "${BLUE}--- Git Sync Process (GitHub) ---${NC}"

# 1. Load Secrets
if [ -f "$SECRETS_FILE" ]; then
    # shellcheck source=/dev/null
    source "$SECRETS_FILE"
else
    echo -e "${RED}[ERROR] File $SECRETS_FILE not found!${NC}"
    echo "Please create it with: GITHUB_USER, GITHUB_REPO, GITHUB_TOKEN."
    exit 1
fi

# Verify required variables
if [ -z "${GITHUB_USER:-}" ] || [ -z "${GITHUB_REPO:-}" ] || [ -z "${GITHUB_TOKEN:-}" ]; then
    echo -e "${RED}[ERROR] Missing variables in $SECRETS_FILE.${NC}"
    exit 1
fi

# 2. Pre-flight Check: Integrity Verification
# We must ensure we are not pushing a state that differs from what is on disk.
# 'git status --porcelain' outputs nothing if the directory is clean.

if [ -n "$(git status --porcelain)" ]; then
    echo -e "${RED}[ERROR] Dirty working directory detected!${NC}"
    echo -e "You have uncommitted changes. Git only pushes committed code."
    echo -e "${YELLOW}--- Modified/Untracked Files ---${NC}"
    git status --short
    echo -e "${YELLOW}--------------------------------${NC}"
    echo -e "Action required: Review changes (e.g., license headers), commit them, and try again."
    exit 1
fi

# 3. Define URLs
# Standard URL for fetch/public access (safe to store in .git/config)
REMOTE_URL="https://github.com/${GITHUB_USER}/${GITHUB_REPO}.git"
# Auth URL for push actions (contains token, kept in memory only)
AUTH_REMOTE_URL="https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${GITHUB_REPO}.git"

# 4. Configure Remote
# We ensure 'origin' points to the repo, but we don't save the token there.

if ! git remote | grep -q "^${REMOTE_NAME}$"; then
    echo "[INFO] Remote '${REMOTE_NAME}' not found. Adding..."
    git remote add "${REMOTE_NAME}" "${REMOTE_URL}"
else
    echo "[INFO] Remote '${REMOTE_NAME}' exists. Ensuring URL matches config..."
    git remote set-url "${REMOTE_NAME}" "${REMOTE_URL}"
fi

# 5. Push Code
# Verify we are on a branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "[INFO] Pushing branch: ${CURRENT_BRANCH}..."

# We push to the AUTH_REMOTE_URL explicitly
if git push "${AUTH_REMOTE_URL}" "${CURRENT_BRANCH}"; then
    echo -e "${GREEN}[SUCCESS] Code pushed successfully.${NC}"
else
    echo -e "${RED}[ERROR] Failed to push code.${NC}"
    exit 1
fi

# 6. Push Tags (if any)
echo "[INFO] Pushing tags..."
if git push "${AUTH_REMOTE_URL}" --tags; then
    echo -e "${GREEN}[SUCCESS] Tags pushed successfully.${NC}"
else
    echo -e "${RED}[WARN] Failed to push tags (or no tags to push).${NC}"
fi

echo -e "${GREEN}✅ Repository synced with GitHub.${NC}"