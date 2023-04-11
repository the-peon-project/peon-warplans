#!/bin/bash
logfile="/var/log/peon/${0##*/}.log"
rootpath="/home/steam/steamcmd/"
configpath="/home/steam/steamcmd/peon/config"
cd $rootpath
echo "" > $logfile
# Logging config start - capture all
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>>$logfile 2>&1
# Logging config end
echo "##################### STARTING SERVER ######################"
# FIRST RUN CHECK
echo ""
if [ ! -f "$configpath/ServerGameSettings.json" ]; then
        echo "$configpath/ServerGameSettings.json not found. Copying default file."
        cp "$rootpath/data/VRisingServer_Data/StreamingAssets/Settings/ServerGameSettings.json" "$configpath" 2>&1
fi
if [ ! -f "$configpath/ServerHostSettings.json" ]; then
        echo "$configpath/ServerHostSettings.json not found. Copying default file."
        cp "$rootpath/data/VRisingServer_Data/StreamingAssets/Settings/ServerHostSettings.json" "$configpath" 2>&1
fi
conf_file="/home/steam/steamcmd/peon/config/server.config"
printf '{ "Server IP" : "'$PUBLIC_IP'",'    > $conf_file
printf '"PORT" : "'$GAMEPORT'",'            >> $conf_file
printf '"Server Name" : "'$SERVERNAME'",'   >> $conf_file
printf '"World" : "'$WORLDNAME'",'          >> $conf_file
printf '"Password" : "'$PASSWORD'" }'       >> $conf_file
# CUSTOM GAME SERVER COMMAND
echo "Clean any existing /tmp/.X0-lock"
rm -rf /tmp/.X0-lock 2>&1
echo "Start Xvfb"
Xvfb :0 -screen 0 1024x768x16 &
echo "Start game server (Using 'DISPLAY=:0.0 ' as a prefix to wine)"
DISPLAY=:0.0 wine64 data/VRisingServer.exe -persistentDataPath $configpath -serverName "$SERVERNAME" -saveName "$WORLDNAME" -logFile "/var/log/peon/server.log" "$GAMEPORT" "$QUERYPORT" 2>&1