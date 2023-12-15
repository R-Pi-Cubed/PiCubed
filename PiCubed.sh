#!/bin/bash

# This script is an installation aid to help install a Minecraft server on a Raspberry Pi.
# For detailed instrustions please visit https://docs.picubed.me
# Note - This script will NOT fetch any version of minecraft. The user is responsible for transfering a copy of the latest
# minecraft server *.jar file to the Pi in the proper directory. Please visit https://docs.picubed.me

# Parts of this script have been pulled from other sources and are credited here in no order of priority.
# GitHub Repository: https://gist.github.com/Prof-Bloodstone/6367eb4016eaf9d1646a88772cdbbac5
# GitHub Repository: https://github.com/TheRemote/RaspberryPiMinecraft
# GitHub Repository: https://github.com/Cat5TV/pinecraft

# PiCubed server version - not currently used for anything
Version="0.9"

# The minimum Java version required for the version on Minecraft you want to install
MinJavaVer=17

# Terminal colors using ANSI escape
# Foreground
fgBLACK=$(tput setaf 0)
fgRED=$(tput setaf 1)
fgGREEN=$(tput setaf 2)
fgYELLOW=$(tput setaf 3)
fgBLUE=$(tput setaf 4)
fgMAGENTA=$(tput setaf 5)
fgCYAN=$(tput setaf 6)
fgWHITE=$(tput setaf 7)
#Text formatting options
txMOVEUP=$(tput cuu 1)
txCLEARLINE=$(tput el 1)
txBOLD=$(tput bold)
txRESET=$(tput sgr0)
txREVERSE=$(tput smso)
txUNDERLINE=$(tput smul)

# apt update counter to not update more than once
Updated=0

# Get the current system user
UserName=$(whoami)

# Prints a line with color using terminal codes
Print_Style() {
  printf "%s\n" "${2}$1${txRESET}"
}

# Configure how much memory to use for the Minecraft server
Get_ServerMemory() {
  sync

  Print_Style " " "$fgCYAN"
  Print_Style "Checking the total system memory..." "$fgCYAN"
  TotalMemory=$(awk '/MemTotal/ { printf "%.0f\n", $2/1024 }' /proc/meminfo)
  AvailableMemory=$(awk '/MemAvailable/ { printf "%.0f\n", $2/1024 }' /proc/meminfo)

  sleep 1s

  Print_Style "Total system memory: $TotalMemory" "$fgCYAN"
  Print_Style "Total available memory: $AvailableMemory" "$fgCYAN"

  if [ $AvailableMemory -lt 1024 ]; then
    Print_Style " " "$fgCYAN"
    Print_Style "WARNING:  There is less than 1Gb of available system memory. This will impact performance and stability." "$fgRED"
    Print_Style "You may be able to increase the available memory by closing other processes." "$fgYELLOW"
    Print_Style "If nothing else is running your operating system may be using all available memory." "$fgYELLOW"
    Print_Style "Please be sure that you are using a headless (no GUI) operating system." "$fgYELLOW"
    Print_Style "Installation aborted." "$fgRED"
    exit 1
  elif [ "$AvailableMemory" -lt 3072 ]; then
    Print_Style " " "$fgCYAN"
    Print_Style "CAUTION: There is a limited amount of RAM available." "$fgYELLOW"
    Print_Style "The Operating system and background processes require some ram to function properly." "$fgYELLOW"
    Print_Style "With $AvailableMemory you may experience performance issues." "$fgYELLOW"
  fi
    
  Print_Style " " "$fgCYAN"
  Print_Style "Please enter the amount of memory you want to dedicate to the server." "$fgCYAN"
  Print_Style "You must leave enough left over memory for the system to run background processes." "$fgCYAN"
  Print_Style "If the system is not left with enough ram it will crash." "$fgCYAN"
  Print_Style "NOTE: For optimal performance this ram will always be reserved for the server while the server is running." "$fgYELLOW"

  MemSelected=0

  RecommendedMemory=$(($AvailableMemory - 1024))

  while [[ $MemSelected -lt 1024 || $MemSelected -ge $AvailableMemory ]]; do
    Print_Style " " "$fgCYAN"
    Print_Style "Enter the amount of memory in megabytes to dedicate to the Minecraft server (recommended: $RecommendedMemory):" "$fgCYAN"
    read MemSelected < /dev/tty
    if [[ $MemSelected -lt 1024 ]]; then
      Print_Style "Please enter a minimum of 1024mb" "$fgRED"
      MemSelected=0
    elif [[ $MemSelected -gt $AvailableMemory ]]; then
      Print_Style "Please enter an amount less than the available system memory: ($AvailableMemory)" "$fgRED"
      MemSelected=0
    fi
  done
  Print_Style " " "$fgCYAN"
  Print_Style "The Minecraft server will be allocated $MemSelected MB of ram." "$fgGREEN"
  sleep 1s
}

