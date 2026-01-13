#!/bin/bash

# Backup script for Hyprland, Omarchy, and installed packages
# Author: nightdevil00
# Date: $(date +%Y-%m-%d)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get timestamp for backup filename
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$HOME"
BACKUP_NAME="hypr_omarchy_backup_${TIMESTAMP}"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}.zip"

print_status "Starting backup process..."
print_status "Backup will be saved to: ${BACKUP_PATH}"

# Create temporary directory for backup
TEMP_DIR=$(mktemp -d)
print_status "Created temporary directory: ${TEMP_DIR}"

# Function to backup directory if it exists
backup_dir() {
    local src="$1"
    local dest="$2"
    local dir_name="$3"
    
    if [ -d "$src" ]; then
        print_status "Backing up ${dir_name}..."
        mkdir -p "$(dirname "$dest")"
        cp -r "$src" "$dest"
        print_status "✓ ${dir_name} backed up"
    else
        print_warning "${dir_name} not found at ${src}, skipping..."
    fi
}

# Function to backup file if it exists
backup_file() {
    local src="$1"
    local dest="$2"
    local file_name="$3"
    
    if [ -f "$src" ]; then
        print_status "Backing up ${file_name}..."
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
        print_status "✓ ${file_name} backed up"
    else
        print_warning "${file_name} not found at ${src}, skipping..."
    fi
}

# Backup Hyprland configuration
backup_dir "$HOME/.config/hypr" "${TEMP_DIR}/config/hypr" "Hyprland configuration"

# Backup Waybar configuration
backup_dir "$HOME/.config/waybar" "${TEMP_DIR}/config/waybar" "Waybar configuration"

# Backup Omarchy data
backup_dir "$HOME/.local/share/omarchy" "${TEMP_DIR}/local_share/omarchy" "Omarchy data"

# Backup installed packages (official packages)
print_status "Backing up official packages (pacman)..."
pacman -Qqe > "${TEMP_DIR}/official_packages.txt" 2>/dev/null || print_warning "Failed to get official packages list"
print_status "✓ Official packages list saved"

# Backup AUR packages
print_status "Backing up AUR packages..."
if command -v yay &> /dev/null; then
    yay -Qqm > "${TEMP_DIR}/aur_packages.txt" 2>/dev/null || print_warning "Failed to get AUR packages list"
    print_status "✓ AUR packages list saved"
else
    print_warning "yay not found, skipping AUR packages backup"
fi

# Backup flatpak packages if installed
if command -v flatpak &> /dev/null; then
    print_status "Backing up Flatpak packages..."
    flatpak list --app --columns=application > "${TEMP_DIR}/flatpak_packages.txt" 2>/dev/null || print_warning "Failed to get Flatpak packages list"
    print_status "✓ Flatpak packages list saved"
fi

# Create restore script
print_status "Creating restore script..."
cat > "${TEMP_DIR}/restore.sh" << 'EOF'
#!/bin/bash

# Restore script for Hyprland, Omarchy, and packages
# This script restores your backup to their correct locations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR"

print_status "Starting restore process from: ${BACKUP_DIR}"
print_status "This will restore your Hyprland config, Omarchy data, and install packages"
echo

# Ask for confirmation
read -p "Do you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "Restore cancelled."
    exit 0
fi

# Function to backup existing files
backup_existing() {
    local src="$1"
    local backup_suffix=".backup_$(date +%Y%m%d_%H%M%S)"
    
    if [ -e "$src" ]; then
        print_status "Backing up existing ${src} to ${src}${backup_suffix}"
        mv "$src" "${src}${backup_suffix}"
    fi
}

# Step 1: Restore official packages
print_step "Step 1: Restoring official packages..."
if [ -f "${BACKUP_DIR}/official_packages.txt" ]; then
    print_status "Installing official packages..."
    sudo pacman -S --needed - < "${BACKUP_DIR}/official_packages.txt"
    print_status "✓ Official packages installed"
else
    print_warning "No official packages list found"
fi

echo

# Step 2: Restore AUR packages using yay
print_step "Step 2: Restoring AUR packages..."
if [ -f "${BACKUP_DIR}/aur_packages.txt" ]; then
    if command -v yay &> /dev/null; then
        print_status "Installing AUR packages..."
        yay -S --needed - < "${BACKUP_DIR}/aur_packages.txt"
        print_status "✓ AUR packages installed"
    else
        print_warning "yay not found. Please install yay first: sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si"
    fi
else
    print_warning "No AUR packages list found"
fi

echo

# Step 3: Restore Flatpak packages
print_step "Step 3: Restoring Flatpak packages..."
if [ -f "${BACKUP_DIR}/flatpak_packages.txt" ]; then
    if command -v flatpak &> /dev/null; then
        print_status "Installing Flatpak packages..."
        while IFS= read -r package; do
            if [ ! -z "$package" ]; then
                flatpak install -y "$package"
            fi
        done < "${BACKUP_DIR}/flatpak_packages.txt"
        print_status "✓ Flatpak packages installed"
    else
        print_warning "flatpak not found, skipping Flatpak packages"
    fi
