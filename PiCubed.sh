#!/bin/bash

# This script is an installation aid to help install a Minecraft server on a Raspberry Pi.
# Note - This script will NOT fetch any version of minecraft. The user is responsible for transfering a copy of the latest
# minecraft server *.jar file to the Pi in the proper directory. 

# This script is a combination of several sources and are credited here in no order of priority.
# GitHub Repository: https://gist.github.com/Prof-Bloodstone/6367eb4016eaf9d1646a88772cdbbac5
# GitHub Repository: https://github.com/TheRemote/RaspberryPiMinecraft
# GitHub Repository: https://github.com/Cat5TV/pinecraft


# PiCubed server version
Version="0.1"

# The minimum Java version required for the version on Minecraft you want to install
minjavaver=17


UserName=$(whoami)

# Terminal colors using ANSI escape
# Foreground
fgBLACK=$(tput setaf 000)
fgRED=$(tput setaf 009)
fgGREEN=$(tput setaf 010)
fgYELLOW=$(tput setaf 011)
fgBLUE=$(tput setaf 012)
fgMAGENTA=$(tput setaf 013)
fgCYAN=$(tput setaf 014)
fgWHITE=$(tput setaf 015)
#Text formatting options
txBRIGHT=$(tput bold)
txNORMAL=$(tput sgr0)
txBLINK=$(tput blink)
txREVERSE=$(tput smso)
txUNDERLINE=$(tput smul)

# Prints a line with color using terminal codes
Print_Style() {
  printf "%s\n" "${2}$1${NORMAL}"
}

# Function to read input from user with a prompt - Only used once in fetching the directory.
function read_with_prompt {
  variable_name="$1"
  prompt="$2"
  default="${3-}"
  unset $variable_name
  while [[ ! -n ${!variable_name} ]]; do
    read -p "$prompt: " $variable_name < /dev/tty
    if [ ! -n "`which xargs`" ]; then
      declare -g $variable_name=$(echo "${!variable_name}" | xargs)
    fi
    declare -g $variable_name=$(echo "${!variable_name}" | head -n1 | awk '{print $1;}')
    if [[ -z ${!variable_name} ]] && [[ -n "$default" ]] ; then
      declare -g $variable_name=$default
    fi
    echo -n "$prompt : ${!variable_name} -- accept (y/n)?"
    read answer < /dev/tty
    if [[ "$answer" == "${answer#[Yy]}" ]]; then
      unset $variable_name
    else
      echo "$prompt: ${!variable_name}"
    fi
  done
}

