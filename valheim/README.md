# Peon War Plan - Valheim

The PEON war plan that Peon uses to deploy your game server.

![Valheim](./logo.png)

## Documentation

If you would like info on how to use this plan, the up-to-date documentation can be found in the [PEON project game guide](http://docs.warcamp.org/guides/games/valheim/).

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/K3K567ILJ)

## Stand-alone Use

This recipe can be used without the wider PEON project components.

### Guide

For this guide, please make sure you have [Docker Compose](https://docs.docker.com.zh.xy2401.com/v17.12/compose/install/) installed and running.

1. Download this folder and its contents.
2. Create a file `docker-compose.yml` in the directory with the contents below.
3. Ensure that any scripts in the directory (i.e. `server_start`, `init_custom`) are executable by the docker user.
    ```bash
    chown 1000:1000 server_start
    chmod u+x server_start
    ```
4. Start the server. You can now start the server with the following command `docker-compose up -d`/`docker compose up -d`. You can then follow the deployment using `docker-compose logs -f`

#### docker-compose.yml

You can change any of the settings according to your needs.

```yml
version: '3'
services:
  server:
    container_name: peon.warcamp.valheim.default
    hostname: peon.steamcmd.valheim
    image: umlatt/steamcmd
    ports:
      - 2456:2456/udp
      - 2457:2457/udp
      - 2458:2458/udp
    environment:
      - STEAMID=896660
      # GAME SERVER VARIABLES
      - PORT=2456
      - SERVERNAME="my-valheim-server"
      - WORLDNAME="my-valheim-world"
      - PASSWORD="some-password"
    volumes:
      - ./actions:/actions
      - ./data:/home/steam/steamcmd/data
      - ./config:/home/steam/config
      - ./user:/home/steam/.config/unity3d/IronGate/Valheim
```
