# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install all dependencies
# All tools are installed and cached in the image layer for offline use.
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository universe && \
    apt-get update && \
    apt-get install -y \
    mdk3 \
    macchanger \
    pwgen \
    python3 \
    curl \
    wget \
    cowsay \
    figlet \
    wireless-tools \
    net-tools \
    network-manager \
    iproute2 \
    kmod \
    pciutils \
    usbutils \
    sudo \
    nano \
    rfkill \
    aircrack-ng \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Copy the project files into the container
COPY . .

# Ensure scripts are executable
RUN chmod +x main.sh .name.py

# The application requires root privileges and direct hardware access.
# Built-in tools are already cached, making the image ready for offline environments.
ENTRYPOINT ["/bin/bash", "./main.sh"]
