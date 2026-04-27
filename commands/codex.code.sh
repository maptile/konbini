#!/usr/bin/env bash
# DESCRIPTION: run codex

import common

workdir=$(pwd)
echoLargeText "Codex" magenta

set_tab_title "Codex"

docker run \
       -v "$HOME/.codex":/home/node/.codex \
       -v "$workdir":/workspace \
       -p 3000 \
       -p 3001 \
       -p 8080 \
       -p 8081 \
       -it --rm -u 1000 codex "$@"
