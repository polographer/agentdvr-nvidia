# Agent DVR NVidia

# Use NVidia maintained docker image
# FROM nvidia/cuda:11.1-runtime-ubuntu18.04 
FROM nvidia/cuda:11.2.2-runtime-ubuntu20.04

#Define download location variables
#ARG FILE_LOCATION="https://ispyfiles.azureedge.net/downloads/Agent_Linux64_4_9_6_0.zip"
ENV FILE_LOCATION_SET=${FILE_LOCATION:+true}
ENV DEFAULT_FILE_LOCATION="https://www.ispyconnect.com/api/Agent/DownloadLocation2?productID=24&is64=true&platform=Linux"
ARG DEBIAN_FRONTEND=noninteractive 
ARG TZ=Australia/Melbourne
    

# Download and install dependencies
RUN apt-get update \
    && apt-get install -y wget libtbb-dev libc6-dev unzip gss-ntlmssp software-properties-common libjpeg-turbo8 libjpeg8
    # && wget http://security.ubuntu.com/ubuntu/pool/main/libj/libjpeg-turbo/libjpeg-turbo8_1.5.2-0ubuntu5.18.04.4_amd64.deb \
    # && wget http://fr.archive.ubuntu.com/ubuntu/pool/main/libj/libjpeg8-empty/libjpeg8_8c-2ubuntu8_amd64.deb \
    # && dpkg -i libjpeg-turbo8_1.5.2-0ubuntu5.18.04.4_amd64.deb \
    # && dpkg -i libjpeg8_8c-2ubuntu8_amd64.deb \
    # && rm libjpeg8_8c-2ubuntu8_amd64.deb \
    # && rm libjpeg-turbo8_1.5.2-0ubuntu5.18.04.4_amd64.deb

# Install aspdotnet on top of nvidia image
RUN apt-get install -y gpg
RUN wget -O - https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o microsoft.asc.gpg
RUN mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/
RUN wget https://packages.microsoft.com/config/ubuntu/18.04/prod.list
RUN mv prod.list /etc/apt/sources.list.d/microsoft-prod.list
RUN apt-get update \
  && apt-get install -y apt-transport-https \
  && apt-get update \
  && apt-get install -y aspnetcore-runtime-3.1


# Install cybermax's ffmpeg with nvidia

# Set NVIDAI capabilities
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility,video

# Get NVIDIA version of ffmpeg
RUN add-apt-repository -y ppa:cybermax-dexter/sdl2-backport && apt-get update
RUN add-apt-repository -y ppa:cybermax-dexter/ffmpeg-nvenc && apt-get update
RUN apt-get install -y ffmpeg

# Download/Install iSpy Agent DVR: 
# Check if we were given a specific version
RUN if [ "${FILE_LOCATION_SET}" = "true" ]; then \
    echo "Downloading from specific location: ${FILE_LOCATION}" && \
    wget -c ${FILE_LOCATION} -O agent.zip; \
    else \
    #Get latest instead
    echo "Downloading latest" && \
    wget -c $(wget -qO- "https://www.ispyconnect.com/api/Agent/DownloadLocation2?productID=24&is64=true&platform=Linux" | tr -d '"') -O agent.zip; \
    fi && \
    unzip agent.zip -d /agent && \
    rm agent.zip
    
# Install libgdiplus, used for smart detection
RUN apt-get install -y libgdiplus
    
# Install Time Zone
RUN apt-get install -y tzdata

# Clean up
RUN apt-get -y --purge remove unzip wget \ 
    && apt autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Docker needs to run a TURN server to get webrtc traffic to and from it over forwarded ports from the host
# These are the default ports. If the ports below are modified here you'll also need to set the ports in XML/Config.xml
# for example <TurnServerPort>3478</TurnServerPort><TurnServerMinPort>50000</TurnServerMinPort><TurnServerMaxPort>50010</TurnServerMaxPort>
# The main server port is overridden by creating a text file called port.txt in the root directory containing the port number, eg: 8090
# To access the UI you must use the local IP address of the host, NOT localhost - for example http://192.168.1.12:8090/

# Define default environment variables
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Main UI port
EXPOSE 8090

# HTTPS port
EXPOSE 443

# STUN server port
EXPOSE 3478/udp

# TURN server UDP port range
EXPOSE 50000-50010/udp

# Data volumes
VOLUME ["/agent/Media/XML", "/agent/Media/WebServerRoot/Media", "/agent/Commands"]

#user setup #WIP
# ARG UNAME=agentdvr
# ARG UID=1000
# ARG GID=1000
# RUN groupadd -g $GID -o $UNAME
# RUN useradd -m -u $UID -g $GID -o -s /bin/bash $UNAME
# USER $UNAME


# Define service entrypoint
CMD ["dotnet", "/agent/Agent.dll"]
