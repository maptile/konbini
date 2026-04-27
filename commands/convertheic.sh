#!/usr/bin/env bash
# DESCRIPTION: Convert HEIC to JPG

set -euo pipefail

# Default quality
QUALITY=95
RM_MODE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --rm)
            RM_MODE=true
            shift
            ;;
        -q)
            if [[ -n "${2:-}" ]]; then
                QUALITY="$2"
                shift 2
            else
                echo "Error: -q requires a quality value"
                exit 1
            fi
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--rm] [-q quality]"
            exit 1
            ;;
    esac
done

# Check if heif-convert exists
if ! command -v heif-convert &>/dev/null; then
    echo "Error: heif-convert not found"
    echo "Please install libheif-examples:"
    echo "  sudo apt install libheif-examples"
    exit 1
fi

# Enable case-insensitive matching
shopt -s nocaseglob nullglob

# Get all heic files (case-insensitive)
heic_files=(*.heic)

if [[ ${#heic_files[@]} -eq 0 ]]; then
    echo "No HEIC files found in current directory"
    exit 0
fi

if [[ "$RM_MODE" == true ]]; then
    # Remove mode: delete heic files that have corresponding jpg
    to_delete=()
    no_jpg=()

    for f in "${heic_files[@]}"; do
        base="${f%.*}"
        # Check if corresponding jpg exists (case-insensitive check)
        if compgen -G "${base}".[jJ][pP][gG] >/dev/null; then
            to_delete+=("$f")
        else
            no_jpg+=("$f")
        fi
    done

    # Warn about heic files without corresponding jpg
    if [[ ${#no_jpg[@]} -gt 0 ]]; then
        echo "Warning: The following ${#no_jpg[@]} HEIC file(s) have NO corresponding JPG:"
        echo "----------------------------------------"
        for f in "${no_jpg[@]}"; do
            echo "  $f"
        done
        echo "----------------------------------------"
        echo ""
    fi

    if [[ ${#to_delete[@]} -eq 0 ]]; then
        echo "No HEIC files with corresponding JPG found, nothing to delete"
        exit 0
    fi

    echo "The following ${#to_delete[@]} HEIC file(s) will be deleted:"
    echo "----------------------------------------"
    for f in "${to_delete[@]}"; do
        echo "  $f"
    done
    echo "----------------------------------------"

    read -rp "Delete these files? [y/N]: " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        for f in "${to_delete[@]}"; do
            rm -v "$f"
        done
        echo "Deleted ${#to_delete[@]} file(s)"
    else
        echo "Aborted"
    fi
else
    # Convert mode
    echo "Converting ${#heic_files[@]} HEIC file(s) with quality $QUALITY..."
    for f in "${heic_files[@]}"; do
        base="${f%.*}"
        echo "Converting: $f -> ${base}.jpg"
        heif-convert -q "$QUALITY" "$f" "${base}.jpg"
    done
    echo "Done"
fi
