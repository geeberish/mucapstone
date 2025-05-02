# Offline AI Assisted Reconnaissance and Hacking Tool over Bluetooth

**IT 489 Capstone Project**  
**Team Members:** Richard Flores, Natasha Menon, Matt Penn  


---

## Overview

This repository contains scripts and setup tools for the **Offline AI Reconnaissance and Hacking Tool**. The project enables secure, offline terminal sessions between two Linux devices(Laptop and Raspberri Pi using our custom Wrym ISO) over Bluetooth and automates the installation of a suite of security, reconnaissance, and AI tools.

---

## File Explanations

### `WyrmTermClient.sh`

- **Purpose:**  
  Run on the client device (e.g., laptop/tablet) to initiate a Bluetooth serial terminal connection to a remote target (we used a Raspberry Pi 5 with our custom ISO).
- **What it does:**  
  - Binds the Bluetooth serial port to the target device's MAC address.
  - Launches a terminal session (`screen`) over the Bluetooth connection.
  - Requires elevated privileges (`sudo`).
- **Known Issue:**  
  - On connection, some "AT" commands may appear at the login prompt due to modem emulation. Wait for these to finish before logging in.[1]

---

### `WyrmTermTarget.sh`

- **Purpose:**  
  Run on the target device to accept Bluetooth serial terminal connections from a client.
- **What it does:**  
  - Customizes the Bluetooth service to advertise a virtual serial port (channel 22).
  - Sets up and enables a systemd service (`btlogin`) to provide Getty-authenticated terminal logins over Bluetooth.
  - Requires elevated privileges (`sudo`).
- **Known Issue:**  
  - Similar to the client, "AT" commands may appear at the login prompt due to modem emulation. Wait for these before logging in.[3]

---

### `setuptools.sh`

- **Purpose:**  
  Automated setup script to install all required packages, tools, and dependencies for the project environment.
- **What it does:**  
  - Updates and upgrades the system.
  - Installs essential development tools and security/reconnaissance utilities (e.g., nmap, tshark, sqlmap, John the Ripper, Metasploit, Hydra, Kismet, Aircrack-ng, Responder, Veil, ScareCrow, Freeze, Snaffler, and more).
  - Clones and builds open-source tools from their repositories.
  - Installs Bluetooth tools and configures the environment for Bluetooth terminal connections.
  - Installs and configures AI tools and dependencies for the capstone project.
- **Notes:**  
  - Designed to be run with `sudo`.
  - Intended for both client and target devices.[2]

---

### `install.sh`

- **Purpose:**  
  Installs the AI hacking assistant (`wyrmai`) and its dependencies in a dedicated directory.
- **What it does:**  
  - Ensures the script is run as root.
  - Installs Ollama if not already present.
  - Installs Python 3, pip, and venv system packages.
  - Copies project files to `/opt/wyrmai`.
  - Sets up a Python virtual environment and installs Python dependencies from `requirements.txt`.
  - Creates a system-wide command `wyrmai` available from anywhere, which runs the main AI assistant.
- **Notes:**  
  - After completion, you can use the `wyrmai` command globally to launch the assistant.[6]

---

### `main.py`

- **Purpose:**  
  Core Python script for the offline AI hacking assistant.
- **What it does:**  
  - Uses Ollama and ChromaDB to provide AI-powered command suggestions and documentation retrieval.
  - Processes and stores Linux manual pages for offline use.
  - Supports interactive chat, single-query mode, and session history review.
- **Key Features:**  
  - Embeds and indexes man pages for fast semantic search.
  - Retrieves relevant documentation for user queries.
  - Generates command suggestions using an AI model (Qwen2.5-coder via Ollama).
  - Logs all queries and responses for session history.[4]

---

### `pull_manpages.sh`

- **Purpose:**  
  Extracts and saves documentation (man pages, --help, -h output) for a wide range of security and hacking tools.
- **What it does:**  
  - Creates a `manpages` directory.
  - Iterates through a list of common tools, saving their documentation output to individual text files.
  - Supports fallback to `--help` or `-h` if man pages are unavailable.
- **Notes:**  
  - Ensures the AI assistant has access to relevant offline documentation for command suggestions.[5]

---

## Usage

1. **Set up the environment:**  
   Install Ubuntu ISO file on Virtual Machine software or Raspberry Pi, pull `mucapstone ` with git.
   
2. **Set up the environment:**  
   Run `setuptools.sh` on both client and target devices to install all dependencies and tools.

3. **Install and configure the AI assistant:**  
   Navigate to the AI tool directory and run `install.sh` with `sudo`.

4. **Extract documentation:**  
   Run `pull_manpages.sh` to populate the `manpages` directory with tool documentation.

5. **Configure the target device:**  
   Run `BTTermTarget.sh` with `sudo` privileges.

6. **Connect from the client device:**  
   Run `BTTermClient.sh` with `sudo` privileges.

7. **Use the AI assistant:**  
   Use the `wyrmai` command to interact with the offline AI hacking tool.

---

## Known Issues

- Both terminal scripts may display a series of "AT" commands at the login prompt due to the way the Bluetooth connection is handled (modem vs. serial). Wait for these to finish before logging in.
- We need to fix the process_man_pages.py file to correctly check for the manpages directory to set up Retrieval Augmented Generation using ChromaDB.

---




---

## License

See repository for licensing details.