# Updates all scripts
Update_Scripts() {
  cd "$DirName/minecraft"

  # Upsate start.sh
  Print_Style "Updating start.sh ..." "$fgYELLOW"
  sudo chmod +x start.sh
  sed -i "s:dirname:$DirName:g" start.sh
  sed -i "s:memselect:$MemSelected:g" start.sh
  sed -i "s:userxname:$UserName:g" start.sh
  sleep 1

  # Update stop.sh
  Print_Style "Updating stop.sh ..." "$fgYELLOW"
  sudo chmod +x stop.sh
  sed -i "s:dirname:$DirName:g" stop.sh
  sleep 1

  # Update restart.sh
  Print_Style "Updating restart.sh ..." "$fgYELLOW"
  sudo chmod +x restart.sh
  sed -i "s:dirname:$DirName:g" restart.sh
  sleep 1

  # Update backup.sh
  Print_Style "Updating backup.sh ..." "$fgYELLOW"
  sudo chmod +x backup.sh
  sed -i "s:dirname:$DirName:g" backup.sh
  sleep 1
}

# Update systemd files to create a Minecraft service.
Update_Service() {
  sudo cp "$DirName"/PiCubed/minecraft.service /etc/systemd/system/
  sudo sed -i "s:userxname:$UserName:g" /etc/systemd/system/minecraft.service
  sudo sed -i "s:dirname:$DirName:g" /etc/systemd/system/minecraft.service
  sudo systemctl daemon-reload
  Print_Style " " "$fgCYAN"
  Print_Style "Your Paper Minecraft server can start automatically at boot if enabled." "$fgCYAN"
  Print_Style "Start Minecraft server automatically at boot? (y/n)?" "$fgYELLOW"
  read answer < /dev/tty
  if [ "$answer" != "${answer#[Yy]}" ]; then
    sudo systemctl enable minecraft.service
  fi
}

# Configure a CRON job to reboot the system daily
# Minecraft servers benefit from a daily reboot in off hours
# It's also a good time to do the daily backup
Configure_Reboot() {
  # Automatic reboot at 4am configuration
  TimeZone=$(cat /etc/timezone)
  CurrentTime=$(date)
  Print_Style " " "$fgCYAN"
  Print_Style "Your time zone is currently set to $TimeZone." "$fgCYAN"
  Print_Style "Current system time: $CurrentTime" "$fgCYAN"
  Print_Style " " "$fgCYAN"
  sleep 1s
  Print_Style "It is highly recommended to reboot your Minecraft server regularly." "$fgCYAN"
  Print_Style "During a reboot is also a good time to do a server backup." "$fgCYAN"
  Print_Style "Server backups will automatically be cycled and only the most recent 10 backups will be kept." "$fgCYAN"
  Print_Style "You can adjust/remove the selected reboot & backup time later by typing crontab -e" "$fgCYAN"
  Print_Style "Enable automatic daily reboot and server at 4am (y/n)?" "$fgYELLOW"
  read answer < /dev/tty
  if [ "$answer" != "${answer#[Yy]}" ]; then
    croncmd="$DirName/minecraft/restart.sh"
    cronjob="0 4 * * * $croncmd 2>&1"
    (
      crontab -l | grep -v -F "$croncmd"
      echo "$cronjob"
    ) | crontab -
    Print_Style "Daily reboot scheduled.  To change time or remove automatic reboot type crontab -e" "$fgGREEN"
    sleep 1
  fi
}

