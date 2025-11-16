#!/bin/bash
set -e

# This script automates the process of updating the system while temporarily disabling the [omarchy] repository.

# Comment out the [omarchy] repository in /etc/pacman.conf
echo "Commenting out [omarchy] repository..."
sudo sed -i '/^\[omarchy\]$/,/^Server/s/^/#/' /etc/pacman.conf

# Update the system
echo "Updating system packages with pacman..."
sudo pacman -Syu --noconfirm

echo "Updating AUR packages with yay..."
yay -Syu --noconfirm

# Uncomment the [omarchy] repository in /etc/pacman.conf
echo "Uncommenting [omarchy] repository..."
sudo sed -i '/^#\[omarchy\]$/,/^#Server/s/^#//' /etc/pacman.conf

echo "System update complete!"
