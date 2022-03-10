#!/bin/sh
# We need to use sh, since it's hardcoded in spigot
# Minecraft server shutdown and Pi reboot.

# This script is a combination of several sources and are credited here in no order of priority.
# GitHub Repository: https://gist.github.com/Prof-Bloodstone/6367eb4016eaf9d1646a88772cdbbac5
# GitHub Repository: https://github.com/TheRemote/RaspberryPiMinecraft
# GitHub Repository: https://github.com/Cat5TV/pinecraft

# Minecraft Server restart script - Primarily called by the daily CRON job, Minecraft service or the server if designated in spigot.yml
# Can also be ran manually with ./restart.sh

# Set path variable
#USERPATH="pathvariable"
#PathLength=${#USERPATH}
#if [[ "$PathLength" -gt 12 ]]; then
#  PATH="$USERPATH"
#else
#  echo "Unable to set path variable."
#fi

# Check to make sure we aren't running as root
if [[ $(id -u) = 0 ]]; then
  echo "This script is not meant to run as root or sudo.  Please run as a normal user with ./restart.sh.  Exiting..."
  exit 1
fi

# Check if server is running
if ! screen -list | grep -q "\.minecraft"; then
  echo "Server is not currently running!"
  exit 1
fi

echo "Now sending restart notifications to server..."
sleep 1
# Sending warning messages to the console.
screen -Rd minecraft -X stuff "say !!!ATTENTION!!! The server is restarting in 30 seconds! $(printf '\r')"
echo "The server is restarting in 30 seconds!"
sleep 23s
screen -Rd minecraft -X stuff "say !!!ATTENTION!!! The server is restarting in 7 seconds! $(printf '\r')"
echo "The server is restarting in 7 seconds!"
sleep 1s
screen -Rd minecraft -X stuff "say The server is restarting in 6 seconds! $(printf '\r')"
echo "The server is restarting in 6 seconds!"
sleep 1s
screen -Rd minecraft -X stuff "say The server is restarting in 5 seconds! $(printf '\r')"
echo "The server is restarting in 5 seconds!"
sleep 1s
screen -Rd minecraft -X stuff "say The server is restarting in 4 seconds! $(printf '\r')"
echo "The server is restarting in 4 seconds!"
sleep 1s
screen -Rd minecraft -X stuff "say The server is restarting in 3 seconds! $(printf '\r')"
echo "The server is restarting in 3 seconds!"
sleep 1s
screen -Rd minecraft -X stuff "say The server is restarting in 2 seconds! $(printf '\r')"
echo "The server is restarting in 2 seconds!"
sleep 1s
screen -Rd minecraft -X stuff "say The server is restarting in 1 second! $(printf '\r')"
echo "The server is restarting in 1 second!"
sleep 1s
screen -Rd minecraft -X stuff "say Closing the server...$(printf '\r')"
screen -Rd minecraft -X stuff "stop $(printf '\r')"

# Wait up to 60 seconds for server to close
echo "Closing the server..."
echo "This could take up to 60 seconds."
StopChecks=0
while [ $StopChecks -lt 60 ]; do
  if ! screen -list | grep -q "\.minecraft"; then
    break
  fi
  sleep 1;
  StopChecks=$((StopChecks+1))
done

# Force quit if server is still open
if screen -list | grep -q "\.minecraft"; then
  echo "Minecraft server still hasn't closed after 60 seconds, closing screen manually"
  screen -S minecraft -X quit
fi

echo "Restarting now."
sleep 1
sudo -n reboot
