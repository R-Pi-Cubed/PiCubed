#!/bin/bash
# This script is a combination of several sources and are credited here in no order of priority.
# GitHub Repository: https://gist.github.com/Prof-Bloodstone/6367eb4016eaf9d1646a88772cdbbac5
# GitHub Repository: https://github.com/TheRemote/RaspberryPiMinecraft
# GitHub Repository: https://github.com/Cat5TV/pinecraft

# Takes ownership of server files to fix common permission errors such as access denied
# This is very common when restoring backups, moving and editing files, etc.
# If you are using the systemd service (sudo systemctl start minecraft) it performs this automatically for you each startup

# Set path variable
#USERPATH="pathvariable"
#PathLength=${#USERPATH}
#if [[ "$PathLength" -gt 12 ]]; then
#    PATH="$USERPATH"
#else
#    echo "Unable to set path variable.  You likely need to download an updated version of SetupMinecraft.sh from GitHub!"
#fi

# Get an optional custom countdown time (in minutes)
#Automated=0
#while getopts ":a:" opt; do
#  case $opt in
#    t)
#      case $OPTARG in
#        ''|*[!0-9]*)
#          Automated=1
#          ;;
#        *)
#          Automated=1
#          ;;
#      esac
#      ;;
#    \?)
#      echo "Invalid option: -$OPTARG; countdown time must be a whole number in minutes." >&2
#      ;;
#  esac
#done

echo "Now taking ownership of all server files/folders in dirname/minecraft..."
#if [[ $Automated == 1 ]]; then
#    sudo -n chown -R userxname dirname/minecraft
#    sudo -n chmod -R 755 dirname/minecraft/*.sh
#else
sudo chown -Rv userxname dirname/minecraft
sudo chmod -Rv 755 dirname/minecraft/*.sh

#fi

sleep 1s

echo "Complete"