#!/bin/bash

# =========================================== WyrmTerm ========================================== #
#
# Script Name:  WyrmTermTarget
# Description:  Configures and starts a boot-time getty service on an RFCOMM serial port, enabling
#               Bluetooth-based remote terminal access to the target device. The RFCOMM device is
#               bound to the system's Bluetooth adapter and a paired remote client. Run
#               'WyrmTermClient' on the client device after executing this script on the target.
# Author:       Richard "RogueFlotilla" Flores
# Created:      2025-04-17
# Modified:     2025-05-02
# Version:      dev-2025-05-02
# Usage:        ./WyrmTermTarget
# Dependencies: bluetooth, bluez, coreutils
# Tested on:    Debian 12.10, BlueZ 5.66, Bash 5.2.15-2+b7
# License:      Custom Academic License – for academic, non-commercial use only. See LICENSE.
# Notes:        Developed while attending Marymount University, CAE-CD, Arlington, VA, for the
#               class IT 489 Capstone Project. Project title: Offline AI Reconnaissance and
#               Hacking Tool. Team Members: Richard Flores, Natasha Menon, and Charles "Matt" Penn.
#
# =============================================================================================== #

# ------------------------------------------ VARIABLES ------------------------------------------ #
# Configure variables here for setup
BThci="hci0" # Host Controller Interface of the Bluetooth adapter. TIP: command "hciconfig -a".
BTchannel="30" # The Bluetooth channel (0-39) to use for the connection. Must match client.
RFcomm="rfcomm24" # The virtual serial port created for the Bluetooth connection
# ----------------------------------------------------------------------------------------------- #

## INSTALL DEPENDENCIES
apt update
apt install bluetooth, bluez, coreutils

## DISABLE DEFAULT BLUETOOTH SERVICE
systemctl stop bluetooth
systemctl disable bluetooth

## CREATE A NEW BLUETOOTH SERVICE BASED OFF DEFAULT ONE
cp /lib/systemd/system/bluetooth.service /etc/systemd/system/

## CUSTOMIZE NEW BLUETOOTH SERVICE
# Run in compatibility mode
sed -i "/ExecStart=/s/$/ --compat/" \
/etc/systemd/system/bluetooth.service

# enable page and inquiry scan
grep -qxF 'ExecStartPost=/bin/hciconfig "'$BThci'" piscan' /etc/systemd/system/bluetooth.service || \
sed -i '/ExecStart=/a \\
ExecStartPost=/bin/hciconfig "'$BThci'" piscan' \
/etc/systemd/system/bluetooth.service

# Power-up the first bluetooth controller
grep -qxF 'ExecStartPost=/bin/hciconfig "'$BThci'" up' /etc/systemd/system/bluetooth.service || \
sed -i '/ExecStart=/a \\
ExecStartPost=/bin/hciconfig "'$BThci'" up' \
/etc/systemd/system/bluetooth.service

# Advertise the port 22 of the bluetooth device as being a virtual serial port
grep -qxF 'ExecStartPost=/usr/bin/sdptool add --channel="'$BTchannel'" SP' /etc/systemd/system/bluetooth.service || \
sed -i '/ExecStart=/a \\
ExecStartPost=/usr/bin/sdptool add --channel="'$BTchannel'" SP' \
/etc/systemd/system/bluetooth.service

## CREATE SYMBOLIC LINKS TO NEW BLUETOOTH SERVICE FILE CREATED
systemctl daemon-reload
systemctl enable /etc/systemd/system/bluetooth.service

## START BLUETOOTH SERVICE
systemctl start bluetooth.service

## BIND BLUETOOTH SERIAL CONNECTION TO GETTY FOR TERMINAL LOGIN
# Note: Can be used to create a single listener instance w/o creating boot-time service
# /usr/bin/rfcomm watch hci0 30 getty rfcomm0 115200 vt100

## CREATE BLUETOOTH LOGIN SERVICE THAT STARTS AT BOOT
# Note: Creates a listener that starts at each boot. No on device interaction needed after setup.
# Create file
touch /etc/systemd/system/btlogin.service

# Write to file
cat <<EOF | tee /etc/systemd/system/wyrmterm.service > /dev/null
[Unit]
Description=WyrmTerm - Remote terminal over Bluetooth serial connection with Getty
After=bluetooth.service
Requires=bluetooth.service

[Service]
ExecStart=/usr/bin/rfcomm watch ${BThci} ${BTchannel} setsid getty ${RFcomm} 115200 vt100
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

## ENABLE AND START LOGIN SERVICE
systemctl daemon-reload
systemctl enable wyrmterm
systemctl start wyrmterm
systemctl --lines 0 --no-pager status wyrmterm
