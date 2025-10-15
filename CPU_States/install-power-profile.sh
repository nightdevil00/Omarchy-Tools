#!/bin/bash

# This script installs and enables a systemd service for a chosen power profile.

# Function to disable all power profile services
disable_all_services() {
    sudo systemctl disable power-profile-performance.service 2>/dev/null
    sudo systemctl disable power-profile-balanced.service 2>/dev/null
    sudo systemctl disable power-profile-power-saver.service 2>/dev/null
}

# Present the menu
echo "Choose a power profile to set as default:"
echo "1) Performance"
echo "2) Balanced"
echo "3) Power Saver"
read -p "Enter your choice [1-3]: " choice

# Handle the choice
case $choice in
    1)
        echo "Setting power profile to Performance..."
        disable_all_services
        sudo mv $HOME/power-profile-performance.service /etc/systemd/system/
        sudo systemctl enable power-profile-performance.service
        ;;
    2)
        echo "Setting power profile to Balanced..."
        disable_all_services
        sudo mv $HOME/power-profile-balanced.service /etc/systemd/system/
        sudo systemctl enable power-profile-balanced.service
        ;;
    3)
        echo "Setting power profile to Power Saver..."
        disable_all_services
        sudo mv $HOME/power-profile-power-saver.service /etc/systemd/system/
        sudo systemctl enable power-profile-power-saver.service
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo "Done."