Set_Permissions() {
  Print_Style " " "$fgCYAN"
  Print_Style "Setting server file permissions..." "$fgCYAN"
  sleep 1s
  #sudo ./setperm.sh -a > /dev/null
  sudo chown -Rv "$UserName $DirName/minecraft"
  sudo chmod -Rv 755 "$DirName/minecraft/*.sh"

}

Java_Check() {
  Print_Style "Checking Java..." "$fgCYAN"
  if [[ $Updated == 0 ]]; then
    sudo apt update > /dev/null 2>&1
    Updated=1
  fi

  # Java installed?
  if type -p java > /dev/null; then
    _java=java
  elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
      _java="$JAVA_HOME/bin/java"
  else
    Print_Style "No version of Java detected. Please install the latest JRE first and try again." "$fgRED"
    Print_Style " " "$fgCYAN"
    Print_Style "Install aborted." "$fgRED"
    Print_Style " " "$fgCYAN"
    exit 0
  fi

  # Detect the version of Java installed
  javaver=0
  if [[ "$_java" ]]; then
    javaver=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
  fi

  ver=0
  for i in $(echo $javaver | tr "." "\n")
  do
    if [[ $ver == 0 ]]; then
      ver=$i
    else
      subver=$i
      break
    fi
  done

  # minimum version of Java supported by Minecraft Server
  if [[ $ver -ge $MinJavaVer ]]; then
    Print_Style "The installed Java is version ${javaver}. You are good to go." "$fgGREEN"
    sleep 1s
  else
    Print_Style "The installed Java is version ${javaver}. You'll need a newer version of Java to continue." "$fgRED"
    exit 0
  fi
}

