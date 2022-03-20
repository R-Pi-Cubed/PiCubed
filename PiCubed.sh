#!/bin/bash

# This script is an installation aid to help install a Minecraft server on a Raspberry Pi.
# For detailed instrustions please visit https://docs.picubed.me
# Note - This script will NOT fetch any version of minecraft. The user is responsible for transfering a copy of the latest
# minecraft server *.jar file to the Pi in the proper directory. 

# This script is a combination of several sources and are credited here in no order of priority.
# GitHub Repository: https://gist.github.com/Prof-Bloodstone/6367eb4016eaf9d1646a88772cdbbac5
# GitHub Repository: https://github.com/TheRemote/RaspberryPiMinecraft
# GitHub Repository: https://github.com/Cat5TV/pinecraft


# PiCubed server version - not currently used for anything
Version="0.1"

# The minimum Java version required for the version on Minecraft you want to install
MinJavaVer=17

# apt update counter to not update more than once
Updated=0

# Get the current system user
UserName=$(whoami)

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
txBLINK=$(tput blink)
txREVERSE=$(tput smso)
txUNDERLINE=$(tput smul)


# Prints a line with color using terminal codes
Print_Style() {
  printf "%s\n" "${2}$1${txRESET}"
}

# Configure how much memory to use for the Minecraft server
Get_ServerMemory() {
  sync

  echo
  Print_Style "Checking the total system memory..." "$fgCYAN"
  TotalMemory=$(awk '/MemTotal/ { printf "%.0f\n", $2/1024 }' /proc/meminfo)
  AvailableMemory=$(awk '/MemAvailable/ { printf "%.0f\n", $2/1024 }' /proc/meminfo)

  sleep 1s

  Print_Style "Total memory: $TotalMemory - Available Memory: $AvailableMemory" "$fgCYAN"

  if [ $AvailableMemory -lt 1024 ]; then
    echo
    Print_Style "WARNING:  Available memory to run the server is less than 1024MB. This will impact performance and stability." "$fgRED"
    Print_Style "You may be able to increase available memory by closing other processes." "$fgYELLOW"
    Print_Style "If nothing else is running your operating system may be using all available memory." "$fgYELLOW"
    Print_Style "The recommended setup is to use a headless distro (Lite or Server version) to ensure you have the maximum memory available possible." "$fgYELLOW"
    #echo -n "Press any key to continue"
    #read endkey < /dev/tty
    exit 1
  elif [ "$AvailableMemory" -lt 3000 ]; then
    echo
    Print_Style "CAUTION: There is a limited amount of RAM available." "$fgYELLOW"
    Print_Style "The Operating system and background processes require some ram to function properly." "$fgYELLOW"
    Print_Style "With $AvailableMemory you may experience performance issues." "$fgYELLOW"
  fi
    
  echo
  Print_Style "Please enter the amount of memory you want to dedicate to the server." "$fgCYAN"
  Print_Style "You must leave enough left over memory for the system to run background processes." "$fgCYAN"
  Print_Style "If the system is not left with enough ram it will crash." "$fgCYAN"
  Print_Style "NOTE: For optimal performance this ram will always be reserved for the server while the server is running." "$fgYELLOW"

  MemSelected=0

  RecommendedMemory=$(($AvailableMemory - 1536))

  while [[ $MemSelected -lt 1024 || $MemSelected -ge $AvailableMemory ]]; do
    Print_Style "Enter amount of memory in megabytes to dedicate to the Minecraft server (recommended: $RecommendedMemory):" "$fgYELLOW"
    #echo -n "Enter amount of memory in megabytes to dedicate to the Minecraft server (recommended: $RecommendedMemory): " 
    read MemSelected < /dev/tty
    if [[ $MemSelected -lt 1024 ]]; then
      Print_Style "Please enter a minimum of 1024mb" "$fgRED"
      MemSelected=0
    elif [[ $MemSelected -gt $AvailableMemory ]]; then
      Print_Style "Please enter an amount less than the available memory in the system ($AvailableMemory)" "$fgRED"
      MemSelected=0
    fi
  done
  echo
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
  #sed -i "s<pathvariable<$PATH<g" start.sh

  sleep 1

  # Update stop.sh
  Print_Style "Updating stop.sh ..." "$fgYELLOW"
  sudo chmod +x stop.sh
  sed -i "s:dirname:$DirName:g" stop.sh
  #sed -i "s<pathvariable<$PATH<g" stop.sh

  sleep 1

  # Update restart.sh
  Print_Style "Updating restart.sh ..." "$fgYELLOW"
  sudo chmod +x restart.sh
  sed -i "s:dirname:$DirName:g" restart.sh
  #sed -i "s<pathvariable<$PATH<g" restart.sh

  sleep 1

  # Update setperm.sh
  Print_Style "Updating setperm.sh ..." "$fgYELLOW"
  sudo chmod +x setperm.sh
  sed -i "s:dirname:$DirName:g" setperm.sh
  sed -i "s:userxname:$UserName:g" setperm.sh
  sed -i "s<pathvariable<$PATH<g" setperm.sh

  sleep 1

  # Update backup.sh
  Print_Style "Updating backup.sh ..." "$fgYELLOW"
  sudo chmod +x backup.sh
  sed -i "s:dirname:$DirName:g" backup.sh
  sed -i "s<pathvariable<$PATH<g" backup.sh

  sleep 1

  # Update backupnas.sh
  #Print_Style "Updating backupnas.sh ..." "$fgYELLOW"
  #chmod +x backupnas.sh
  #sed -i "s:dirname:$DirName:g" backup.sh
  #sed -i "s<pathvariable<$PATH<g" backup.sh

}

