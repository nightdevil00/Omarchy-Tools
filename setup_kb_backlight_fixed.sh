#!/bin/bash

# This script sets up and manages the keyboard backlight using a systemd service.

# Exit on error
set -e

# --- Variables ---

BACKLIGHT_PATH=""

# --- Functions ---

# Check if running as root
check_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please use sudo." >&2
    exit 1
  fi
}

# Find the correct backlight path
find_backlight_path() {
  if [ -e "/sys/class/leds/smc::kbd_backlight/brightness" ]; then
    BACKLIGHT_PATH="/sys/class/leds/smc::kbd_backlight/brightness"
  elif [ -e "/sys/class/leds/platform::kbd_backlight/brightness" ]; then
    BACKLIGHT_PATH="/sys/class/leds/platform::kbd_backlight/brightness"
  else
    echo "Error: Keyboard backlight device not found." >&2
    echo "Please ensure your hardware is supported and the necessary kernel modules are loaded." >&2
    exit 1
  fi
}

# Install the keyboard backlight service
install_service() {
  check_root
  find_backlight_path

  echo "Backlight device found at $BACKLIGHT_PATH. Creating systemd service..."

  # Define the service file path
  SERVICE_FILE="/etc/systemd/system/kb-backlight.service"

  # Create the systemd service file
  cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Keyboard backlight control

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo 100 > $BACKLIGHT_PATH'

[Install]
WantedBy=multi-user.target
EOF

  echo "Reloading systemd daemon..."
  systemctl daemon-reload

  echo "Enabling the keyboard backlight service to start on boot..."
  systemctl enable kb-backlight.service

  echo "Starting the keyboard backlight service..."
  systemctl start kb-backlight.service

  echo "Done. The keyboard backlight should now be on."
  echo "The service is enabled and will start automatically on future boots."
}

# Turn the keyboard backlight on
turn_on_service() {
  check_root
  echo "Turning the keyboard backlight on..."
  systemctl start kb-backlight.service
  echo "Done."
}

# Turn the keyboard backlight off
turn_off_backlight() {
  check_root
  find_backlight_path
  echo "Turning the keyboard backlight off..."
  echo 0 > "$BACKLIGHT_PATH"
  echo "Done."
}

# Turn the keyboard backlight service off and turn off the backlight
turn_off_service() {
  check_root
  echo "Stopping the keyboard backlight service..."
  systemctl stop kb-backlight.service
  turn_off_backlight
  echo "Done."
}

# --- Main Menu ---

main_menu() {
  while true; do
    echo
    echo "Keyboard Backlight Service Manager"
    echo "----------------------------------"
    echo "1. Install and Start Service"
    echo "2. Turn On Backlight"
    echo "3. Turn Off Backlight"
    echo "4. Turn Off Service and Backlight"
    echo "5. Exit"
    echo

    read -p "Enter your choice [1-5]: " choice

    case $choice in
      1)
        install_service
        ;;
      2)
        turn_on_service
        ;;
      3)
        turn_off_backlight
        ;;
      4)
        turn_off_service
        ;;
      5)
        echo "Exiting."
        exit 0
        ;;
      *)
        echo "Invalid choice. Please enter a number between 1 and 5."
        ;;
    esac
  done
}

# --- Script Entry Point ---

main_menu
