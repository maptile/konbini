#!/usr/bin/env bash
# DESCRIPTION: docker compose exec <name> (bash or sh)

if [[ -z "$1" ]]; then
    echo "Usage: dce <service>"
    exit 1
fi

service="$1"

if docker compose exec "$service" which bash >/dev/null 2>&1; then
    exec docker compose exec "$service" bash
elif docker compose exec "$service" which sh >/dev/null 2>&1; then
    exec docker compose exec "$service" sh
else
    echo "Error: neither bash nor sh found in container '$service'" >&2
    exit 1
fi
