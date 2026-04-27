#!/usr/bin/env bash
# DESCRIPTION: recursively status

for DIR in $(ls)
do
    if [ -d "$DIR" ]; then
        echo $DIR
        cd $DIR
        pwd
        git st -s
        cd ..
        echo
    fi
done
