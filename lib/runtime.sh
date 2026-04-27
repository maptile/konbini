#!/usr/bin/env bash

import() {
    local module="$1"
    if [ -f "$KONBINI_LIB_DIR/$module.sh" ]; then
        source "$KONBINI_LIB_DIR/$module.sh"
    fi
    if [ -n "$KONBINI_CUSTOM_LIB_DIR" ] && [ -f "$KONBINI_CUSTOM_LIB_DIR/$module.sh" ]; then
        source "$KONBINI_CUSTOM_LIB_DIR/$module.sh"
    fi
}