Configure_Server(){

  Print_Style " " "$fgCYAN"
  Print_Style "The server.properties file will now be configured." "$fgCYAN"
  sleep 1s
  Print_Style "All of the following settings and more can be changed later in" "$fgCYAN"
  Print_Style "the server.properties file in the minecraft directory." "$fgCYAN"
  sleep 1s
  
  # Set MOTD
  Print_Style " " "$fgCYAN"
  Print_Style "Please enter a name for your server." "$fgCYAN"
  read -r -p 'Server Name: ' ServerName < /dev/tty
  Print_Style "Setting server MOTD to $ServerName." "$fgWHITE"
  # Change the value if it exists
  /bin/sed -i "/motd=/c\motd=${ServerName} - A Minecraft Server" $DirName/minecraft/server.properties

  # Set the game mode
  Print_Style " " "$fgCYAN"
  Print_Style "Please choose one of the following game modes." "$fgCYAN"
  Print_Style "Survival-( s ) Creative-( c )" "$fgCYAN"
  read -r -p 'Game Mode: ' GameMode < /dev/tty

  case $GameMode in
    
    s | S)  #Default game difficulty is Easy - Nothing to do
        Print_Style "Server game mode left at the default survival setting." "$fgWHITE"
        ;;

    c | C)  # Set game difficulty to Normal (default is Easy)
        Print_Style "Setting server game mode to creative." "$fgWHITE"
        # Change the value if it exists
        /bin/sed -i '/gamemode=/c\gamemode=creative' $DirName/minecraft/server.properties
        ;;

    *)  # Set game difficulty to Normal (default is Easy)
        Print_Style "No available selection detected." "$fgYELLOW"
        Print_Style "Server game mode left at the default survival setting." "$fgWHITE"
        ;;

  esac
  sleep 1s


  # Set the game difficulty level
  Print_Style " " "$fgCYAN"
  Print_Style "Please choose one of the following difficulty levels." "$fgCYAN"
  Print_Style "Easy-( e ) Normal-( n ) Hard-( h ) Peaceful-( p)" "$fgCYAN"
  read -r -p 'Difficulty Level: ' DifLevel < /dev/tty

  case $DifLevel in
    
    e | E)  #Default game difficulty is Easy - Nothing to do
        Print_Style "Server difficulty left at the default easy setting." "$fgWHITE"
        ;;

    n | N)  # Set game difficulty to Normal (default is Easy)
        Print_Style "Setting server difficulty to Normal." "$fgWHITE"
        # Change the value if it exists
        /bin/sed -i '/difficulty=/c\difficulty=normal' $DirName/minecraft/server.properties
        ;;

    h | H)  # Set game difficulty to Normal (default is Easy)
        Print_Style "Setting server difficulty to Hard." "$fgWHITE"
        # Change the value if it exists
        /bin/sed -i '/difficulty=/c\difficulty=hard' $DirName/minecraft/server.properties
        ;;

    p | P)  # Set game difficulty to Normal (default is Easy)
        Print_Style "Setting server difficulty to Peaceful." "$fgWHITE"
        # Change the value if it exists
        /bin/sed -i '/difficulty=/c\difficulty=peaceful' $DirName/minecraft/server.properties
        ;;

    *)  # Set game difficulty to Normal (default is Easy)
        Print_Style "No available selection detected." "$fgYELLOW"
        Print_Style "Setting server difficulty to Normal." "$fgWHITE"
        # Change the value if it exists
        /bin/sed -i '/difficulty=/c\difficulty=normal' $DirName/minecraft/server.properties
        ;;

  esac
  sleep 1s

  # Option to set a custom level seed
  Print_Style " " "$fgCYAN"
  Print_Style "You can optionally set you own custom world seed." "$fgCYAN"
  sleep 1s
  Print_Style "By default a random world seed will be generated if you do not set a custom seed." "$fgCYAN"
  Print_Style "If you don't know what this is or are unsure the best option is to select no and let the game generate a random world." "$fgCYAN"
  Print_Style "For more information visit docs.picubed.me." "$fgCYAN"
  sleep 1s
  Print_Style " " "$fgCYAN"
  Print_Style "Do you want to set a custom world seed? (y/n)?" "$fgCYAN"
  read answer < /dev/tty
  if [ "$answer" != "${answer#[Yy]}" ]; then
    Print_Style " " "$fgCYAN"
    Print_Style "Please enter your custom world seed." "$fgCYAN"
    read -r -p 'Seed: ' Seed < /dev/tty
    Print_Style "Setting the seed." "$fgWHITE"
    # Change the value if it exists
    /bin/sed -i "/level-seed=/c\level-seed=${seed}" $DirName/minecraft/server.properties
    sleep 1s
  fi

  # Change the default port number
  Print_Style " " "$fgCYAN"
  Print_Style "The default connection port for a Minecraft server is 25565." "$fgCYAN"
  sleep 1s
  Print_Style "It is recommended that you change this port number if you will be allowing external connections to your server." "$fgCYAN"
  Print_Style "For more information visit docs.picubed.me." "$fgCYAN"
  sleep 1s
  Print_Style "Do you want to change your connection port? (y/n)?" "$fgCYAN"
  read answer < /dev/tty
  if [ "$answer" != "${answer#[Yy]}" ]; then

    PortNumber=0

    while [[ $PortNumber -lt 10001 || $MemSelected -ge 65536 ]]; do
      Print_Style " " "$fgCYAN"
      Print_Style "You must select a port number between 10001 and 65535." "$fgCYAN"
      Print_Style "Please enter your new 5 digit port number." "$fgCYAN"
      read -r -p 'Port Number: ' PortNumber < /dev/tty
      if [[ $PortNumber -lt 10001 ]]; then
        Print_Style "The port number you entered is too low." "$fgRED"
        PortNumber=0
      elif [[ $PortNumber -gt 65535 ]]; then
        Print_Style "The port number you entered is too high." "$fgRED"
        PortNumber=0
      fi
    done
    
    Print_Style "Setting the server port to $PortNumber." "$fgWHITE"
    Print_Style "Please write down your port number somewhere safe." "$fgYELLOW"
    Print_Style "You will need it later to connect to your server." "$fgYELLOW"
    # Change the value if it exists
    /bin/sed -i "/query.port=/c\query.port=${PortNumber}" $DirName/minecraft/server.properties
    sleep 4s
  fi

  # Set network compression
  Print_Style "Setting network compression threshold to 512" "$fgWHITE"
  # Change the value if it exists
  /bin/sed -i '/network-compression-threshold=256/c\network-compression-threshold=512' $DirName/minecraft/server.properties
  sleep 1s

  # Set max number of players
  Print_Style "Setting the maximum number of simultaneous players to 10" "$fgWHITE"
  # Change the value if it exists
  /bin/sed -i '/max-players=/c\max-players=10' $DirName/minecraft/server.properties
  sleep 1s

  # Set flight error handling - this is to prevent the game from falsely think a player is flying
  Print_Style "Setting allow flight to true - this is for error control - not to allow flying in game." "$fgWHITE"
  # Change the value if it exists
  /bin/sed -i '/allow-flight=false/c\allow-flight=true' $DirName/minecraft/server.properties
  sleep 1s

}

