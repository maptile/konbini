#!/usr/bin/env bash
# DESCRIPTION: recursively pull

for DIR in $(ls)
do
    if [ -d "$DIR" ]; then
        echo $DIR
        cd $DIR
        pwd
        git pull
        cd ..
        echo
    fi
done
