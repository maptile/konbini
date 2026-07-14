#!/usr/bin/env bash
# DESCRIPTION: Do a full system upgrade

import common

echo 'Will do a full system upgrade, please type sudo password'
sudo uname -a > /dev/null

printCountDown 'Do after' 5

echoText 'Update list of available packages'
sudo apt update

echoText 'Installing all upgradable packages'
sudo apt upgrade -y

echoText 'Remove automatically all unused packages'
sudo apt autoremove -y

echoText 'Refreshing snaps'
sudo snap refresh
