#!/usr/bin/env bash
# DESCRIPTION: run nodejs docker

import common

workdir=$(pwd)
echoLargeText node green

if userConfirmDir "$workdir"; then
    docker run \
           -v "$workdir":/workspace \
           -p 3000 \
           -p 3001 \
           -p 8080 \
           -p 8081 \
           -it --rm -u 1000 \
           node:24 bash "$@"
else
    echo "User cancelled"
fi
