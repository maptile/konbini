#!/usr/bin/env bash
# DESCRIPTION: run codex

echo "downloading $1"

if [[ -n "$2" ]]; then
  aria2c -c -x 16 -s 16 -o "$2" "$1"
else
  aria2c -c -x 16 -s 16 "$1"
fi
