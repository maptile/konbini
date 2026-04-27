#!/usr/bin/env bash
# DESCRIPTION: display verse of the day from BibleGateway

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Execute _verse.js via an absolute path and pass through arguments and stdio
exec node "$SCRIPT_DIR/_verse.js" "$@"
