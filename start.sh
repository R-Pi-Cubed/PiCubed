#!/bin/bash
# Minecraft Server startup script using screen - primarily called by the Minecraft service
# but can be run manually with ./start.sh
# To view the console type "screen -r minecraft" without the quotation marks.

# This script is a combination of several sources and are credited here in no order of priority.
# GitHub Repository: https://gist.github.com/Prof-Bloodstone/6367eb4016eaf9d1646a88772cdbbac5
# GitHub Repository: https://github.com/TheRemote/RaspberryPiMinecraft
# GitHub Repository: https://github.com/Cat5TV/pinecraft


# Settings
# The name of your server jar
server_jar="dirname/minecraft/paper.jar"

# What will be passed to `-Xms` and `-Xmx`
heap_size="memselectM"

# JVM startup flags, one per line for better readability.
# NOTE: -Xms and -Xmx are set separately but are set to the same value.
# These are mostly "Aikar flags"
# taken from: https://mcflags.emc.gs/
jvm_flags=(
  -XX:+UseG1GC
  -XX:+ParallelRefProcEnabled
  -XX:MaxGCPauseMillis=200
  -XX:+UnlockExperimentalVMOptions
  -XX:+DisableExplicitGC
  -XX:+AlwaysPreTouch
  -XX:G1NewSizePercent=30
  -XX:G1MaxNewSizePercent=40
  -XX:G1HeapRegionSize=8M
  -XX:G1ReservePercent=20
  -XX:G1HeapWastePercent=5
  -XX:G1MixedGCCountTarget=4
  -XX:InitiatingHeapOccupancyPercent=15
  -XX:G1MixedGCLiveThresholdPercent=90
  -XX:G1RSetUpdatingPauseTimePercent=5
  -XX:SurvivorRatio=32
  -XX:+PerfDisableSharedMem
  -XX:MaxTenuringThreshold=1
  -Dusing.aikars.flags=https://mcflags.emc.gs
  -Daikars.new.flags=true
)

# Minecraft arguments you might want to start your server with.
# Usually there is not much to configure here:
mc_args=(
  #--nogui # Since we are using screen we want the GUI or screen won't stay open
)
# END OF SETTINGS

# Build the arguments that will be passed to java:
java_args=(
  -Xms"${heap_size}" # Set heap min size
  -Xmx"${heap_size}" # Set heap max size
  "${jvm_flags[@]}" # Use jvm flags specified above
  -jar "${server_jar}" # Run the server
  "${mc_args[@]}" # And pass it these settings
)

# Set path variable
#USERPATH="pathvariable"
#PathLength=${#USERPATH}
#if [[ "$PathLength" -gt 12 ]]; then
#    PATH="$USERPATH"
#else
#    echo "Unable to set path variable."
#fi

# Check to make sure that we are not running as root.
if [[ $(id -u) = 0 ]]; then
   echo "This script is not meant to run as root or sudo.  Please run as a normal user with ./start.sh.  Exiting..."
   exit 1
fi

# Check if server is already running
if screen -list | grep -q "\.minecraft"; then
    echo "Server is already running!  Type screen -r minecraft to open the console"
    exit 1
fi

# Flush out memory to disk so we have the maximum available for Java allocation.
sudo sh -c "echo 1 > /proc/sys/vm/drop_caches"
sync

# Check if network interfaces are up.
NetworkChecks=0
DefaultRoute=$(route -n | awk '$4 == "UG" {print $2}')
while [ -z "$DefaultRoute" ]; do
    echo "Network interface not up, will try again in 1 second";
    sleep 1;
    DefaultRoute=$(route -n | awk '$4 == "UG" {print $2}')
    NetworkChecks=$((NetworkChecks+1))
    if [ $NetworkChecks -gt 20 ]; then
        echo "Waiting for network interface to come up timed out - starting server without network connection ..."
        break
    fi
done

# Take ownership of the server files and set correct permissions.
Permissions=$(bash /dirname/minecraft/setperm.sh -a)

# Back up the server.
bash /dirname/minecraft/backup.sh


echo "Starting your Minecraft server."

screen -dmS minecraft java -jar "${java_args[@]}"

# Verify that the server has started in a screen.
StartChecks=0
while [ $StartChecks -lt 30 ]; do
  if screen -list | grep -q "\.minecraft"; then
    #screen -r minecraft
    break
  fi
  sleep 1s
  StartChecks=$((StartChecks + 1))
done

if [[ $StartChecks == 30 ]]; then
  echo "Server has failed to start after 30 seconds."
  exit 1
fi

sleep 5

# Double check that the screen is still working.
if screen -list | grep -q "\.minecraft"; then
  echo "Your Minecraft server is now starting."
  echo "The process can take several minutes. Please be patient."
  echo "To view the window that your server is running in type...  screen -r minecraft"
  echo "To minimize the window and let the server run in the background, press Ctrl+A then Ctrl+D"
else
  echo "Your Minecraft server attempted to start but failed."
fi
