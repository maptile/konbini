#!/usr/bin/env bash
# DESCRIPTION: copy specified file to clipboard

if [[ $# -ne 1 ]]; then
    echo "Usage: copy <name>"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
file=""
if [[ -n "$KONBINI_CUSTOM_COMMANDS_DIR" ]]; then
    custom_file="$KONBINI_CUSTOM_COMMANDS_DIR/copy/$1.txt"
    if [[ -f "$custom_file" ]]; then
        file="$custom_file"
    fi
fi
if [[ -z "$file" ]]; then
    builtin_file="$SCRIPT_DIR/copy/$1.txt"
    if [[ -f "$builtin_file" ]]; then
        file="$builtin_file"
    fi
fi
if [[ -z "$file" ]]; then
    echo "File not found: $1"
    exit 1
fi

xclip -selection clipboard -i "$file" >/dev/null 2>&1
echo "Copied file to clipboard: $file"
