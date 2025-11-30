#!/bin/bash

# Script to mount or unmount iPhone, with dependency checking and user guidance.

MOUNT_POINT="$HOME/iphone"

# --- Dependency Checking ---
check_dependencies() {
    local missing_deps=()
    for cmd in ifuse usbmuxd; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "The following dependencies are missing: ${missing_deps[*]}. This script requires them to function."
        read -p "Would you like to install them now using pacman? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo pacman -S --noconfirm usbmuxd ifuse libimobiledevice
        else
            echo "Installation cancelled. Please install dependencies manually to use this script."
            exit 1
        fi
    fi
}

# --- Main Logic ---
main() {
    # Check if the mount point exists, if not create it
    if [ ! -d "$MOUNT_POINT" ]; then
        echo "Creating mount point at $MOUNT_POINT."
        mkdir -p "$MOUNT_POINT"
    fi

    if [ "$1" == "unmount" ]; then
        if mountpoint -q "$MOUNT_POINT"; then
            echo "Unmounting iPhone from $MOUNT_POINT..."
            fusermount -u "$MOUNT_POINT"
            echo "iPhone unmounted successfully."
        else
            echo "iPhone is not currently mounted at $MOUNT_POINT."
        fi
    else
        if mountpoint -q "$MOUNT_POINT"; then
            echo "iPhone is already mounted at $MOUNT_POINT."
        else
            echo "--- Mounting iPhone ---"
            echo "Please connect your iPhone to your computer via USB."
            echo "On your iPhone, you should see a 'Trust This Computer' prompt. Please tap 'Trust' and enter your passcode if prompted."
            read -p "Press [Enter] after you have trusted this computer..."

            echo "Attempting to mount iPhone to $MOUNT_POINT..."
            ifuse "$MOUNT_POINT"
            
            if mountpoint -q "$MOUNT_POINT"; then
                echo "iPhone mounted successfully."
                echo "You can now access its files in Nautilus at: $MOUNT_POINT"
            else
                echo "------------------------------------------------------------------"
                echo "Mounting failed. Please try the following troubleshooting steps:"
                echo "1. Disconnect and reconnect your iPhone."
                echo "2. Make sure you tapped 'Trust' on the prompt."
                echo "3. Restart the usbmuxd service: sudo systemctl restart usbmuxd"
                echo "4. Try running the script again."
                echo "------------------------------------------------------------------"
            fi
        fi
    fi
}

# --- Script Execution ---
check_dependencies
main "$@"