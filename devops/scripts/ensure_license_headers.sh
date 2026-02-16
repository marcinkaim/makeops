#!/bin/bash

################################################################################
#  MakeOps
#  Copyright (C) 2026 Marcin Kaim
#  SPDX-License-Identifier: GPL-3.0-or-later
################################################################################

# ------------------------------------------------------------------------------
# Automates the injection of GPLv3 license headers into source files.
#
# CONFIGURATION SOURCE (Priority Order):
# 1. 'alire.toml' Magic Comment:   # Title: My Custom Name
# 2. 'alire.toml' field:           description = "..." (Optional switch)
# 3. 'alire.toml' field:           name = "..." (Auto-formatted to Title Case)
#
# BEHAVIOR:
# - Idempotent: Checks if the header exists before adding it.
# - Safe: Preserves Shebangs (#!/bin/bash) in scripts.
# - Self-Preservation: Excludes itself from modification to avoid runtime errors.
# - Verbose: Reports actions to stdout for audit trails.
# - Smart Parsing: Reads metadata safely from TOML without external deps.
# - Dynamic Year: Uses $(date +%Y) for NEW headers only.
# - Loose Check: Ignores year when checking if header exists.
# ------------------------------------------------------------------------------

set -e  # Exit immediately if a command exits with a non-zero status.

# --- CONFIGURATION & SSOT ---

# Default values (Fallback)
YEAR=$(date +%Y) # Dynamic current year for NEW headers

# ANSI Colors for verbose output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}[INFO] Starting GPLv3 License Header Compliance Scan...${NC}"

# --- INTELLIGENT CONFIG LOAD ---

# Strategy 1: README.md Title (The "Display" Name)
# Why: The README H1 header is the definitive source for how the project name should be written.
if [ -f "README.md" ]; then
    # Finds the first line starting with "# " (Markdown H1)
    # grep -m 1: Stop after first match
    # sed: Remove leading '# ' and any trailing whitespace
    README_TITLE=$(grep -m 1 "^#[[:space:]]" "README.md" | sed -E 's/^#[[:space:]]+//; s/[[:space:]]*$//')
    
    if [ -n "$README_TITLE" ]; then
        PROJECT_NAME_DISPLAY="$README_TITLE"
        echo -e "       -> Mode: README.md Title ('$PROJECT_NAME_DISPLAY')"
    fi
fi

# Strategy 2: GPR Project Definition (The "Technical" Name)
# Why: If README is missing, the GPR file defines the project identity in Ada.
# Looks for: "project MakeOps is" or "aggregate project MakeOps is"
if [ -z "$PROJECT_NAME_DISPLAY" ]; then
    # Find the main .gpr file (prefer root dir)
    GPR_FILE=$(find . -maxdepth 1 -name "*.gpr" -print -quit)
    
    if [ -f "$GPR_FILE" ]; then
        # Regex explanation:
        # ^(aggregate )?project   -> Matches 'project' or 'aggregate project' at start of line
        # [[:space:]]+            -> Whitespace
        # ([^[:space:]]+)         -> Capture the Project Name (Group 1)
        # [[:space:]]+is          -> Followed by ' is'
        GPR_NAME=$(grep -i -E "^(aggregate )?project " "$GPR_FILE" | head -n 1 | sed -E 's/.*project[[:space:]]+([^[:space:]]+)[[:space:]]+is.*/\1/')
        
        if [ -n "$GPR_NAME" ]; then
            PROJECT_NAME_DISPLAY="$GPR_NAME"
            echo -e "       -> Mode: GPR Project Definition ('$GPR_NAME' from $GPR_FILE)"
        fi
    fi
fi

# Strategy 3: Final Fallback to Directory Name
if [ -z "$PROJECT_NAME_DISPLAY" ]; then
    PROJECT_NAME_DISPLAY=$(basename "$PWD" | sed -E 's/[-_]/ /g; s/\b\w/\U&/g')
    echo -e "${YELLOW}[WARN] Could not detect project name. Using directory name.${NC}"