# Update systemd files to create a Minecraft service.
Update_Service() {
  sudo cp "$DirName/PiCubed/minecraft.service /etc/systemd/system/"
  sudo sed -i "s:userxname:$UserName:g" /etc/systemd/system/minecraft.service
  sudo sed -i "s:dirname:$DirName:g" /etc/systemd/system/minecraft.service
  sudo systemctl daemon-reload
  echo
  Print_Style "Your Parper Minecraft server can start automatically at boot if enabled." "$fgCYAN"
  Print_Style "Start Minecraft server at startup automatically (y/n)?" "$fgYELLOW"
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
  echo
  Print_Style "Your time zone is currently set to $TimeZone." "$fgCYAN"
  Print_Style "Current system time: $CurrentTime" "$fgCYAN"
  echo
  sleep 1s
  Print_Style "It is highly recommended to reboot your Minecraft server regularly." "$fgCYAN"
  Print_Style "During a reboot is also a good time to do a server backup." "$fgCYAN"
  Print_Style "Server backups will automatically be cycled and only the most recent 10 backups will be kept." "$fgCYAN"
  Print_Style "You can adjust/remove the selected reboot & backup time later by typing crontab -e" "$fgCYAN"
  Print_Style "Automatically reboot the Pi and backup the server daily at 4am (y/n)?" "$fgYELLOW"
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


Update_Sudoers() {
  if [ -d /etc/sudoers.d ]; then
    sudoline="$UserName ALL=(ALL) NOPASSWD: /bin/bash $DirName/minecraft/setperm.sh, /bin/systemctl start minecraft, /bin/bash $DirName/minecraft/start.sh, /sbin/reboot"
    if [ -e /etc/sudoers.d/minecraft ]; then
      AddLine=$(sudo grep -qxF "$sudoline" /etc/sudoers.d/minecraft || echo "$sudoline" | sudo tee -a /etc/sudoers.d/minecraft)
    else
      AddLine=$(echo "$sudoline" | sudo tee /etc/sudoers.d/minecraft)
    fi
  else
    echo "/etc/sudoers.d was not found on your system.  Please add this line to sudoers using sudo visudo:  $sudoline"
  fi
}

Set_Permissions() {
  echo
  Print_Style "Setting server file permissions..." "$fgCYAN"
  sleep 1s
  sudo ./setperm.sh -a > /dev/null
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
  echo
  Print_Style "Install aborted." "$fgRED"
  echo
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

  echo
  Print_Style "The server.properties file will now be configured." "$fgCYAN"
  sleep 1s
  Print_Style "Please enter a name for your server." "$fgCYAN"
  Print_Style "This can be changed later in the server.properties file in your minecraft directory." "$fgCYAN"
  read -p 'Server Name: ' ServerName < /dev/tty

  # Set game difficulty to Normal (default is Easy)
  Print_Style "Setting server difficulty to normal." "$fgWHITE"
  # Change the value if it exists
  /bin/sed -i '/difficulty=/c\difficulty=normal' $DirName/minecraft/server.properties

  # Set MOTD
  Print_Style "Setting server MOTD to $ServerName." "$fgWHITE"
  # Change the value if it exists
  /bin/sed -i "/motd=/c\motd=${servername} - A Minecraft Server" $DirName/minecraft/server.properties

  # Set network compression
  Print_Style "Setting network compression threshold to 512" "$fgWHITE"
  # Change the value if it exists
  /bin/sed -i '/network-compression-threshold=256/c\network-compression-threshold=512' $DirName/minecraft/server.properties

  # Set max number of players
  Print_Style "Setting the maximum number of simultaneous players to 10" "$fgWHITE"
  # Change the value if it exists
  /bin/sed -i '/max-players=20/c\max-players=10' $DirName/minecraft/server.properties

  # Set max number of players
  Print_Style "Setting allow flight to true - this is for error control - not to allow flying in game." "$fgWHITE"
  # Change the value if it exists
  /bin/sed -i '/allow-flight=false/c\allow-flight=true' $DirName/minecraft/server.properties

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
      apt update > /dev/null 2>&1
      Updated=1
    fi
    apt -y install screen > /dev/null 2>&1
  else
    Print_Style "The latest version of screen has been detected.... Not your screen, the program known as screen." "$fgGREEN"
    sleep 1s
  fi

}

Cleanup(){

  #placeholder
  rm -rf PiCubed

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
  sudo cp "$DirName"/PiCubed/{start.sh,stop.sh,restart.sh,setperm.sh,backup.sh,paper.jar} "$DirName"/minecraft/

  cd ~
}

Init_Server(){
  
  cd "$DirName/minecraft"

  echo
  Print_Style "Now running the server jar for the first time." "$fgYELLOW"
  sleep 1s
  Print_Style "This will initialize the server but it will not start. Please wait." "$fgYELLOW"
  sleep 1s
  Print_Style "Errors at this stage are normal and expected." "$fgYELLOW"
  sleep 1s
  Print_Style "Please wait." "$fgYELLOW$txREVERSE"
  echo
  java -jar -Xms1000M -Xmx1000M paper.jar --nogui

  # Accept the EULA
  echo
  Print_Style "End-User License Agreement" "$txBOLD$fgCYAN"
  sleep 1s
  Print_Style "To continue you must accept the Minecraft EULA. found at https://account.mojang.com/documents/minecraft_eula" "$fgYELLOW"
  Print_Style "The EULA can be found at https://account.mojang.com/documents/minecraft_eula" "$fgCYAN"
  sleep 1s
  Print_Style "Do you accept the EULA? (y/n)?" "$fgYELLOW"
  read answer < /dev/tty
  if [ "$answer" != "${answer#[Yy]}" ]; then
    Print_Style "Accepting the EULA..." "$fgGREEN"
    /bin/sed -i '/eula=false/c\eula=true' $DirName/minecraft/eula.txt
    #echo eula=true >eula.txt
    sleep 1
  else
    Print_Style "We cannot continue until you accept the EULA." "$fgYELLOW"
    Print_Style "Answering no again will exit the setup." "$fgYELLOW"
    Print_Style "Do you accept the EULA? (y/n)?" "$fgYELLOW"
    read answer < /dev/tty

    if [ "$answer" != "${answer#[Yy]}" ]; then
      Print_Style "Accepting the EULA..." "$fgGREEN" 
      /bin/sed -i '/eula=false/c\eula=true' $DirName/minecraft/eula.txt
      #echo eula=true >eula.txt
      sleep 1
    else
      Print_Style "You have chosen..... poorly." "$fgRED"
      sleep 1
      Print_Style "Exiting the setup." "$fgYELLOW"
      exit 1
    fi

  fi
  
  cd ~

}

#################################################################################################

clear

Print_Style "PiCubed Minecraft server installation script" "$txBOLD$fgCYAN"
Print_Style "The latest version is available at https://https://github.com/R-Pi-Cubed/PiCubed-Minecraft-Installer" "$fgCYAN"

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
Set_Permissions

# Update Server configuration
if [[ -e $DirName/minecraft/server.properties ]]; then
  Configure_Server
fi

# Finished!
Print_Style "Setup is complete. Starting your Minecraft server..." "$fgGREEN"
sudo systemctl start minecraft.service

# Wait up to 30 seconds for server to start
StartChecks=0
while [ $StartChecks -lt 30 ]; do
  if screen -list | grep -q "\.minecraft"; then
    screen -r minecraft
    break
  fi
  sleep 1s
  StartChecks=$((StartChecks + 1))
done

if [[ $StartChecks == 30 ]]; then
  Print_Style "Server has failed to start after 30 seconds." "$fgRED"
  exit 1

else
  #screen -r minecraft
  #Cleanup
  Print_Style "Installation complete." "$fgCYAN"
  Print_Style "Please Remember: World generation can take a few minutes. Be patient." "$fgYELLOW"
  Print_Style "Your Minecraft server $servername is now starting on $ip" "$fgCYAN"
  Print_Style "For the full documentation: https://github.com/R-Pi-Cubed/PiCubed-Minecraft-Installer" "$fgCYAN"
  exit 0

fi