# Configure how much memory to use for the Minecraft server
Get_ServerMemory() {
  sync

  Print_Style "Getting total system memory..." "$fgYELLOW"
  TotalMemory=$(awk '/MemTotal/ { printf "%.0f\n", $2/1024 }' /proc/meminfo)
  AvailableMemory=$(awk '/MemAvailable/ { printf "%.0f\n", $2/1024 }' /proc/meminfo)
  CPUArch=$(uname -m)

  sleep 1s

  Print_Style "Total memory: $TotalMemory - Available Memory: $AvailableMemory" "$fgYELLOW"
  if [[ "$CPUArch" == *"armv7"* || "$CPUArch" == *"armhf"* ]]; then
    Print_Style "Warning: You are running a 32 bit operating system which has a hard limit of 3 GB of memory per process" "$fgRED"
    Print_Style "Warning: This installer is intended for a 64 bit headless operating system, continue at your own discression." "$fgRED"
    if [ "$AvailableMemory" -gt 2700 ]; then
      echo
      Print_Style "Warning: There is a limited amount of RAM available. The Operating system requires some ram to function properly." "$fgRED"
      Print_Style "You must also leave behind some room for the Java VM process overhead.  It is not recommended to exceed 2700 and if you experience crashes you may need to reduce it further." "$fgYELLOW"
      Print_Style "You can remove this limit by using a headless 64 bit operating system like Ubuntu." "$fgYELLOW"
      AvailableMemory=2700
    fi
  fi
  if [ $AvailableMemory -lt 1024 ]; then
    Print_Style "WARNING:  Available memory to run the server is less than 1000MB. This will impact performance and stability." "$fgRED"
    Print_Style "You may be able to increase available memory by closing other processes. If nothing else is running your distro may be using all available memory." "$fgYELLOW"
    Print_Style "It is recommended to use a headless distro (Lite or Server version) to ensure you have the maximum memory available possible." "$fgYELLOW"
    echo -n "Press any key to continue"
    read endkey < /dev/tty
    exit 1
  fi

  # Suggest an amount of memory to use and confirm with the user.
  if [[ "$CPUArch" == *"aarch64"* || "$CPUArch" == *"arm64"* ]]; then
    Print_Style "INFO: You are running a 64-bit architecture." "$fgMAGENTA"
    if [ "$AvailableMemory" -gt 2700 ]; then
      Print_Style "INFO: You can use more than 2700MB of RAM for the Minecraft server." "$fgMAGENTA"
    fi
  fi
  echo
  Print_Style "Please enter the amount of memory you want to dedicate to the server.  A minimum of 1024MB is recommended." "$fgCYAN"
  Print_Style "You must leave enough left over memory for the operating system to run background processes." "$fgCYAN"
  Print_Style "If the operating system is not left with enough ram it will crash." "$fgCYAN"
  MemSelected=0
  RecommendedMemory=$(($AvailableMemory - 2000))
  while [[ $MemSelected -lt 1000 || $MemSelected -ge $TotalMemory ]]; do
    echo -n "Enter amount of memory in megabytes to dedicate to the Minecraft server (recommended: $RecommendedMemory): " 
    read MemSelected < /dev/tty
    if [[ $MemSelected -lt 1000 ]]; then
      Print_Style "Please enter a minimum of 1000" "$fgRED"
    elif [[ $MemSelected -gt $TotalMemory ]]; then
      Print_Style "Please enter an amount less than the total memory in the system ($TotalMemory)" "$fgRED"
    elif [[ $MemSelected -gt 2700 && "$CPUArch" == *"armv7"* || "$CPUArch" == *"armhf"* ]]; then
      Print_Style "You are running a 32 bit operating system which has a limit of 2700MB.  Please enter 2700 to use it all." "$fgRED"
      Print_Style "If you experience crashes at 2700MB you may need to run SetupMinecraft again and lower it further." "$fgRED"
      Print_Style "You can lift this restriction by upgrading to a 64 bit operating system." "$fgRED"
      MemSelected=0
    fi
  done
  Print_Style "Amount of memory for Minecraft server selected: $MemSelected MB" "$fgGREEN"
  sleep 2
}

# Updates all scripts
Update_Scripts() {
  cd $DirName/minecraft

  # Upsate start.sh
  Print_Style "Updating start.sh ..." "$fgYELLOW"
  chmod +x start.sh
  sed -i "s:dirname:$DirName:g" start.sh
  sed -i "s:memselect:$MemSelected:g" start.sh
  sed -i "s<pathvariable<$PATH<g" start.sh

  sleep 1

  # Update stop.sh
  Print_Style "Updating stop.sh ..." "$fgYELLOW"
  chmod +x stop.sh
  sed -i "s:dirname:$DirName:g" stop.sh
  sed -i "s<pathvariable<$PATH<g" stop.sh

  sleep 1

  # Update restart.sh
  Print_Style "Updating restart.sh ..." "$fgYELLOW"
  chmod +x restart.sh
  sed -i "s:dirname:$DirName:g" restart.sh
  sed -i "s<pathvariable<$PATH<g" restart.sh

  sleep 1

  # Update setperm.sh
  Print_Style "Updating setperm.sh ..." "$fgYELLOW"
  chmod +x setperm.sh
  sed -i "s:dirname:$DirName:g" setperm.sh
  sed -i "s:userxname:$UserName:g" setperm.sh
  sed -i "s<pathvariable<$PATH<g" setperm.sh

  sleep 1

  # Update backup.sh
  Print_Style "Updating backup.sh ..." "$fgYELLOW"
  chmod +x backup.sh
  sed -i "s:dirname:$DirName:g" backup.sh
  sed -i "s<pathvariable<$PATH<g" backup.sh

  sleep 1

  # Update backup.sh
  Print_Style "Updating backupnas.sh ..." "$fgYELLOW"
  chmod +x backupnas.sh
  sed -i "s:dirname:$DirName:g" backup.sh
  sed -i "s<pathvariable<$PATH<g" backup.sh

}

