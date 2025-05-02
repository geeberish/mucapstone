#!/bin/bash

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
