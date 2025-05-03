#!/bin/bash

# =========================================== WyrmTools ========================================== #
#
# Script Name:  setuptools.sh
# Description:  Initial setup, configuration, and installation of tools on Raspberry Pi.
# Author:       Natasha "geeberish" Menon
# Created:      ...
# Modified:     2025-05-02
# Version:      dev-2025-05-02
# Usage:        sudo ./setuptools.sh
# Dependencies: software-properties-common, net-tools, git, nano, vim, golang, autotools-dev, 
#               build-essential, libpcap-dev, pipx, python3-pip, libtool, shtool, pkg-config, 
#               wget, ethtool, rfkill, libssl-dev, libgcrypt20-dev, libnl-3-dev, 
#               libnl-genl-3-dev, mono-complete
# Tested on:    Debian 12.10, BlueZ 5.66, Bash 5.2.15-2+b7
# License:      Custom Academic License – for academic, non-commercial use only. See LICENSE.
# Notes:        Developed while attending Marymount University, CAE-CD, Arlington, VA, for the
#               class IT 489 Capstone Project. Project title: Offline AI Reconnaissance and
#               Hacking Tool. Team Members: Richard Flores, Natasha Menon, and Charles "Matt" Penn.
#
# =============================================================================================== #

# Update and upgrade the system
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y software-properties-common net-tools git nano vim golang autotools-dev build-essential libpcap-dev pipx python3-pip libtool shtool pkg-config wget ethtool rfkill libssl-dev libgcrypt20-dev libnl-3-dev libnl-genl-3-dev mono-complete

# Install additional dependencies
sudo apt update && sudo apt install -y build-essential git libmicrohttpd-dev libnl-3-dev libnl-genl-3-dev libcap-dev libpcap-dev libsqlite3-dev libprotobuf-dev protobuf-compiler libncurses-dev libssl-dev pkg-config
sudo apt-get install -y libwebsockets-dev libusb-1.0-0-dev librtlsdr-dev
sudo apt install -y tshark nmap python3-scapy

# Clone and setup Exploit-Database
git clone https://gitlab.com/exploit-database/exploitdb.git /opt/exploit-database
ln -sf /opt/exploit-database/searchsploit /usr/local/bin/searchsploit
cp -n /opt/exploit-database/.searchsploit_rc ~/

# Clone and build arp-scan
git clone https://github.com/royhills/arp-scan.git
cd arp-scan
autoreconf --install
./configure
make
make check
make install
cd ..

# Clone and setup sqlmap
git clone --depth 1 https://github.com/sqlmapproject/sqlmap.git sqlmap-dev

# Install gvm-tools via pipx
python3 -m pipx install gvm-tools
echo 'export PATH=$PATH:/root/.local/bin' >> ~/.bashrc
source ~/.bashrc

# Clone and setup Social-Engineer Toolkit (SET)
git clone https://github.com/trustedsec/social-engineer-toolkit

# Download and install aircrack-ng
wget https://download.aircrack-ng.org/aircrack-ng-1.7.tar.gz
tar -zxvf aircrack-ng-1.7.tar.gz
cd aircrack-ng-1.7
autoreconf -i
./configure --with-experimental
make
make install
ldconfig
cd ..

# Download and install Snaffler
wget https://github.com/SnaffCon/Snaffler/releases/latest/download/Snaffler.exe -O Snaffler.exe

# Setup Kismet repository and install Kismet
wget -O - https://www.kismetwireless.net/repos/kismet-release.gpg.key --quiet | gpg --dearmor | sudo tee /usr/share/keyrings/kismet-archive-keyring.gpg >/dev/null
echo 'deb [signed-by=/usr/share/keyrings/kismet-archive-keyring.gpg] https://www.kismetwireless.net/repos/apt/git/noble noble main' | sudo tee /etc/apt/sources.list.d/kismet.list >/dev/null
sudo apt update
sudo apt install -y kismet

sudo apt install sl

# Install John the Ripper
sudo apt-get install -y john

# Clone and setup Responder
git clone https://github.com/lgandx/Responder.git
cd Responder
sudo apt install -y python3-netifaces
cd ..

# Install Hydra
sudo apt install -y hydra

# Install Metasploit
curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
chmod 755 msfinstall
./msfinstall

# Clone and setup Veil
git clone https://github.com/Veil-Framework/Veil.git
cd Veil/
./config/setup.sh --force --silent
cd ..

# Clone and build ScareCrow
git clone https://github.com/Tylous/ScareCrow.git
cd ScareCrow
go mod init github.com/Tylous/ScareCrow
go mod tidy
go build
./ScareCrow --help
cd ..

# Clone and build Freeze
git clone https://github.com/Tylous/Freeze.git
cd Freeze
go mod init freeze
go mod tidy
go build -o Freeze Freeze.go
cd ..

# Install Netcat
sudo apt install -y netcat-openbsd

# Install Bluetooth tools
sudo apt install -y bluetooth
sudo apt install core-utils bluetooth getty
sudo apt install core-utils bluetooth screen

# Install AI Tool
cd mucapstone
cd wyrmaiTool
chmod +x ./install.sh
chmod +x ./pull_manpages.sh
sudo ./install.sh
sudo ./pull_manpages.sh 
sudo wyrmai --process
cd ..
sudo ollama pull qwen2.5-coder:1.5b

# Run WyrmTermTarget.sh to create Bluetooth login listener service
cd /wyrmterm
chmod +x WyrmTermTarget.sh
./WyrmTermTarget.sh

sudo apt update && sudo apt upgrade -y

echo "All commands executed successfully!"
