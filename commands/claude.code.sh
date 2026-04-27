#!/usr/bin/env bash
# DESCRIPTION: run claude code

import common

# Always use the current directory and pass all remaining arguments through to the program inside the container
workdir=$(pwd)
echoLargeText "Claude Code" magenta

set_tab_title "Claude Code"

docker run \
       -v "$HOME/.claude":/home/node/.claude \
       -v "$HOME/.claude.json":/home/node/.claude.json \
       -v "$workdir":/workspace \
       -p 3000 \
       -p 3001 \
       -p 8080 \
       -p 8081 \
       -it --rm -u 1000 claudecode "$@"
