# agentdvr-nvidia-docker
Dockerfile and configuration for creating a container for AgentDVR with nvidia support

# pre-requisites

Install these 2 on your host machine

1. docker ce
https://docs.docker.com/engine/install/

2. Nvidia container toolkit
https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html

# docker compose 

after installing docker the easiest way to get started is to use docker compose.  Create a docker-compose.yml with this content:

```
version: '3.5'
services:
    agent-dvr:
      restart: unless-stopped
      privileged: true
      image: polographer/agentdvr-nvidia:latest
      volumes:
        - <change this to your media folder>:/agent/Media/WebServerRoot/Media/
        - <change this to your config folder>:/agent/Media/XML/
        - <change this to your commands folder>:/agent/Commands/
      ports:
          - "8090:8090"
          - "3478:3478/udp"
          - "50000-50010:50000-50010/udp"
      environment:
        NVIDIA_VISIBLE_DEVICES: "all"
        NVIDIA_DRIVER_CAPABILITIES: "compute,video,utility"
        TZ: "America/New_York"
      deploy:
        resources:
          reservations:
            devices:
              - driver: "nvidia"
                count: 1`
```
update the volumes to your computer's media, config and commands folders.  Then run `docker-compose up -d` to start the container.

# docker registry
https://hub.docker.com/repository/docker/polographer/agentdvr-nvidia/tags?page=1&ordering=last_updated