# Update systemd files to create a Minecraft service.
Update_Service() {
  sudo cp minecraft.service /etc/systemd/system/
  sudo sed -i "s:userxname:$UserName:g" /etc/systemd/system/minecraft.service
  sudo sed -i "s:dirname:$DirName:g" /etc/systemd/system/minecraft.service
  sudo systemctl daemon-reload
  Print_Style "Your Parper Minecraft server can start automatically at boot if enabled." "$fgCYAN"
  echo -n "Start Minecraft server at startup automatically (y/n)?"
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
  Print_Style "Your time zone is currently set to $TimeZone.  Current system time: $CurrentTime" "$fgCYAN"
  Print_Style "It is highly recommended to reboot your Minecraft server regularly." "$fgCYAN"
  Print_Style "During a reboot is also a good time to do a server backup." "$fgCYAN"
  Print_Style "Server backups will automatically be cycled and only the most recent 10 backups will be kept." "$fgCYAN"
  Print_Style "You can adjust/remove the selected reboot & backup time later by typing crontab -e" "$fgCYAN"
  echo -n "Automatically reboot the Pi and backup the server daily at 4am (y/n)?"
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
  echo "Setting server file permissions..."
  sudo ./setperm.sh -a > /dev/null
}

Check_Java() {
Print_Style "Checking Java..." "$fgCYAN"
apt-get update > /dev/null 2>&1

# Java installed?
if type -p java > /dev/null; then
  _java=java
elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
    _java="$JAVA_HOME/bin/java"
else
  Print_Style "No version of Java detected. Please install the latest JRE first and try again." "$fgRED"
  echo
  echo "Install aborted."
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
if [[ $ver > 8 ]] || [[ $ver == 1 ]] && [[ $subver > 8 ]]; then
  Print_Style "The installed Java is version ${javaver}. You'll need a newer version of JRE." "$fgRED"
  echo
  echo "Failed."
  echo
  exit 0
fi
}

Configure_Server(){

if [[ -e $DirName/minecraft/server.properties ]]; then

  Print_Style "Please enter a name for your server." "$fgMAGENTA"
  Print_Style "This can be changed later in the server.properties file in your minecraft directory." "$fgMAGENTA"
  read -p 'Server Name: ' servername < /dev/tty

  # Set game difficulty to Normal (default is Easy, but we want at least SOME challenge)
  # Change the value if it exists
  /bin/sed -i '/difficulty=/c\difficulty=normal' $DirName/minecraft/server.properties
  # Add it if it doesn't exist
  if ! grep -q "difficulty=" $DirName/minecraft/server.properties; then
    echo "difficulty=normal" >> $DirName/minecraft/server.properties
  fi

  # Set server name
  # Change the value if it exists
  /bin/sed -i '/server-name=/c\server-name=$servername' $DirName/minecraft/server.properties
  # Add it if it doesn't exist
  if ! grep -q "server-name=" $DirName/minecraft/server.properties; then
    echo "server-name=$servername" >> $DirName/minecraft/server.properties
  fi

  # Set MOTD
  # Change the value if it exists
  /bin/sed -i '/motd=/c\motd=$servername' $DirName/minecraft/server.properties
  # Add it if it doesn't exist
  if ! grep -q "motd=" $DirName/minecraft/server.properties; then
    echo "motd=$servername" >> $DirName/minecraft/server.properties
  fi

  #echo "server-name=$servername" >>server.properties
  #echo "motd=$servername" >>server.properties
  #echo "difficulty=normal" >>server.properties

fi

}

