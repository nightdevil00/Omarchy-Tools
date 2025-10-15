#!/bin/bash

# Disable docker.service
sudo systemctl disable docker.service

# Disable systemd-binfmt.service
sudo systemctl disable systemd-binfmt.service

echo "docker.service and systemd-binfmt.service have been disabled."