#!/usr/bin/env bash
# DESCRIPTION: install calibre digital book manager

sudo mkdir -p /opt/calibre && sudo rm -rf /opt/calibre/* && sudo tar xvf $1 -C /opt/calibre && sudo /opt/calibre/calibre_postinstall
