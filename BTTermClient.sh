#!/bin/bash

## PROJECT INFORMATION:
# Project Title: Offline AI Reconnaissance and Hacking Tool
# Team Members: Richard Flores, Natasha Menon, and Matt Penn
# Class: IT 489 Capstone Project
# Submission Date: May 1, 2025

## DESCRIPTION:
# This code creates a terminal emulator connection on a remote host for a client device, such as a 
# tablet or another computer, to connect to it over a serial bluetooth connection using Getty 
# authentication. This script is to be run on the client device that is connecting to the traget.

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
targetMAC = 2C:CF:67:9D:BA:66
# ------------------------------------------------------------- #

## INSTALL DEPENDENCIES
sudo apt install core-utils bluetooth screen

## BIND BLUETOOTH SERIAL CONNECTION TO SCREEN FOR TERMINAL LOGIN
sudo rfcomm -i hci0 bind /dev/rfcomm0 $targetMAC 22

## INITIATE REMOTE CONNECTION TO TARGET OF BLUETOOTH SERIAL CONNECTION
sudo screen /dev/rfcomm0
