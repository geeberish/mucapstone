#!/bin/bash

# =========================================== WyrmAI ========================================== #
#
# Script Name:  install.sh
# Description:  This script automates the installation of our wyrmai tool and makes it usable
#               system wide. It installs Ollama if not already installed and sets up the required
#               python and system dependencies needed. Once set up the tool's files are copied
#               to /opt/wyrmai where a python venv is set up and installs needed packages. 
#               Finally it creates the global wyrmai command so this tool can be utilized
#               anywhere.
# Author:       Matt Penn
# Created:      2025-04-17
# Modified:     2025-05-02
# Version:      dev-2025-05-02
# Usage:        wyrmai --help
# Dependencies: chromadb, sentence-transformers, ollama (all in requirements.txt file), python3
#               python3-venv, python3-pip, Ollama
# Tested on:    Raspberry Pi 5, Ubuntu Server 25.04
# License:      Custom Academic License – for academic, non-commercial use only. See LICENSE.
# Notes:        Developed while attending Marymount University, CAE-CD, Arlington, VA, for the
#               class IT 489 Capstone Project. Project title: Offline AI Reconnaissance and
#               Hacking Tool. Team Members: Richard Flores, Natasha Menon, and Charles "Matt" Penn.
#
# =============================================================================================== #




# Define install location
INSTALL_DIR="/opt/wyrmai"
VENV_DIR="$INSTALL_DIR/venv"

# Ensure script is run with sudo
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root or use sudo"
    exit 1
fi

# Install Ollama if not installed
if ! command -v ollama &> /dev/null; then
    echo "Ollama not found. Installing..."
    curl -fsSL https://ollama.com/install.sh | sh
else
    echo "Ollama is already installed."
fi

# Install required system dependencies
echo "Installing system dependencies..."
apt update && apt install -y python3 python3-venv python3-pip

# Create installation directory
mkdir -p $INSTALL_DIR
cp -r * $INSTALL_DIR
cd $INSTALL_DIR || exit 1

# Set up virtual environment
python3 -m venv $VENV_DIR
$VENV_DIR/bin/pip install --upgrade pip
$VENV_DIR/bin/pip install -r requirements.txt

# Create system-wide command
cat <<EOF > /usr/local/bin/wyrmai
#!/bin/bash
$VENV_DIR/bin/python3 $INSTALL_DIR/main.py "\$@"
EOF

chmod +x /usr/local/bin/wyrmai

# Finish installation
echo "Installation complete. You can now use 'wyrmai' from anywhere."
