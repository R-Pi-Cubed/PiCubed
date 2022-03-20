#!/bin/bash

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

echo "Now taking ownership of all server files/folders in dirname/minecraft..."

sudo chown -Rv userxname dirname/minecraft
sudo chmod -Rv 755 dirname/minecraft/*.sh

#fi

sleep 1s

echo "Complete"