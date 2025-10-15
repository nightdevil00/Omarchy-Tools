#!/bin/bash

# Move the service file to the systemd directory
sudo mv /home/mihai/walker-shutdown.service /etc/systemd/system/

# Reload the systemd daemon
sudo systemctl daemon-reload

# Enable the service
sudo systemctl enable walker-shutdown.service

echo "Walker shutdown service installed and enabled."