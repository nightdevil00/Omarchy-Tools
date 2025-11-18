#!/bin/bash

# This script enables or disables autologin for sddm by modifying the
# /etc/pam.d/sddm-autologin file.

# Check if the user is root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# Check the current status of autologin
if grep -q "^#auth" /etc/pam.d/sddm-autologin; then
  echo "Autologin is currently disabled."
  echo "To enable it, run this script with the --enable flag."
else
  echo "Autologin is currently enabled."
  echo "To disable it, run this script with the --disable flag."
fi

# Enable autologin
if [ "$1" == "--enable" ]; then
  sed -i 's/^#auth/auth/' /etc/pam.d/sddm-autologin
  echo "Autologin has been enabled."
fi

# Disable autologin
if [ "$1" == "--disable" ]; then
  sed -i 's/^auth/#auth/' /etc/pam.d/sddm-autologin
  echo "Autologin has been disabled."
fi
