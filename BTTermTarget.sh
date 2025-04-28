#!/bin/bash

## PROJECT INFORMATION:
# Project Title: Offline AI Reconnaissance and Hacking Tool
# Team Members: Richard Flores, Natasha Menon, and Matt Penn
# Class: IT 489 Capstone Project
# Submission Date: May 1, 2025

## DESCRIPTION:
# This code creates a terminal emulator connection on a remote host for a client device, such as a 
# tablet or another computer, to connect to it over a serial bluetooth connection using Getty 
# authentication. This script is to be run on the target device being connected to.

## NOTES:
# This script should be run with elevated privilleges (sudo). It was created by automating a 
# tutorial by "Yes, I know IT !" YouTube video tutorial on 'How to open a Linux Session over 
# Bluetooth ? Yes, I Know IT ! Ep 26' - https://www.youtube.com/watch?v=7xBSgb1GwCw with some 
# additional customizations and configurations.

## KNOWN BUGS:
# There is a known bug with this connection where a set of AT's are sent to the longin after 
# initial connection is made. This is due to the connection being treated as a modem connection, 
# and not a serial connection. No solution has been identified at this time. It is possible to wait 
# for a set of three "AT" login attempts before logging into the target device.

# ------------------------- VARIABLES ------------------------- #
# Configure variables here for setup
clientMAC = A8:CA:77:05:42:C1
# ------------------------------------------------------------- #

## UPDATE APT CACHE AND UPGRADE INSTALLATION
sudo apt update
# sudo apt upgrade -y

## INSTALL BLUETOOTH PACKAGE IN ORDER TO GET DEFAULT SERVICE FILE
sudo apt install core-utils bluetooth getty

## DISABLE DEFAULT BLUETOOTH SERVICE
sudo systemctl stop bluetooth
sudo systemctl disable bluetooth

## CREATE A NEW BLUETOOTH SERVICE BASED OFF DEFAULT ONE
sudo cp /lib/systemd/system/bluetooth.service /etc/systemd/system/

## CUSTOMIZE NEW BLUETOOTH SERVICE
# Run in compatibility mode
sudo sed -i "/ExecStart=/s/$/ --compat/" \
/etc/systemd/system/bluetooth.service

# enable page and inquiry scan
grep -qxF "ExecStartPost=/bin/hciconfig hci0 piscan" /etc/systemd/system/bluetooth.service || \
sudo sed -i "/ExecStart=/a \\
ExecStartPost=/bin/hciconfig hci0 piscan" \
/etc/systemd/system/bluetooth.service

# Power-up the first bluetooth controller
grep -qxF "ExecStartPost=/bin/hciconfig hci0 up" /etc/systemd/system/bluetooth.service || \
sudo sed -i "/ExecStart=/a \\
ExecStartPost=/bin/hciconfig hci0 up" \
/etc/systemd/system/bluetooth.service

# Advertise the port 22 of the bluetooth device as being a virtual serial port
grep -qxF "ExecStartPost=/usr/bin/sdptool add --channel=22 SP" /etc/systemd/system/bluetooth.service || \
sudo sed -i "/ExecStart=/a \\
ExecStartPost=/usr/bin/sdptool add --channel=22 SP" \
/etc/systemd/system/bluetooth.service

## CREATE SYMBOLIC LINKS TO NEW BLUETOOTH SERVICE FILE CREATED
sudo systemctl daemon-reload
sudo systemctl enable /etc/systemd/system/bluetooth.service

## START BLUETOOTH SERVICE
sudo systemctl start bluetooth.service

## BIND BLUETOOTH SERIAL CONNECTION TO GETTY FOR TERMINAL LOGIN
# sudo /usr/bin/rfcomm watch hci0 22 getty rfcomm0 115200 vt100

## CREATE BLUETOOTH LOGIN SERVICE THAT STARTS AT BOOT
# Create file
sudo touch /etc/systemd/system/btlogin.service

# Write to file
cat <<EOF | sudo tee /etc/systemd/system/btlogin.service > /dev/null
[Unit]
Description=Remote login over Bluetooth serial connection with Getty authentication
After=bluetooth.service
Requires=bluetooth.service

[Service]
ExecStart=/usr/bin/rfcomm watch hci0 22 setsid getty rfcomm0 115200 vt100

[Install]
WantedBy=multi-user.target
EOF

## ENABLE AND START LOGIN SERVICE
sudo systemctl daemon-reload
sudo systemctl enable btlogin
sudo systemctl start btlogin
sudo systemctl --lines 0 --no-pager status btlogin
