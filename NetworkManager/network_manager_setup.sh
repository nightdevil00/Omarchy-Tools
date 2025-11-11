#!/bin/bash

# This script automates the process of switching from iwd to NetworkManager,
# as described in the README.md file. It also includes a VPN selection menu.

# Function to print messages
print_message() {
    echo "--------------------------------------------------"
    echo "$1"
    echo "--------------------------------------------------"
}

# Step 1: Install NetworkManager and required packages
print_message "Installing NetworkManager, wpa_supplicant, and OpenVPN..."
sudo pacman -S --noconfirm networkmanager wpa_supplicant network-manager-applet nm-connection-editor openvpn

# Step 2: Stop and mask iwd and systemd-networkd
print_message "Stopping and masking iwd and systemd-networkd..."
sudo systemctl stop iwd systemd-networkd
sudo systemctl mask iwd systemd-networkd

# Step 3: Enable and start NetworkManager
print_message "Enabling and starting NetworkManager..."
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager

# Step 4: Configure Waybar to use nm-applet
WAYBAR_CONFIG="$HOME/.config/waybar/config.jsonc"
if [ -f "$WAYBAR_CONFIG" ]; then
    print_message "Configuring Waybar to use nm-applet..."
    sed -i 's/"on-click": "omarchy-launch-wifi"/"on-click": "nm-applet --indicator"/' "$WAYBAR_CONFIG"
else
    print_message "Waybar config not found at $WAYBAR_CONFIG. Skipping this step."
fi

# Step 5: VPN Selection
print_message "VPN Setup"
PS3="Choose a VPN to configure (or 'q' to quit): "
vpn_options=("ProtonVPN" "NordVPN" "Mullvad" "Quit")
select opt in "${vpn_options[@]}"; do
    case $opt in
        "ProtonVPN")
            echo "Configuring ProtonVPN..."
            # Add ProtonVPN configuration commands here
            # For example:
            # sudo openvpn --config /path/to/protonvpn.ovpn
            break
            ;;
        "NordVPN")
            echo "Configuring NordVPN..."
            # Add NordVPN configuration commands here
            break
            ;;
        "Mullvad")
            echo "Configuring Mullvad..."
            # Add Mullvad configuration commands here
            break
            ;;
        "Quit")
            break
            ;;
        *) echo "Invalid option $REPLY";;
    esac
done

# Step 6: Reload Waybar
print_message "Reloading Waybar..."
killall waybar
waybar &

# Final instructions
print_message "Setup complete!"
echo "You can now connect to a regular or 802.1X WiFi network using the nm-applet in your system tray."
echo "A reboot is recommended to ensure all changes take effect properly."
read -p "Reboot now? (y/n): " reboot_choice
if [[ "$reboot_choice" == "y" || "$reboot_choice" == "Y" ]]; then
    sudo reboot
fi