dependancy_check(){

if [ $(dpkg-query -W -f='${Status}' screen 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  Print_Style "Installing the latest version of screen.... Not your screen, the program known as screen." "$fgYELLOW"
  if [[ $updated == 0 ]]; then
    apt-get update > /dev/null 2>&1
    updated=1
  fi
  apt-get -y install screen > /dev/null 2>&1
fi
# Install dependencies needed to run minecraft in the background
#Print_Style "Installing the latest version of screen.... Not your screen, the program known as screen." "$fgYELLOW"
#sleep 2s
#sudo apt-get update
#sudo apt-get install screen -y
#sudo apt-get install net-tools -y

}

#################################################################################################

Print_Style "PiCubed Minecraft server installation script" "$CYAN"
Print_Style "The latest version is always available at https://https://github.com/R-Pi-Cubed/PiCubed-Minecraft-Installer" "$fgCYAN"

# Check to make sure we aren't running as root
if [[ $(id -u) = 0 ]]; then
   Print_Style "This script is not meant to run as root or sudo.  Please run as a normal user with ./PiCubed.sh  Exiting..." "$fgRED"
   exit 1
fi

sleep 2s

# Install dependencies needed to run minecraft in the background
dependancy_check

# Get the directory path (default ~)
until [ -d "$DirName" ]
do
  Print_Style "Please enter the root directory path to install the Minecraft server." "$fgCYAN"
  Print_Style "If you are not sure what this is just enter the default. (default = ~)" "$fgCYAN"
  Print_Style "If you're installing to a different disk altogether the default won't work. " "$fgCYAN"
  read_with_prompt DirName "Directory Path" ~
  DirName=$(eval echo "$DirName")
  if [ ! -d "$DirName" ]; then
    Print_Style "Invalid directory. Please use the default path (default = ~) if you aren't familiar with fully qualified Linux paths or you're going to have errors." "$fgRED"
  fi
done

# Check to see if the Minecraft directory already exists.
if [ -d "$DirName/minecraft" ]; then
  Print_Style "Found Minecraft directory." "$fgGREEN"
  sleep 1s
else
  Print_Style "Minecraft directory not found. Exiting." "$fgRED"
  exit 1
fi

Print_Style "Moving into the Minecraft directory." "$fgCYAN"
cd "$DirName/minecraft"

# Create backup directory
# Check to see if the backup directory already exists.
if [ -d "$DirName/minecraft/backups" ]; then
  Print_Style "A backups directory already exists." "$fgGREEN"
  sleep 2s
else
  Print_Style "Creating the backups directory." "$fgYELLOW"
  mkdir backups
  sleep 2s
fi

# Get total system memory
Get_ServerMemory

# Run the Minecraft server for the first time which will build the server and exit saying the EULA needs to be accepted.
Print_Style "Now running the server jar for the first time." "$fgYELLOW"
sleep 1
Print_Style "This will initialize the server but it will not start. Please wait." "$fgYELLOW"
java -jar -Xms1000M -Xmx1000M paper.jar --nogui

# Accept the EULA
Print_Style "End-User License Agreement" "$fgMAGENTA"
Print_Style "In order to proceed, you must read and accept the EULA at https://account.mojang.com/documents/minecraft_eula" "$fgCYAN"
echo -n "Do you accept the EULA? (y/n)?"
read answer < /dev/tty
if [ "$answer" != "${answer#[Yy]}" ]; then
  Print_Style "Accepting the EULA..." "$fgGREEN"
  echo eula=true >eula.txt
  sleep 1
else
  Print_Style "We cannot continue until you accept the EULA." "$fgYELLOW"
  Print_Style "Answering no again will exit the setup." "$fgYELLOW"
  echo -n "Do you accept the EULA? (y/n)?"
  read answer < /dev/tty

  if [ "$answer" != "${answer#[Yy]}" ]; then
    Print_Style "Accepting the EULA..." "$fgGREEN"
    echo eula=true >eula.txt
    sleep 1
  else
    Print_Style "You have chosen..... poorly." "$fgRED"
    sleep 1
    Print_Style "Exiting the setup." "$fgYELLOW"
    exit 1
  fi

fi

# Update Minecraft server scripts
Update_Scripts

# Service configuration
Update_Service

# Configure automatic start on boot
Configure_Reboot

# Sudoers configuration
Update_Sudoers

# Fix server files/folders permissions
Set_Permissions

# Update Server configuration
Configure_Server

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
  exit

else
  #screen -r minecraft
  Print_Style "Installation complete." "$fgCYAN"
  Print_Style "Please Remember: World generation can take a few minutes. Be patient." "$fgYELLOW"
  Print_Style "Your Minecraft server $servername is now starting on $ip" "$fgCYAN"
  Print_Style "For the full documentation: https://github.com/R-Pi-Cubed/PiCubed-Minecraft-Installer" "$fgCYAN"
  #Print_Style "Support The Project: https://patreon.com" "$fgCYAN"
  exit
  
fi
