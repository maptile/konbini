#!/usr/bin/env bash
# DESCRIPTION: save key to keychain: <service> <user>, password will be prompted

import common

service="$1"
user="$2"
if [ -z "$service" ] || [ -z "$user" ]; then
    echo "Usage: $0 savekey <service> <user>" >&2
    exit 2
fi
if writeApiKey "$service" "$user"; then
    if readApiKey "$service" "$user" >/dev/null; then
        echo "Saved API key for service='$service' user='$user'."
        exit 0
    else
        echo "Failed to verify saved key for service='$service' user='$user'." >&2
        exit 1
    fi
else
    echo "Failed to save key for service='$service' user='$user'." >&2
    exit 1
fi