else
    print_warning "No Flatpak packages list found"
fi

echo

# Step 4: Restore Hyprland configuration
print_step "Step 4: Restoring Hyprland configuration..."
if [ -d "${BACKUP_DIR}/config/hypr" ]; then
    backup_existing "$HOME/.config/hypr"
    print_status "Restoring Hyprland configuration to ~/.config/hypr"
    mkdir -p "$HOME/.config"
    cp -r "${BACKUP_DIR}/config/hypr" "$HOME/.config/"
    print_status "✓ Hyprland configuration restored"
else
    print_warning "No Hyprland configuration found in backup"
fi

echo

# Step 5: Restore Waybar configuration
print_step "Step 5: Restoring Waybar configuration..."
if [ -d "${BACKUP_DIR}/config/waybar" ]; then
    backup_existing "$HOME/.config/waybar"
    print_status "Restoring Waybar configuration to ~/.config/waybar"
    mkdir -p "$HOME/.config"
    cp -r "${BACKUP_DIR}/config/waybar" "$HOME/.config/"
    print_status "✓ Waybar configuration restored"
else
    print_warning "No Waybar configuration found in backup"
fi

echo

# Step 6: Restore Omarchy data
print_step "Step 6: Restoring Omarchy data..."
if [ -d "${BACKUP_DIR}/local_share/omarchy" ]; then
    backup_existing "$HOME/.local/share/omarchy"
    print_status "Restoring Omarchy data to ~/.local/share/omarchy"
    mkdir -p "$HOME/.local/share"
    cp -r "${BACKUP_DIR}/local_share/omarchy" "$HOME/.local/share/"
    print_status "✓ Omarchy data restored"
else
    print_warning "No Omarchy data found in backup"
fi

echo

# Step 7: Set permissions
print_step "Step 7: Setting permissions..."
if [ -d "$HOME/.config/hypr" ]; then
    chmod -R 755 "$HOME/.config/hypr"
fi
if [ -d "$HOME/.config/waybar" ]; then
    chmod -R 755 "$HOME/.config/waybar"
fi
if [ -d "$HOME/.local/share/omarchy" ]; then
    chmod -R 755 "$HOME/.local/share/omarchy"
fi
print_status "✓ Permissions set"

echo

print_status "Restore completed successfully!"
print_status "You may need to restart Hyprland or relogin for all changes to take effect."

# Optional: Ask about restarting
read -p "Do you want to restart Hyprland now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Restarting Hyprland..."
    hyprctl reload 2>/dev/null || print_warning "Could not restart Hyprland automatically"
fi

EOF

# Make restore script executable
chmod +x "${TEMP_DIR}/restore.sh"

# Create README file
print_status "Creating README file..."
cat > "${TEMP_DIR}/README.md" << EOF
# Hyprland & Omarchy Backup

## Created on
$(date)

## Contents
- \`config/hypr/\` - Hyprland configuration files
- \`config/waybar/\` - Waybar configuration files
- \`local_share/omarchy/\` - Omarchy application data
- \`official_packages.txt\` - List of official Arch packages
- \`aur_packages.txt\` - List of AUR packages (if yay was available)
- \`flatpak_packages.txt\` - List of Flatpak applications (if installed)
- \`restore.sh\` - Script to restore everything

## How to restore
1. Extract this backup: \`unzip backup.zip\`
2. Navigate to the extracted folder: \`cd hypr_omarchy_backup_*\`
3. Run the restore script: \`./restore.sh\`
4. Follow the prompts

## Manual restore
If you prefer manual restoration:
- Copy \`config/hypr\` to \`~/.config/hypr\`
- Copy \`config/waybar\` to \`~/.config/waybar\`
- Copy \`local_share/omarchy\` to \`~/.local/share/omarchy\`
- Install packages using the provided lists:
  - Official: \`sudo pacman -S --needed - < official_packages.txt\`
  - AUR: \`yay -S --needed - < aur_packages.txt\`
  - Flatpak: \`flatpak install -y < flatpak_packages.txt\`

## Notes
- Existing files will be backed up with a .backup_* suffix
- The restore script requires sudo for package installation
- You may need to relogin or restart Hyprland after restoration
EOF

# Create the zip archive
print_status "Creating zip archive..."
cd "$TEMP_DIR"
zip -r "${BACKUP_PATH}" . > /dev/null

# Cleanup temporary directory
print_status "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

# Get final file size
FILE_SIZE=$(du -h "${BACKUP_PATH}" | cut -f1)

echo
print_status "✓ Backup completed successfully!"
print_status "Backup file: ${BACKUP_PATH}"
print_status "File size: ${FILE_SIZE}"
echo
print_status "To restore, extract the zip and run:"
echo "  cd $(dirname "${BACKUP_PATH}")"
echo "  unzip $(basename "${BACKUP_PATH}")"
echo "  cd ${BACKUP_NAME}"
echo "  ./restore.sh"
echo
