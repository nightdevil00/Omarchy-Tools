#!/bin/bash

# This script removes transparency settings from your Hyprland configuration.

# Note: This script is based on the file structure and content as of 2025-09-30.
# If the configuration files change, this script may need to be updated.

# Theme file
THEME_FILE="$HOME/.config/omarchy/current/theme/hyprland.conf"
if [ -f "$THEME_FILE" ]; then
    sed -i 's/col.active_border = rgba(ADADADee) rgba(CECECEee) 45deg/col.active_border = rgb(ADADAD) rgb(CECECE) 45deg/' "$THEME_FILE"
    sed -i 's/col.inactive_border = rgba(00000088)/col.inactive_border = rgb(000000)/' "$THEME_FILE"
fi

# Windows file
WINDOWS_FILE="$HOME/.local/share/omarchy/default/hypr/windows.conf"
if [ -f "$WINDOWS_FILE" ]; then
    sed -i 's/windowrule = opacity 0.97 0.9, class:.*/windowrule = opacity 1.0 1.0, class:.*/' "$WINDOWS_FILE"
fi

# Look and feel file
LOOKNFEEL_FILE="$HOME/.local/share/omarchy/default/hypr/looknfeel.conf"
if [ -f "$LOOKNFEEL_FILE" ]; then
    sed -i 's/col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg/col.active_border = rgb(33ccff) rgb(00ff99) 45deg/' "$LOOKNFEEL_FILE"
    sed -i 's/col.inactive_border = rgba(595959aa)/col.inactive_border = rgb(595959)/' "$LOOKNFEEL_FILE"
    sed -i 's/color = rgba(1a1a1aee)/color = rgb(1a1a1a)/' "$LOOKNFEEL_FILE"
    sed -i 's/enabled = true/enabled = false/' "$LOOKNFEEL_FILE"
fi

# Browser apps file
BROWSER_FILE="$HOME/.local/share/omarchy/default/hypr/apps/browser.conf"
if [ -f "$BROWSER_FILE" ]; then
    sed -i 's/windowrule = opacity 1 0.97, tag:chromium-based-browser/windowrule = opacity 1 1, tag:chromium-based-browser/' "$BROWSER_FILE"
    sed -i 's/windowrule = opacity 1 0.97, tag:firefox-based-browser/windowrule = opacity 1 1, tag:firefox-based-browser/' "$BROWSER_FILE"
fi

echo "Transparency removal script finished."