fi

# Auto-detect Author from Git Config if not set manually
if [ -z "$OWNER" ]; then
    GIT_USER=$(git config user.name)
    if [ -n "$GIT_USER" ]; then
        OWNER="$GIT_USER"
        echo -e "       -> Author: Git Config ('$OWNER')"
    else
        OWNER="Maintainer"
        echo -e "${YELLOW}[WARN] Could not detect author. Using default 'Maintainer'.${NC}"
    fi
fi

# Helper to get absolute path (safe for both Linux and macOS/BSD usually)
SCRIPT_PATH=$(readlink -f "$0" 2>/dev/null || realpath "$0")

# Counters
FIXED_COUNT=0
SKIPPED_COUNT=0

echo -e "       Config: Owner='${OWNER}', Year='${YEAR}', Project='${PROJECT_NAME_DISPLAY}'"

# --- HEADER DEFINITIONS ---
# NOTE: We add '|| true' after read because read -d '' returns exit code 1 
# on EOF (End Of File) if the delimiter (NULL) is not found. 
# Without '|| true', 'set -e' would kill the script here.

# 1. ADA Style (-- )
read -r -d '' HEADER_ADA << EOM || true
-------------------------------------------------------------------------------
--  $PROJECT_NAME_DISPLAY
--  Copyright (C) $YEAR $OWNER
--  SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------
EOM

# 2. C/C++/CUDA/PTX Style (// )
read -r -d '' HEADER_CPP << EOM || true
//------------------------------------------------------------------------------
//  $PROJECT_NAME_DISPLAY
//  Copyright (C) $YEAR $OWNER
//  SPDX-License-Identifier: GPL-3.0-or-later
//------------------------------------------------------------------------------
EOM

# 3. Shell/Make/Docker Style (# )
read -r -d '' HEADER_SHELL << EOM || true
################################################################################
#  $PROJECT_NAME_DISPLAY
#  Copyright (C) $YEAR $OWNER
#  SPDX-License-Identifier: GPL-3.0-or-later
################################################################################
EOM

# --- SAFE HEADER DEFINITIONS (ASCII HEX) ---
# \x3C = <
# \x21 = !
# \x2D = -
H_START=$(printf "\x3C\x21\x2D\x2D")

# \x2D = -
# \x3E = >
H_END=$(printf "\x2D\x2D\x3E")

# 4. Markdown Style (HTML Comment)
# Note: Invisible in rendered view, visible in source.
read -r -d '' HEADER_MARKDOWN << EOM || true
$H_START
  $PROJECT_NAME_DISPLAY
  Copyright (C) $YEAR $OWNER
  SPDX-License-Identifier: GPL-3.0-or-later
$H_END
EOM

# --- LOGIC ---

apply_header() {
    local file="$1"
    local style="$2"
    local header_content="$3"
    
    # SAFETY CHECK: Do not modify the running script itself
    local file_abs
    file_abs=$(readlink -f "$file" 2>/dev/null || realpath "$file")
    
    if [[ "$file_abs" == "$SCRIPT_PATH" ]]; then
        # We silently verify if self has header, if not, we warn but don't touch
        if ! grep -q "Copyright (C).*$OWNER" "$file"; then
            echo -e "${YELLOW}[WARN]${NC}   $file - Script is missing header! Please add manually."
        else
            SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
        fi
        return
    fi
    
    # Check if the file already contains the copyright notice
    if grep -q "Copyright (C).*$OWNER" "$file"; then
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
        return
    fi

    echo -e "${YELLOW}[FIXing]${NC} $file - Injecting license header..."
    
    local temp_file
    temp_file=$(mktemp)

    if [[ "$style" == "SHELL" ]]; then
        # For Shell scripts, we MUST preserve the Shebang (#!/...) on the first line
        if head -n 1 "$file" | grep -q "^#\!/"; then
            # Copy Shebang
            head -n 1 "$file" > "$temp_file"
            echo "" >> "$temp_file"
            # Inject License
            echo "$header_content" >> "$temp_file"
            echo "" >> "$temp_file"
            # Append rest of file
            tail -n +2 "$file" >> "$temp_file"
        else
            echo "$header_content" > "$temp_file"
            echo "" >> "$temp_file"
            cat "$file" >> "$temp_file"
        fi
    else
        echo "$header_content" > "$temp_file"
        echo "" >> "$temp_file"
        cat "$file" >> "$temp_file"
    fi

    mv "$temp_file" "$file"
    chmod --reference="$file" "$file" 2>/dev/null || true

    FIXED_COUNT=$((FIXED_COUNT + 1))
}

