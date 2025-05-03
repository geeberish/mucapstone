#!/bin/bash

# =========================================== WyrmAI ========================================== #
#
# Script Name:  pull_manpages.sh
# Description:  This bash script automates the extraction of man pages, or if no man page is 
#               available then the help output for a list of our chosen tools. After it checks
#               for a man page or help output, it saves the output of each tool into individual
#               text files in the manpages directory.
# Author:       Matt Penn
# Created:      2025-04-17
# Modified:     2025-05-02
# Version:      dev-2025-05-02
# Usage:        ./pull_manpages.sh
# Dependencies: N/A
# Tested on:    Raspberry Pi 5, Ubuntu Server 25.04
# License:      Custom Academic License – for academic, non-commercial use only. See LICENSE.
# Notes:        Developed while attending Marymount University, CAE-CD, Arlington, VA, for the
#               class IT 489 Capstone Project. Project title: Offline AI Reconnaissance and
#               Hacking Tool. Team Members: Richard Flores, Natasha Menon, and Charles "Matt" Penn.
#
# =============================================================================================== #


mkdir -p manpages

# Function to get man/help output
fetch_doc() {
    tool_name=$1
    output_file="manpages/${tool_name}.txt"

    echo "[*] Processing $tool_name..."

    if ! command -v "$tool_name" &> /dev/null; then
        echo "[!] $tool_name not found in PATH" | tee "$output_file"
        return
    fi

    # Try man page
    if man "$tool_name" &> /dev/null; then
        echo "[+] Found man page for $tool_name"
        man "$tool_name" > "$output_file"
    # Try --help
    elif "$tool_name" --help &> /dev/null; then
        echo "[+] Found --help for $tool_name"
        "$tool_name" --help > "$output_file" 2>&1
    # Try -h
    elif "$tool_name" -h &> /dev/null; then
        echo "[+] Found -h for $tool_name"
        "$tool_name" -h > "$output_file" 2>&1
    else
        echo "[!] No documentation found for $tool_name" | tee "$output_file"
    fi
}

# List of tools (all included now)
declare -A tools=(
    [wireshark]="wireshark"
    [networkminer]="networkminer"
    [searchsploit]="searchsploit"
    [arp-scan]="arp-scan"
    [nmap]="nmap"
    [sqlmap]="sqlmap"
    [openvas]="openvas"
    [setoolkit]="setoolkit"
    [aircrack-ng]="aircrack-ng"
    [bloodhound]="bloodhound"
    [scapy]="scapy"
    [snaffler]="snaffler"
    [hashcat]="hashcat"
    [johntheripper]="john"
    [responder]="responder"
    [hydra]="hydra"
    [msfvenom]="msfvenom"
    [veil]="veil"
    [scarecrow]="scarecrow"
    [freeze]="freeze"
    [metasploit]="msfconsole"
    [netcat]="nc"
)

# Loop through tools and fetch docs
for tool in "${!tools[@]}"; do
    fetch_doc "${tools[$tool]}"
done

echo "[✓] Documentation extraction complete. Check the 'manpages' folder."