# Update Server configuration
Optimize_Server(){
  #Send a stop command to the server instance
  #This is only executed by the server after it is finished loading
  screen -Rd minecraft -X stuff "stop $(printf '\r')"
  Print_Style "Please be patient." "$fgYELLOW$txREVERSE"
  Print_Style "We will have to let the server finish loading before it can be stopped safely." "$fgYELLOW$txBOLD"
  Print_Style "The system will wait up to 5 minuutes before quiting." "$fgYELLOW"

  #Check to see if the server is still running
  StopChecks=0
  while [ $StopChecks -lt 300 ]; do
    if ! screen -list | grep -q "\.minecraft"; then
      break
    fi
    sleep 1;
    StopChecks=$((StopChecks+1))
  done

  # Cancel optimization if the server can't be stopped
  if screen -list | grep -q "\.minecraft"; then
    Print_Style "The server has still not closed after 5 minutes." "$fgRED"
    Print_Style "Automatic optimization not possible." "$fgRED"
    Print_Style "You Pi will now reboot and attempt to restart the server." "$fgYELLOW"
    sleep 5s
    sudo reboot   
  fi

  if [[ -e $DirName/minecraft/bukkit.yml ]]; then
    Print_Style "bukkit.yml found." "$fgCYAN"

    # spawn-limits: monsters: 63
    Print_Style "Setting spawn-limits: monsters: 63" "$fgWHITE"
    # Change the value if it exists
    /bin/sed -i '/monsters: 70/c\monsters: 63' $DirName/minecraft/bukkit.yml
    sleep 1s
  fi

  if [[ -e $DirName/minecraft/spigot.yml ]]; then
    Print_Style "spigot.yml found." "$fgCYAN"

    # save-user-cache-on-stop-only
    Print_Style "Setting save-user-cache-on-stop-only: true" "$fgWHITE"
    # Change the value if it exists
    /bin/sed -i '/save-user-cache-on-stop-only: false/c\save-user-cache-on-stop-only: true' $DirName/minecraft/spigot.yml
    sleep 1s
    
    # max-tick-time
    Print_Style "Setting max-tick-time: tile: 1000 - entity: 1000" "$fgWHITE"
    # Change the value if it exists
    /bin/sed -i '/tile: 50/c\tile: 1000' $DirName/minecraft/spigot.yml
    /bin/sed -i '/entity: 50/c\entity: 1000' $DirName/minecraft/spigot.yml
    sleep 1s
    
     # merge radius
    Print_Style "Setting merge-radius: exp: 6.0 - item: 4.0" "$fgWHITE"
    # Change the value if it exists
    /bin/sed -i '/exp: 3.0/c\exp: 6.0' $DirName/minecraft/spigot.yml
    /bin/sed -i '/item: 2.5/c\item: 3.0' $DirName/minecraft/spigot.yml
    sleep 1s
    
     # restart script
    Print_Style "Setting the restart script to restart.sh" "$fgWHITE"
    # Change the value if it exists
    /bin/sed -i '/restart-script: ./start.sh/c\restart-script: ./restart.sh' $DirName/minecraft/spigot.yml
    sleep 1s
 fi

  if [[ -e $DirName/minecraft/paper.yml ]]; then
    Print_Style "paper.yml found." "$fgCYAN"
    
    # prevent-moving-into-unloaded-chunks
    Print_Style "Setting prevent-moving-into-unloaded-chunks: true" "$fgWHITE"
    # Change the value if it exists
    /bin/sed -i '/prevent-moving-into-unloaded-chunks: false/c\prevent-moving-into-unloaded-chunks: true' $DirName/minecraft/paper.yml
    sleep 1s
    
    # use-faster-eigencraft-redstone
    Print_Style "Setting use-faster-eigencraft-redstone: true" "$fgWHITE"
    # Change the value if it exists
    /bin/sed -i '/use-faster-eigencraft-redstone: false/c\use-faster-eigencraft-redstone: true' $DirName/minecraft/paper.yml
    sleep 1s
    
    # fix-climbing-bypassing-cramming-rule
    Print_Style "Setting fix-climbing-bypassing-cramming-rule: true" "$fgWHITE"
    # Change the value if it exists
    /bin/sed -i '/fix-climbing-bypassing-cramming-rule: false/c\fix-climbing-bypassing-cramming-rule: true' $DirName/minecraft/paper.yml
    sleep 1s
    
    # grass-spread-tick-rate
    Print_Style "Setting grass-spread-tick-rate: 2" "$fgWHITE"
    # Change the value if it exists
    /bin/sed -i '/grass-spread-tick-rate: 1/c\grass-spread-tick-rate: 2' $DirName/minecraft/paper.yml
    sleep 1s
    
    # optimize-explosions
    Print_Style "Setting optimize-explosions: true" "$fgWHITE"
    # Change the value if it exists
    /bin/sed -i '/optimize-explosions: false/c\optimize-explosions: true' $DirName/minecraft/paper.yml
    sleep 1s
    
    # lootables: auto-replenish:
    Print_Style "Setting auto-replenish: true" "$fgWHITE"
    # Change the value if it exists
    /bin/sed -i '/auto-replenish: false/c\auto-replenish: true' $DirName/minecraft/paper.yml
    sleep 1s
    
    # book-size: page-max:
    Print_Style "Setting book-size: page-max: 1280" "$fgWHITE"
    # Change the value if it exists
    /bin/sed -i '/page-max: 2560/c\page-max: 1280' $DirName/minecraft/paper.yml
    sleep 1s
    
    # monster-spawn-max-light-level:
    Print_Style "Setting monster-spawn-max-light-level: 7" "$fgWHITE"
    # Change the value if it exists
    /bin/sed -i '/monster-spawn-max-light-level: -1/c\monster-spawn-max-light-level: 7' $DirName/minecraft/paper.yml
    sleep 1s
    
    # monster-spawn-max-light-level:
    Print_Style "Setting monster-spawn-max-light-level: 7" "$fgWHITE"
    # Change the value if it exists
    /bin/sed -i '/monster-spawn-max-light-level: -1/c\monster-spawn-max-light-level: 7' $DirName/minecraft/paper.yml
    sleep 1s
    
  fi

  # Restart the server after optimization
  Print_Style "Optimization is complete." "$txBOLD$fgGREEN"
  Print_Style "Your server will now be restarted to implement the changes." "$fgCYAN"
  Print_Style "NOTE: World generation can take several minutes. Please be patient." "$fgYELLOW"
  sleep 3
  Start_Server
}

