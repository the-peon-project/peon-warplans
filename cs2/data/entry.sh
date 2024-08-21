#!/bin/bash
set -x

# Update and install packages
apt-get update
apt-get install -y --no-install-recommends --no-install-suggests \
    wget \
    ca-certificates \
    lib32z1 \
    simpleproxy \
    libicu-dev \
    unzip \
    jq

# Prepare directories and set permissions
mkdir -p "${STEAMAPPDIR}" || true
chmod +x "${STEAMAPPDIR}"/entry.sh
chown -R steam:steam "${STEAMAPPDIR}"/entry.sh "${STEAMAPPDIR}"

# Clean up
apt-get clean
find /var/lib/apt/lists/ -type f -delete
chown -R steam:steam "${STEAMAPPDIR}"
chmod 0777 "${STEAMAPPDIR}"

# Download Updates

if [[ "$STEAMAPPVALIDATE" -eq 1 ]]; then
    VALIDATE="validate"
else
    VALIDATE=""
fi

# steamclient.so fix
mkdir -p ~/.steam/sdk64
ln -sfT ${STEAMCMDDIR}/linux64/steamclient.so ~/.steam/sdk64/steamclient.so

# Install server.cfg
cp "${STEAMAPPDIR}"/server.cfg "${STEAMAPPDIR}"/game/csgo/cfg/server.cfg

# Download and extract custom config bundle
if [[ ! -z $CS2_CFG_URL ]]; then
    echo "Downloading config pack from ${CS2_CFG_URL}"
    wget -qO- "${CS2_CFG_URL}" | tar xvzf - -C "${STEAMAPPDIR}"
fi

# Rewrite Config Files

sed -i -e "s/{{SERVER_HOSTNAME}}/${SERVER_NAME}/g" \
       -e "s/{{SERVER_CHEATS}}/${CS2_CHEATS}/g" \
       -e "s/{{SERVER_HIBERNATE}}/${CS2_SERVER_HIBERNATE}/g" \
       -e "s/{{SERVER_PW}}/${CS2_PW}/g" \
       -e "s/{{SERVER_RCON_PW}}/${CS2_RCONPW}/g" \
       -e "s/{{TV_ENABLE}}/${TV_ENABLE}/g" \
       -e "s/{{TV_PORT}}/${TV_PORT}/g" \
       -e "s/{{TV_AUTORECORD}}/${TV_AUTORECORD}/g" \
       -e "s/{{TV_PW}}/${TV_PW}/g" \
       -e "s/{{TV_RELAY_PW}}/${TV_RELAY_PW}/g" \
       -e "s/{{TV_MAXRATE}}/${TV_MAXRATE}/g" \
       -e "s/{{TV_DELAY}}/${TV_DELAY}/g" \
       -e "s/{{SERVER_LOG}}/${CS2_LOG}/g" \
       -e "s/{{SERVER_LOG_MONEY}}/${CS2_LOG_MONEY}/g" \
       -e "s/{{SERVER_LOG_DETAIL}}/${CS2_LOG_DETAIL}/g" \
       -e "s/{{SERVER_LOG_ITEMS}}/${CS2_LOG_ITEMS}/g" \
       "${STEAMAPPDIR}"/game/csgo/cfg/server.cfg

if [[ ! -z $CS2_BOT_DIFFICULTY ]] ; then
    sed -i "s/bot_difficulty.*/bot_difficulty ${CS2_BOT_DIFFICULTY}/" "${STEAMAPPDIR}"/game/csgo/cfg/*
fi
if [[ ! -z $CS2_BOT_QUOTA ]] ; then
    sed -i "s/bot_quota.*/bot_quota ${CS2_BOT_QUOTA}/" "${STEAMAPPDIR}"/game/csgo/cfg/*
fi
if [[ ! -z $CS2_BOT_QUOTA_MODE ]] ; then
    sed -i "s/bot_quota_mode.*/bot_quota_mode ${CS2_BOT_QUOTA_MODE}/" "${STEAMAPPDIR}"/game/csgo/cfg/*
fi

# Switch to server directory
cd "${STEAMAPPDIR}/game/bin/linuxsteamrt64"

# Pre Hook
source "${STEAMAPPDIR}/pre.sh"

# Construct server arguments

if [[ -z $CS2_GAMEALIAS ]]; then
    # If CS2_GAMEALIAS is undefined then default to CS2_GAMETYPE and CS2_GAMEMODE
    CS2_GAME_MODE_ARGS="+game_type ${CS2_GAMETYPE} +game_mode ${CS2_GAMEMODE}"
else
    # Else, use alias to determine game mode
    CS2_GAME_MODE_ARGS="+game_alias ${CS2_GAMEALIAS}"
fi

if [[ -z $CS2_IP ]]; then
    CS2_IP_ARGS=""
else
    CS2_IP_ARGS="-ip ${CS2_IP}"
fi

if [[ ! -z $STEAM_GSLT ]]; then
    SV_SETSTEAMACCOUNT_ARGS="+sv_setsteamaccount ${STEAM_GSLT}"
fi

# Start Server

if [[ ! -z $CS2_RCON_PORT ]]; then
    echo "Establishing Simpleproxy for ${CS2_RCON_PORT} to 127.0.0.1:${CS2_PORT}"
    simpleproxy -L "${CS2_RCON_PORT}" -R 127.0.0.1:"${CS2_PORT}" &
fi

echo "Starting CS2 Dedicated Server"
eval "./cs2" -dedicated \
        "${CS2_IP_ARGS}" -port "${CS2_PORT}" \
        -console \
        -usercon \
        -high \
        -tickrate 128 \
        -maxplayers "${CS2_MAXPLAYERS}" \
        "${CS2_GAME_MODE_ARGS}" \
        +mapgroup "${CS2_MAPGROUP}" \
        +map "${CS2_STARTMAP}" \
        +rcon_password "${CS2_RCONPW}" \
        "${SV_SETSTEAMACCOUNT_ARGS}" \
        +sv_password "${CS2_PW}" \
        +sv_lan "${CS2_LAN}" \
        +sv_minrate 128000 \
        +sv_maxrate 0 \
        +sv_mincmdrate 128 \
        +sv_maxcmdrate 128 \
        +sv_minupdaterate 128 \
        +sv_maxupdaterate 128 \
        +sv_parallel_sendsnapshot 1 \
        "${CS2_ADDITIONAL_ARGS}"

# Post Hook
source "${STEAMAPPDIR}/post.sh"