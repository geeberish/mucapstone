#!/bin/bash

# =========================================== WyrmTerm ========================================== #
#
# Script Name:  WyrmTermClient
# Description:  Configures and launches a terminal emulator service on an RFCOMM serial port,
#               enabling Bluetooth-based remote terminal access to the target device. The RFCOMM
#               device is bound to the system's Bluetooth adapter and a paired remote client. Run
#               'WyrmTermTarget' on the target device before executing this script on the client.
# Author:       Richard "RogueFlotilla" Flores
# Created:      2025-04-17
# Modified:     2025-05-02
# Version:      dev-2025-05-02
# Usage:        sudo ./WyrmTermClient
# Dependencies: bluetooth, bluez, coreutils, screen
# Tested on:    Debian 12.10, BlueZ 5.66, Bash 5.2.15-2+b7, Screen 4.9.0-4
# License:      Custom Academic License – for academic, non-commercial use only. See LICENSE.
# Notes:        Developed while attending Marymount University, CAE-CD, Arlington, VA, for the
#               class IT 489 Capstone Project. Project title: Offline AI Reconnaissance and
#               Hacking Tool. Team Members: Richard Flores, Natasha Menon, and Charles "Matt" Penn.
#
# =============================================================================================== #

# ------------------------------------------ VARIABLES ------------------------------------------ #
# Configure variables here for setup
targetMAC="2C:CF:67:9D:BA:66" # MAC address of the Linux device being connected to
# Matt's Pi: "2C:CF:67:70:A6:5F" {OR} Richard's Pi: "2C:CF:67:9D:BA:66"
BThci="hci0" # Host Controller Interface of the Bluetooth adapter. TIP: command "hciconfig -a".
BTchannel="30" # The Bluetooth channel (0-39) to use for the connection. Must match target.
RFcomm="rfcomm42" # The virtual serial port created for the Bluetooth connection
# ----------------------------------------------------------------------------------------------- #

## INSTALL DEPENDENCIES
apt update
apt install bluetooth bluez coreutils screen

## ENSURE BLUETOOTH IS ON, ENABLED, AND CONFIGURED
systemctl enable bluetooth
systemctl start bluetooth
bluetoothctl -- power on
bluetoothctl -- default-agent
bluetoothctl -- agent on
bluetoothctl -- pairable on

## ATTEMPT TO RELEASE PREVIOUS RFCOMM BIND
rfcomm release $RFcomm

## BIND BLUETOOTH SERIAL CONNECTION TO SCREEN FOR TERMINAL LOGIN
rfcomm -i $BThci -S bind /dev/$RFcomm $targetMAC $BTchannel

## CREATE RULE TO ENSURE CONNECTION IS NOT TREATED AS A MODEM (sends unsolicited ATs)
mkdir -p /etc/udev/rules.d
touch /etc/udev/rules.d/99-rfcomm-ignore.rules
grep -qxF 'SUBSYSTEM=="tty", KERNEL=="'$RFcomm'", ENV{ID_MM_DEVICE_IGNORE}="1"' \
/etc/udev/rules.d/99-rfcomm-ignore.rules || \
echo 'SUBSYSTEM=="tty", KERNEL=="'$RFcomm'", ENV{ID_MM_DEVICE_IGNORE}="1"' | \
tee -a /etc/udev/rules.d/99-rfcomm-ignore.rules
udevadm control --reload-rules
udevadm trigger
systemctl restart ModemManager

## INITIATE REMOTE CONNECTION TO TARGET OVER BLUETOOTH SERIAL CONNECTION
screen /dev/$RFcomm

## RELEASE RFCOMM BIND AFTER DISCONNECTING
rfcomm release $RFcomm