Dependancy_Check(){

  CPUArch=$(uname -m)

  Print_Style "Doing a dependancy check." "$fgCYAN"
  sleep 1s

  if [[ "$CPUArch" == *"aarch64"* || "$CPUArch" == *"arm64"* ]]; then
    Print_Style "You are running a 64 bit operating system." "$fgGREEN"
    sleep 1s
  else
    if [[ "$CPUArch" == *"armv7"* || "$CPUArch" == *"armhf"* ]]; then
      Print_Style "You are running a 32 bit operating system." "$fgRED"
      Print_Style "This script does not support 32 bit operating systems. Please upgrade your base os to a 64 bit system." "$fgYellow"
      Print_Style "In the near future Minecraft Java will no longer support a 32 bit OS." "$fgYellow"
      exit 1
    else
      Print_Style "Unable to verify your operating system." "$fgRED"
      Print_Style "Please ensure that you are running a 64 bit operating system." "$fgYellow"
      exit 1
    fi
  fi

  # Verify the directory path
  if [ -d "$HOME/PiCubed" ]; then
    Print_Style "The Home directory has been verified." "$fgGREEN"
    DirName=$HOME
    sleep 1s
  else
    Print_Style "Failed to find the PiCubed directory." "$fgRED"
    Print_Style "Exiting." "$fgRED"
    exit 1
  fi

  if [ $(dpkg-query -W -f='${Status}' screen 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    Print_Style "Installing the latest version of screen.... Not your screen, the program known as screen." "$fgYELLOW"
    if [[ $Updated == 0 ]]; then
      sudo apt update > /dev/null 2>&1
      Updated=1
    fi
    sudo apt -y install screen > /dev/null 2>&1
  else
    Print_Style "The latest version of screen has been detected.... Not your screen, the program known as screen." "$fgGREEN"
    sleep 1s
  fi

}

Cleanup(){

  #placeholder
  rm -rf "$DirName/PiCubed"

}

Build_System(){

  cd ~

  ServerFile="$DirName/PiCubed/paper.jar"

  if [ -f "$ServerFile" ]; then
    Print_Style "Located the paper.jar file." "$fgGREEN"
    sleep 1s
  else 
    Print_Style "Unable to locate the $ServerFile file." "$fgRED"
    Print_Style "Please be sure that you have uploaded the latest paper.jar file to the PiCubed directory." "$fgYELLOW"
    Print_Style "Also be sure that it is named paper.jar." "$fgYELLOW"
    exit 1
  fi

  # Check to see if the Minecraft directory already exists.
  if [ -d "$DirName/minecraft" ]; then
    Print_Style "An existing Minecraft directory has been found." "$fgRED"
    Print_Style "Please remove the directory before continuing." "$fgRED"
    exit 1
  else
    Print_Style "Creating the Minecraft directory." "$fgCYAN"
    mkdir minecraft
    sleep 1s
  fi

  # Verify if the directory was created correctly
  if [ -d "$DirName/minecraft" ]; then
    Print_Style "Moving into the Minecraft directory." "$fgCYAN"
    cd "$DirName/minecraft"
    sleep 1s
  else
    Print_Style "Failed to create the Minecraft directory." "$fgRED"
    Print_Style "Exiting." "$fgRED"
    exit 1
  fi

  # Create the backup directory
  Print_Style "Creating the backups directory." "$fgCYAN"
  mkdir backups
  sleep 1s

  Print_Style "Copying files." "$fgCYAN"
  sudo cp "$DirName"/PiCubed/{start.sh,stop.sh,restart.sh,backup.sh,paper.jar} "$DirName"/minecraft/

  cd ~
}

Init_Server(){
  
  cd "$DirName/minecraft"

  Print_Style " " "$fgCYAN"
  Print_Style "Now running the server jar for the first time." "$fgYELLOW"
  sleep 1s
  Print_Style "This will initialize the server but it will not start. Please wait." "$fgYELLOW"
  sleep 1s
  Print_Style "Errors at this stage are normal and expected." "$fgYELLOW"
  sleep 1s
  Print_Style "Please wait." "$fgYELLOW$txREVERSE"
  Print_Style " " "$fgCYAN"
  java -jar -Xms1000M -Xmx1000M paper.jar --nogui

  # Accept the EULA
  Print_Style " " "$fgCYAN"
  Print_Style "End-User License Agreement" "$txBOLD$fgCYAN"
  sleep 1s
  Print_Style "To continue you must accept the Minecraft EULA." "$fgYELLOW"
  sleep 1s
  Print_Style " " "$fgCYAN"
  Print_Style "From the EULA....." "$fgCYAN"
  sleep 1s
  Print_Style " " "$fgCYAN"
  Print_Style "By changing the setting below to TRUE you are indicating your agreement to our EULA" "$fgWHITE"
  sleep 1s
  Print_Style "(https://account.mojang.com/documents/minecraft_eula)." "$fgWHITE"
  sleep 1s
  Print_Style " " "$fgCYAN"
  Print_Style "You also agree that tacos are tasty, and the best food in the world." "$fgWHITE"
  sleep 1s
  Print_Style " " "$fgCYAN"
  Print_Style "Do you accept the EULA? (y/n)?" "$fgYELLOW"
  read answer < /dev/tty
  if [ "$answer" != "${answer#[Yy]}" ]; then
    Print_Style "Accepting the EULA..." "$fgGREEN"
    /bin/sed -i '/eula=false/c\eula=true' $DirName/minecraft/eula.txt
    sleep 1
  else
    Print_Style " " "$fgCYAN"
    Print_Style "We cannot continue until you accept the EULA." "$fgYELLOW"
    sleep 1s
    Print_Style "Answering no again will exit the setup." "$fgYELLOW"
    sleep 1s
    Print_Style " " "$fgCYAN"
    Print_Style "Do you accept the EULA? (y/n)?" "$fgYELLOW"
    read answer < /dev/tty

    if [ "$answer" != "${answer#[Yy]}" ]; then
      Print_Style "Accepting the EULA..." "$fgGREEN" 
      /bin/sed -i '/eula=false/c\eula=true' $DirName/minecraft/eula.txt
      sleep 1
    else
      Print_Style " " "$fgCYAN"
      Print_Style "You have chosen..... poorly." "$fgRED"
      sleep 1
      Print_Style "Exiting the setup." "$fgYELLOW"
      exit 1
    fi

  fi
  
  cd ~

}

Start_Server(){
  sudo systemctl start minecraft.service

  # Wait up to 30 seconds for server to start
  StartChecks=0
  while [ $StartChecks -lt 30 ]; do
    if screen -list | grep -q "\.minecraft"; then
      Print_Style "Your Minecraft server $ServerName is now starting on $IP" "$fgCYAN"
      break
    fi
    sleep 1s
    StartChecks=$((StartChecks + 1))
  done

  if [[ $StartChecks == 30 ]]; then
    Print_Style "Server has failed to start after 30 seconds." "$fgRED"
    exit 1
  fi

}
#################################################################################################

clear

Print_Style "PiCubed Minecraft server installation script" "$txREVERSE$fgCYAN"
Print_Style " " "$fgCYAN"
Print_Style "The latest version is available at https://github.com/R-Pi-Cubed/PiCubed-Minecraft-Installer" "$fgCYAN"

# Check to make sure we aren't running as root
if [[ $(id -u) = 0 ]]; then
   Print_Style "This script is not meant to run as root or sudo.  Please run as a normal user with ./PiCubed.sh  Exiting..." "$fgRED"
   exit 1
fi

sleep 1s

# Verify the assumed dependancies
Dependancy_Check

#Check that Java is installed and it's a recent enough version
Java_Check

# Build the system structure
Build_System

# Get total system memory
Get_ServerMemory

# Run the Minecraft server for the first time which will build the server and exit saying the EULA needs to be accepted.
Init_Server

# Update Minecraft server scripts
Update_Scripts

# Service configuration
Update_Service

# Configure automatic start on boot
Configure_Reboot

# Sudoers configuration
#Update_Sudoers

# Fix server files/folders permissions
#Set_Permissions

# Update Server configuration
if [[ -e $DirName/minecraft/server.properties ]]; then
  Configure_Server
fi

# Basic server installed
Print_Style "Setup is complete." "$txBOLD$fgGREEN"
Print_Style "Your server will now be started for the first time to test the service created for autostart." "$fgCYAN"
Print_Style "NOTE: World generation can take several minutes. Please be patient." "$fgYELLOW"
sleep 5
Start_Server

#Offer semi-auto optimization
Print_Style " " "$fgCYAN"
Print_Style "This script can optionally update your server configuration files" "$fgCYAN"
Print_Style "for the most common performance adjustements." "$fgCyan"
sleep 1s
Print_Style " " "$fgCYAN"
Print_Style "Do you want to optimize? (y/n)?" "$fgYELLOW"
read answer < /dev/tty
if [ "$answer" != "${answer#[Yy]}" ]; then
  Optimize_Server
fi

Print_Style " " "$fgCYAN"
Print_Style "Server installation complete." "$fgGREEN$txBOLD"
Print_Style "To view the screen that your server is running in type...  screen -r minecraft" "$fgYELLOW"
Print_Style "To exit the screen and let the server run in the background, press Ctrl+A then Ctrl+D" "$fgYELLOW"
Print_Style "For the full documentation: https://docs.picubed.me" "$fgCYAN"
exit 0