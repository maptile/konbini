#!/usr/bin/env bash
# DESCRIPTION: docker compose restart <name>

if [[ -z "$1" ]]; then
    echo "Usage: dcr <service>"
    exit 1
fi

docker compose restart "$1"
