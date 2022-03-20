#!/bin/bash
# Minecraft Server backup script - primarily called by start.sh
# but can be ran manually with ./backup.sh

# This script is a combination of several sources and are credited here in no order of priority.
# GitHub Repository: https://github.com/TheRemote/RaspberryPiMinecraft

# Switch to server directory
cd dirname/minecraft/

# Back up server
echo "Now backing up the server to minecraft/backups folder."
echo "The backup does not include the /cache, ,logs, or the server jar file (paper.jar)"
sleep 1
tar --exclude='./backups' --exclude='./cache' --exclude='./logs' --exclude='./paper.jar' -pzvcf backups/$(date +%Y.%m.%d.%H.%M.%S).tar.gz ./*

# Rotate backups -- keep most recent 10
echo "Cleaning up minecraft/backups folder."
echo "Only the latest 10 backups are preserved."
Rotate=$(pushd dirname/minecraft/backups; ls -1tr | head -n -10 | xargs -d '\n' rm -f --; popd)

sleep 1
echo "Complete"
sleep 1