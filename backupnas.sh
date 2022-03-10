#!/bin/bash
# This script is a combination of several sources and are credited here in no order of priority.
# GitHub Repository: https://gist.github.com/Prof-Bloodstone/6367eb4016eaf9d1646a88772cdbbac5
# GitHub Repository: https://github.com/TheRemote/RaspberryPiMinecraft
# GitHub Repository: https://github.com/Cat5TV/pinecraft

# Set path variable
#USERPATH="pathvariable"
#PathLength=${#USERPATH}
#if [[ "$PathLength" -gt 12 ]]; then
#    PATH="$USERPATH"
#else
#    echo "Unable to set path variable.  You likely need to download an updated version of SetupMinecraft.sh from GitHub!"
#fi

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
sleep 1
Rotate=$(pushd dirname/minecraft/backups; ls -1tr | head -n -10 | xargs -d '\n' rm -f --; popd)
echo "Complete"
sleep 1