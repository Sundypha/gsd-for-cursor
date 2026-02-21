#!/bin/bash

# =============================================================================
# GSD Installer for Cursor IDE
# =============================================================================
#
# This script installs the GSD (Get Shit Done) system for Cursor IDE by
# copying all necessary files to the ~/.cursor/ directory.
#
# Usage:
#   ./install.sh [--source <path>] [--force]
#
# =============================================================================

set -e

# Default values
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_PATH="$SCRIPT_DIR/../src"
CURSOR_DIR="$HOME/.cursor"
FORCE=false

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --source|-s)
            SOURCE_PATH="$2"
            shift 2
            ;;
        --force|-f)
            FORCE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--source <path>] [--force]"
            echo ""
            echo "Options:"
            echo "  --source, -s    Path to cursor-gsd/src directory"
            echo "  --force, -f     Overwrite existing installation"
            echo "  --help, -h      Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Resolve source path to absolute
if [[ -d "$SOURCE_PATH" ]]; then
    SOURCE_PATH="$(cd "$SOURCE_PATH" && pwd)"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  GSD Installer for Cursor IDE${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

echo -e "${CYAN}Paths:${NC}"
echo -e "  ${GRAY}Source:      $SOURCE_PATH${NC}"
echo -e "  ${GRAY}Target:      $CURSOR_DIR${NC}"
echo ""

# Check source exists
if [ ! -d "$SOURCE_PATH" ]; then
    echo -e "${RED}ERROR: Source path not found: $SOURCE_PATH${NC}"
    echo -e "${YELLOW}Run the migration script first to generate the src directory.${NC}"
    exit 1
fi

# Check for existing installation
if [ -d "$CURSOR_DIR/get-shit-done" ] && [ "$FORCE" = false ]; then
    echo -e "${YELLOW}Existing GSD installation found at: $CURSOR_DIR/get-shit-done${NC}"
    read -p "Overwrite? (y/N) " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}Installation cancelled.${NC}"
        exit 0
    fi
fi

# Create directory structure
echo -e "${CYAN}Creating directory structure...${NC}"

directories=(
    "commands"
    "agents"
    "get-shit-done/bin/lib"
    "get-shit-done/workflows"
    "get-shit-done/templates"
    "get-shit-done/templates/codebase"
    "get-shit-done/templates/research-project"
    "get-shit-done/references"
    "hooks"
    "cache"
)

for dir in "${directories[@]}"; do
    full_path="$CURSOR_DIR/$dir"
    if [ ! -d "$full_path" ]; then
        mkdir -p "$full_path"
        echo -e "  ${GRAY}Created: $dir${NC}"
    fi
done

# Copy files with proper path handling
echo ""
echo -e "${CYAN}Copying files...${NC}"

file_count=0

# Function to copy directory contents
copy_dir() {
    local src_dir="$1"
    local dest_dir="$2"
    local label="$3"
    
    echo -e "  ${GRAY}Processing: $label${NC}"
    
    if [ -d "$src_dir" ]; then
        # Get absolute path for proper relative path calculation
        local abs_src_dir="$(cd "$src_dir" && pwd)"
        
        find "$abs_src_dir" -type f | while read -r file; do
            local relative_path="${file#$abs_src_dir/}"
            local dest_path="$dest_dir/$relative_path"
            local dest_folder="$(dirname "$dest_path")"
            
            if [ ! -d "$dest_folder" ]; then
                mkdir -p "$dest_folder"
            fi
            
            cp "$file" "$dest_path"
            ((file_count++)) 2>/dev/null || file_count=$((file_count + 1))
        done
        echo -e "    ${GRAY}Copied: $label${NC}"
    else
        echo -e "    ${YELLOW}SKIPPED: Source not found${NC}"
    fi
}

# Copy each directory
if [ -d "$SOURCE_PATH/commands" ]; then
    copy_dir "$SOURCE_PATH/commands" "$CURSOR_DIR/commands" "commands"
    file_count=$((file_count + $(find "$SOURCE_PATH/commands" -type f 2>/dev/null | wc -l)))
fi

