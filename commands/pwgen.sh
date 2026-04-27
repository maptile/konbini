#!/usr/bin/env bash
# DESCRIPTION: password generator

pwgen -c -n -y 15 1 # complex password
pwgen -c -n 15 1 # without symbol
tr -dc '0-9' </dev/urandom | head -c 6; echo # 6 digit number
echo "$(shuf -n 1 /usr/share/dict/words)$(shuf -i 1000-9999 -n 1)" # username
