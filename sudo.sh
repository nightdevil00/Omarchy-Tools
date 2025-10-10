#!/bin/bash

# Backup the sudoers file before making changes
echo "Backing up the sudoers file..."
sudo cp /etc/sudoers /etc/sudoers.bak

# Add the entry for the current user to allow passwordless sudo access to 'pacman'
echo "Modifying sudoers file to allow '$USER' to run commands without password..."

# Check if the line already exists to prevent duplicates
if ! sudo grep -q "$USER ALL=(ALL) NOPASSWD: /usr/bin/pacman" /etc/sudoers; then
    echo "'$USER' to sudoers with passwordless access to pacman"
    echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/pacman" | sudo tee -a /etc/sudoers > /dev/null
else
    echo "'$USER' is already configured for passwordless sudo access."


# Validate the sudoers file for syntax errors
echo "Validating sudoers file..."
sudo visudo -c

if [ $? -eq 0 ]; then
    echo "Sudoers file updated successfully."
else
    echo "Error: Sudoers file has syntax issues. Restoring the backup..."
    sudo cp /etc/sudoers.bak /etc/sudoers
    echo "Restoration complete. Please fix the syntax manually."
fi

