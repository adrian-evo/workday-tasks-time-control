#!/bin/sh
# Run tasks from within working time tray icon menu

# Default env.json
env=devdata/env.json

# Edit this value for a custom wait time in seconds when executing tasks from tray icon
wait=5

# Set to true to use rcc silent flag otherwise set to false
silent=true

# Name of plist file used as startup after computer restart
plist="$HOME/Library/LaunchAgents/workday.tasks.time.control.plist"

cwd="$(pwd)"

# On first run, when Output folder does not exists, silent is false anyway to that to have progress visible
if [ ! -d $cwd/output ]
then
	silent=false
fi

# If run without arguments, ask it
if [ $# -eq 0 ]
then
    while true; do
      read -p "Type the task to execute: In, Out, Verify, Custom, Icon [Icon]: " choice
      choice=${choice:-Icon}
      if [ "$choice" == "In" ] || [ "$choice" == "Out" ] || [ "$choice" == "Verify" ] || [ "$choice" == "Custom" ] || [ "$choice" == "Icon" ] || [ "$choice" == "Startup" ]
      then
        break
      else
        printf "The $choice is invalid taks. Please choose a valid task or close window to exit."
      fi
    done
else
  choice=$1
fi

# Write a plist file under /Library/launchAgents.
function write_plist() {
cat > $1 << STOP
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>workday.tasks.time.control</string>
    <key>OnDemand</key>
    <false/>
    <key>LaunchOnlyOnce</key>
    <true/>
    <key>ProgramArguments</key>
    <array>
        <string>$PWD/run-tasks.command</string>
        <string>Icon</string>
    </array>
</dict>
</plist>
STOP
}
FUNC=$(declare -f write_plist)

# Startup choice will add or remove a plist under launchAgents, that will automatically restart the Icon after computer restart
if [ "$choice" == "Startup" ]
then
  # check root run
  if [ "$EUID" -ne 0 ]
    then printf "The Startup option needs to be run as root.\n"
  fi
  # If plist already exists delete it
  if [ -f $plist ]
  then
    printf "The file $plist will be deleted now.\n"
    sudo rm $plist
  else
    printf "The file $plist will be created and 'run-tasks.command Icon' will be executed at computer restart.\n"
    sudo bash -c "$FUNC; write_plist $plist"
    sudo launchctl load -w $plist
  fi
  exit 0
fi

printf "\n\n"
for (( i=$wait; i>0; i--)); do
    printf "\rThe Check-$choice task will be executed in $i seconds. Press any key to continue."
    read -s -n 1 -t 1 key
    if [ $? -eq 0 ] 
    then
        break
    fi
done

# Execute the task choice by Apple osascript
osascript -ss - "$cwd" <<EOF

    on run argv -- argv is a list of strings
        tell application "Terminal"
            if application "Terminal" is not running then
              activate
              set R to False
            else
              set R to True
            end if
            set T to do script ("cd " & quoted form of item 1 of argv)
            set W to the id of window 1 where its tab 1 = T
            if $silent is true
              do script ("rcc run -t \"$choice\" -e \"$env\" --silent") in T
            else
              do script ("rcc run -t \"$choice\" -e \"$env\"") in T
            end
            repeat
              delay 1
              if not busy of T then exit repeat
            end repeat
            if R then
              close window id W
            else
              quit
            end
        end tell
    end run

EOF

exit 0