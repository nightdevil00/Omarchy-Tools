#!/bin/bash

# This script adjusts screen brightness and improves font rendering on Arch Linux.

# --- Brightness ---
# Set screen brightness to 1.2 (software adjustment)
xrandr --output eDP-1 --brightness 1.2

# --- Font Rendering ---
# Install noto-fonts (if not already installed)
yay -S --noconfirm noto-fonts

# Enable slight hinting and sub-pixel rendering
sudo ln -sf /usr/share/fontconfig/conf.avail/10-hinting-slight.conf /etc/fonts/conf.d/
sudo ln -sf /usr/share/fontconfig/conf.avail/10-sub-pixel-rgb.conf /etc/fonts/conf.d/

# Rebuild the font cache
fc-cache -fv

echo "Brightness and font settings applied."
echo "Note: Brightness setting is temporary and will be reset on reboot."
echo "To make the brightness setting permanent, you can add the xrandr command to your .xinitrc or desktop environment's startup applications."
