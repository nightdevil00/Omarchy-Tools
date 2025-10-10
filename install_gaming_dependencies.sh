#!/bin/bash

# This script installs the gaming dependencies listed in list.txt

# Read the packages from list.txt into an array
mapfile -t packages < list.txt

# Install the packages using yay
yay -S --needed --noconfirm "${packages[@]}"