if [ -d "$SOURCE_PATH/agents" ]; then
    copy_dir "$SOURCE_PATH/agents" "$CURSOR_DIR/agents" "agents"
    file_count=$((file_count + $(find "$SOURCE_PATH/agents" -type f 2>/dev/null | wc -l)))
fi

if [ -d "$SOURCE_PATH/bin" ]; then
    copy_dir "$SOURCE_PATH/bin" "$CURSOR_DIR/get-shit-done/bin" "bin (gsd-tools)"
    file_count=$((file_count + $(find "$SOURCE_PATH/bin" -type f 2>/dev/null | wc -l)))
fi

if [ -d "$SOURCE_PATH/workflows" ]; then
    copy_dir "$SOURCE_PATH/workflows" "$CURSOR_DIR/get-shit-done/workflows" "workflows"
    file_count=$((file_count + $(find "$SOURCE_PATH/workflows" -type f 2>/dev/null | wc -l)))
fi

if [ -d "$SOURCE_PATH/templates" ]; then
    copy_dir "$SOURCE_PATH/templates" "$CURSOR_DIR/get-shit-done/templates" "templates"
    file_count=$((file_count + $(find "$SOURCE_PATH/templates" -type f 2>/dev/null | wc -l)))
fi

if [ -d "$SOURCE_PATH/references" ]; then
    copy_dir "$SOURCE_PATH/references" "$CURSOR_DIR/get-shit-done/references" "references"
    file_count=$((file_count + $(find "$SOURCE_PATH/references" -type f 2>/dev/null | wc -l)))
fi

if [ -d "$SOURCE_PATH/hooks" ]; then
    copy_dir "$SOURCE_PATH/hooks" "$CURSOR_DIR/hooks" "hooks"
    file_count=$((file_count + $(find "$SOURCE_PATH/hooks" -type f 2>/dev/null | wc -l)))
fi

# Configure settings.json
echo ""
echo -e "${CYAN}Configuring settings...${NC}"

settings_path="$CURSOR_DIR/settings.json"

# Create or update settings.json
if command -v jq &> /dev/null; then
    # Use jq if available
    if [ -f "$settings_path" ]; then
        # Merge with existing settings
        jq '. + {
            "hooks": {
                "SessionStart": [
                    {
                        "hooks": [
                            {
                                "type": "command",
                                "command": "node ~/.cursor/hooks/gsd-check-update.js"
                            }
                        ]
                    }
                ]
            },
            "statusLine": {
                "type": "command",
                "command": "node ~/.cursor/hooks/gsd-statusline.js"
            }
        }' "$settings_path" > "$settings_path.tmp" && mv "$settings_path.tmp" "$settings_path"
    else
        # Create new settings
        cat > "$settings_path" << 'EOF'
{
    "hooks": {
        "SessionStart": [
            {
                "hooks": [
                    {
                        "type": "command",
                        "command": "node ~/.cursor/hooks/gsd-check-update.js"
                    }
                ]
            }
        ]
    },
    "statusLine": {
        "type": "command",
        "command": "node ~/.cursor/hooks/gsd-statusline.js"
    }
}
EOF
    fi
else
    # Create basic settings without jq
    cat > "$settings_path" << 'EOF'
{
    "hooks": {
        "SessionStart": [
            {
                "hooks": [
                    {
                        "type": "command",
                        "command": "node ~/.cursor/hooks/gsd-check-update.js"
                    }
                ]
            }
        ]
    },
    "statusLine": {
        "type": "command",
        "command": "node ~/.cursor/hooks/gsd-statusline.js"
    }
}
EOF
fi

echo -e "  ${GRAY}Updated: settings.json${NC}"

# Create VERSION file
echo "1.0.0" > "$CURSOR_DIR/get-shit-done/VERSION"
echo -e "  ${GRAY}Created: VERSION${NC}"

# Summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Installation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "  Files installed: ${CYAN}$file_count${NC}"
echo -e "  Location: ${CYAN}$CURSOR_DIR${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

echo -e "${YELLOW}Quick start:${NC}"
echo "  1. Open Cursor IDE"
echo "  2. Type /gsd-help to see all commands"
echo "  3. Type /gsd-new-project to start a new project"
echo ""