# --- EXECUTION LOOP ---

TARGET_DIRS="devops docs source"
echo -e "${BLUE}[INFO] Scanning directories: $TARGET_DIRS ${NC}"

if [ -d "source" ]; then # Simple check to avoid errors if run in wrong dir
    while read -r file; do
        filename=$(basename "$file")
        
        # EXCLUSION: Skip README.md anywhere (root or subdirs)
        if [[ "$filename" == "README.md" ]]; then
            continue
        fi

        case "$file" in
            *.ads|*.adb|*.gpr)
                apply_header "$file" "ADA" "$HEADER_ADA"
                ;;
            *.c|*.h|*.cpp|*.hpp|*.cu|*.ptx)
                apply_header "$file" "CPP" "$HEADER_CPP"
                ;;
            *.sh|*/Containerfile|*/Makefile|Makefile)
                apply_header "$file" "SHELL" "$HEADER_SHELL"
                ;;
            *.md)
                apply_header "$file" "MARKDOWN" "$HEADER_MARKDOWN"
                ;;
            *)
                ;;
        esac
    done < <(find $TARGET_DIRS -type f 2>/dev/null)
else
    echo -e "${RED}[ERROR] Directory structure not recognized. Run from project root.${NC}"
    exit 1
fi

# Check specific root files
for root_file in Makefile mandelbrot_explorer.gpr; do
    if [[ -f "$root_file" ]]; then
        if [[ "$root_file" == "Makefile" ]]; then
            apply_header "$root_file" "SHELL" "$HEADER_SHELL"
        elif [[ "$root_file" == *.gpr ]]; then
            apply_header "$root_file" "ADA" "$HEADER_ADA"
        fi
    fi
done

# --- SUMMARY ---

echo -e "${BLUE}[INFO] Scan complete.${NC}"
if [ "$FIXED_COUNT" -gt 0 ]; then
    echo -e "       Stats: ${YELLOW}Fixed: $FIXED_COUNT${NC}, ${GREEN}Compliant: $SKIPPED_COUNT${NC}"
else
    echo -e "       Stats: ${GREEN}All $SKIPPED_COUNT files compliant.${NC}"
fi

# ------------------------------------------------------------------------------
# REUSE VERIFICATION (Trust but Verify)
# ------------------------------------------------------------------------------

echo -e "${BLUE}[INFO] Verifying compliance with REUSE Tool...${NC}"

# Sprawdzamy, czy narzędzie 'reuse' jest dostępne w $PATH
if command -v reuse &> /dev/null; then
    # Uruchamiamy linter. Jeśli zwróci błąd (exit code != 0), skrypt też powinien to zgłosić.
    if reuse lint; then
         echo -e "${GREEN}[SUCCESS] REUSE Tool confirmed compliance.${NC}"
    else
         echo -e "${RED}[ERROR] REUSE Tool detected issues!${NC}"
         # Exit 1 wymusi błąd w CI/CD (np. w GitHub Actions), blokując merge'a.
         exit 1 
    fi
else
    # Graceful degradation - ostrzeżenie zamiast błędu
    echo -e "${YELLOW}[WARN] 'reuse' tool not found in PATH.${NC}"
    echo -e "       Skipping secondary verification. Install via: pip install reuse"
fi