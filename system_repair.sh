#!/bin/bash

# System Repair Script for Arch Linux Live ISO
# Supports LUK2 encrypted systems with Btrfs subvolumes and various bootloaders

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
ENCRYPTED_PARTITION=""
CRYPT_NAME="cryptroot"
MOUNT_POINT="/mnt"
BOOTLOADER=""
FILESYSTEM=""
BTRFS_SUBVOLS=()

# Functions
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    cat << EOF
System Repair Script for Arch Linux Live ISO

Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -p, --partition PART    Specify encrypted partition (e.g., /dev/nvme0n1p3)
    -m, --mountpoint DIR    Mount point (default: /mnt)
    -c, --cryptname NAME    Name for encrypted device (default: cryptroot)
    -b, --bootloader TYPE   Bootloader type (grub/limine/systemd-boot)
    -f, --filesystem TYPE   Filesystem type (btrfs/ext4/xfs)
    --auto-detect           Auto-detect system configuration

EXAMPLES:
    $0 --auto-detect
    $0 -p /dev/nvme0n1p3 -b grub -f btrfs
    $0 --partition /dev/sda3 --bootloader limine --filesystem btrfs

EOF
}

check_dependencies() {
    print_status "Checking dependencies..."
    local deps=("cryptsetup" "lsblk" "blkid" "mount" "arch-chroot")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            print_error "Missing dependency: $dep"
            exit 1
        fi
    done
    print_success "All dependencies found"
}

detect_system() {
    print_status "Detecting system configuration..."
    
    # List available block devices
    print_status "Available block devices:"
    lsblk -f
    
    # Try to find encrypted partitions
    local encrypted_parts=()
    while IFS= read -r line; do
        if [[ $line == *"crypto_LUKS"* ]]; then
            encrypted_parts+=("$(echo "$line" | cut -d: -f1)")
        fi
    done < <(blkid)
    
    if [[ ${#encrypted_parts[@]} -eq 0 ]]; then
        print_error "No encrypted partitions found"
        return 1
    fi
    
    if [[ ${#encrypted_parts[@]} -eq 1 ]]; then
        ENCRYPTED_PARTITION="${encrypted_parts[0]}"
        print_success "Found encrypted partition: $ENCRYPTED_PARTITION"
    else
        print_status "Multiple encrypted partitions found:"
        for i in "${!encrypted_parts[@]}"; do
            echo "$((i+1)). ${encrypted_parts[i]}"
        done
        read -p "Select partition (1-${#encrypted_parts[@]}): " choice
        choice=$((choice-1))
        ENCRYPTED_PARTITION="${encrypted_parts[choice]}"
    fi
    
    # Detect filesystem by examining the partition
    local fs_type=$(blkid -o value -s TYPE "$ENCRYPTED_PARTITION" 2>/dev/null || echo "unknown")
    print_status "Detected filesystem type: $fs_type"
    
    case "$fs_type" in
        "crypto_LUKS")
            print_status "This is a LUKS encrypted partition"
            ;;
        *)
            print_warning "Unexpected filesystem type: $fs_type"
            ;;
    esac
    
    # Try to detect bootloader from mounted EFI partition if available
    print_status "Attempting to detect bootloader..."
}

unlock_encrypted_drive() {
    print_status "Unlocking encrypted drive: $ENCRYPTED_PARTITION"
    
    if [[ -e "/dev/mapper/$CRYPT_NAME" ]]; then
        print_warning "Device $CRYPT_NAME already exists, attempting to close first..."
        cryptsetup close "$CRYPT_NAME" || true
    fi
    
    # Try to unlock the encrypted partition
    if ! cryptsetup open "$ENCRYPTED_PARTITION" "$CRYPT_NAME"; then
        print_error "Failed to unlock encrypted partition"
        print_status "Please check:"
        echo "1. Correct partition path"
        echo "2. Encryption password"
        echo "3. Caps lock status"
        exit 1
    fi
    
    print_success "Successfully unlocked encrypted partition"
}

detect_filesystem() {
    print_status "Detecting filesystem on unlocked device..."
    
    # Try to determine filesystem type
    if blkid /dev/mapper/"$CRYPT_NAME" | grep -q "ext4"; then
        FILESYSTEM="ext4"
    elif blkid /dev/mapper/"$CRYPT_NAME" | grep -q "btrfs"; then
        FILESYSTEM="btrfs"
    elif blkid /dev/mapper/"$CRYPT_NAME" | grep -q "xfs"; then
        FILESYSTEM="xfs"
    else
        print_status "Unable to auto-detect filesystem. Please specify:"
        echo "1) ext4"
        echo "2) btrfs"
        echo "3) xfs"
        read -p "Choose filesystem [1-3]: " fs_choice
        case $fs_choice in
            1) FILESYSTEM="ext4" ;;
            2) FILESYSTEM="btrfs" ;;
            3) FILESYSTEM="xfs" ;;
            *) print_error "Invalid choice"; exit 1 ;;
        esac
    fi
    
    print_success "Detected filesystem: $FILESYSTEM"
}

mount_filesystem() {
    print_status "Mounting filesystem..."
    
    # Create mount point if it doesn't exist
    [[ ! -d "$MOUNT_POINT" ]] && mkdir -p "$MOUNT_POINT"
    
    case "$FILESYSTEM" in
        "btrfs")
            mount_btrfs_subvolumes
            ;;
        "ext4"|"xfs")
            print_status "Mounting $FILESYSTEM filesystem..."
            mount "/dev/mapper/$CRYPT_NAME" "$MOUNT_POINT"
            print_success "Mounted $FILESYSTEM filesystem"
            ;;
        *)
            print_error "Unsupported filesystem: $FILESYSTEM"
            exit 1
            ;;
    esac
}

mount_btrfs_subvolumes() {
    print_status "Scanning Btrfs subvolumes..."
    
    # Mount temporarily to scan subvolumes
    mount "/dev/mapper/$CRYPT_NAME" "$MOUNT_POINT"
    
    # List subvolumes
    print_status "Available Btrfs subvolumes:"
    btrfs subvolume list "$MOUNT_POINT" || print_warning "Could not list subvolumes"
    
    # Common subvolume patterns
    local common_subvols=("@" "@home" "@log" "@pkg" "@.snapshots" "@var" "@root")
    local found_subvols=()
    
    for subvol in "${common_subvols[@]}"; do
        if btrfs subvolume show "$MOUNT_POINT/$subvol" &>/dev/null; then
            found_subvols+=("$subvol")
        fi
    done
    
    # Unmount to remount with proper subvolumes
    umount "$MOUNT_POINT"
    
    if [[ ${#found_subvols[@]} -eq 0 ]]; then
        # No subvolumes found, mount as single volume
        mount "/dev/mapper/$CRYPT_NAME" "$MOUNT_POINT"
        print_warning "No subvolumes detected, mounting as single volume"
    else
        # Mount main subvolume (@) first
        if [[ " ${found_subvols[*]} " =~ " @ " ]]; then
            mount -o subvol=@ "/dev/mapper/$CRYPT_NAME" "$MOUNT_POINT"
            print_success "Mounted @ subvolume"
            
            # Mount other subvolumes
            for subvol in "${found_subvols[@]}"; do
                if [[ "$subvol" != "@" ]]; then
                    local mount_path=""
                    case "$subvol" in
                        "@home") mount_path="$MOUNT_POINT/home" ;;
                        "@log") mount_path="$MOUNT_POINT/var/log" ;;
                        "@pkg") mount_path="$MOUNT_POINT/var/cache/pacman/pkg" ;;
                        "@.snapshots") mount_path="$MOUNT_POINT/.snapshots" ;;
                        "@var") mount_path="$MOUNT_POINT/var" ;;
                        *) continue ;;
                    esac
                    
                    [[ ! -d "$mount_path" ]] && mkdir -p "$mount_path"
                    mount -o subvol="$subvol" "/dev/mapper/$CRYPT_NAME" "$mount_path"
                    print_success "Mounted $subvol to $mount_path"
                fi
            done
        else
            # Fallback to mounting first subvolume as root
            mount -o subvol="${found_subvols[0]}" "/dev/mapper/$CRYPT_NAME" "$MOUNT_POINT"
            print_success "Mounted ${found_subvols[0]} as root"
        fi
    fi
}

mount_boot_partitions() {
    print_status "Looking for boot partitions..."
    
    # Get base device name
    local base_device="${ENCRYPTED_PARTITION%p[0-9]*}"
    
    # Look for EFI partition
    local efi_part=""
    local boot_part=""
    
    for part in "${base_device}"*; do
        if [[ "$part" != "$ENCRYPTED_PARTITION" ]]; then
            local part_label=$(lsblk -no LABEL "$part" 2>/dev/null || echo "")
            local part_fstype=$(lsblk -no FSTYPE "$part" 2>/dev/null || echo "")
            
            case "$part_fstype" in
                "vfat")
                    if [[ "$part_label" == "EFI" ]] || [[ "$part" == *"p1" ]] || [[ "$part" == *"p2" ]]; then
                        efi_part="$part"
                    fi
                    ;;
                "ext2"|"ext3"|"ext4")
                    if [[ "$part_label" == "BOOT" ]] || [[ "$part" == *"p1" ]]; then
                        boot_part="$part"
                    fi
                    ;;
            esac
        fi
    done
    
    # Mount EFI partition
    if [[ -n "$efi_part" ]]; then
        [[ ! -d "$MOUNT_POINT/boot/efi" ]] && mkdir -p "$MOUNT_POINT/boot/efi"
        mount "$efi_part" "$MOUNT_POINT/boot/efi"
        print_success "Mounted EFI partition: $efi_part"
    fi
    
    # Mount boot partition
    if [[ -n "$boot_part" ]]; then
        [[ ! -d "$MOUNT_POINT/boot" ]] && mkdir -p "$MOUNT_POINT/boot"
        mount "$boot_part" "$MOUNT_POINT/boot"
        print_success "Mounted boot partition: $boot_part"
    fi
}

mount_virtual_filesystems() {
    print_status "Mounting virtual filesystems..."
    
    mount --bind /dev "$MOUNT_POINT/dev"
    mount --bind /proc "$MOUNT_POINT/proc"
    mount --bind /sys "$MOUNT_POINT/sys"
    mount --bind /run "$MOUNT_POINT/run"
    
    print_success "Mounted virtual filesystems"
}

enter_chroot() {
    print_status "Entering arch-chroot environment..."
    print_status "You can now perform system maintenance tasks."
    print_status "Common commands:"
    echo "  pacman -Syu                    # Update system"
    echo "  grub-install --recheck          # Reinstall GRUB"
    echo "  grub-mkconfig -o /boot/grub/grub.cfg"
    echo "  mkinitcpio -P                   # Regenerate initramfs"
    echo "  passwd username                 # Reset password"
    echo "  systemctl enable service        # Enable service"
    echo "  exit                            # Leave chroot"
    
    arch-chroot "$MOUNT_POINT"
}

cleanup_and_exit() {
    print_status "Cleaning up..."
    
    # Unmount everything
    umount -R "$MOUNT_POINT" 2>/dev/null || true
    
    # Close encrypted device
    if [[ -e "/dev/mapper/$CRYPT_NAME" ]]; then
        cryptsetup close "$CRYPT_NAME"
        print_success "Closed encrypted device"
    fi
    
    print_success "Cleanup completed"
}

interactive_menu() {
    while true; do
        clear
        cat << EOF
System Repair Menu
==================

1) Auto-detect and mount system
2) Manually specify partition
3) Mount boot partitions only
4) Enter chroot
5) Reinstall bootloader
6. Fix initramfs
7) Reset user password
8) Backup important files
9) Unmount and cleanup
10) Reboot system
0) Exit

EOF
        read -p "Select an option [0-10]: " choice
        
        case $choice in
            1)
                detect_system
                unlock_encrypted_drive
                detect_filesystem
                mount_filesystem
                mount_boot_partitions
                mount_virtual_filesystems
                ;;
            2)
                read -p "Enter encrypted partition path (e.g., /dev/nvme0n1p3): " ENCRYPTED_PARTITION
                unlock_encrypted_drive
                detect_filesystem
                mount_filesystem
                ;;
            3)
                if [[ -z "$ENCRYPTED_PARTITION" ]]; then
                    read -p "Enter encrypted partition path: " ENCRYPTED_PARTITION
                fi
                mount_boot_partitions
                ;;
            4)
                enter_chroot
                ;;
            5)
                reinstall_bootloader
                ;;
            6)
                fix_initramfs
                ;;
            7)
                reset_password
                ;;
            8)
                backup_files
                ;;
            9)
                cleanup_and_exit
                ;;
            10)
                cleanup_and_exit
                print_status "Rebooting system..."
                reboot
                ;;
            0)
                cleanup_and_exit
                exit 0
                ;;
            *)
                print_error "Invalid option"
                ;;
        esac
        
        read -p "Press Enter to continue..."
    done
}

reinstall_bootloader() {
    if [[ ! -d "$MOUNT_POINT/etc" ]]; then
        print_error "System not mounted. Please mount the system first."
        return 1
    fi
    
    print_status "Select bootloader to reinstall:"
    echo "1) GRUB (UEFI)"
    echo "2) GRUB (Legacy BIOS)"
    echo "3) Limine (UEFI)"
    echo "4) systemd-boot"
    read -p "Choice [1-4]: " bl_choice
    
    case $bl_choice in
        1)
            arch-chroot "$MOUNT_POINT" grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
            arch-chroot "$MOUNT_POINT" grub-mkconfig -o /boot/grub/grub.cfg
            ;;
        2)
            arch-chroot "$MOUNT_POINT" grub-install --target=i386-pc /dev/sda
            arch-chroot "$MOUNT_POINT" grub-mkconfig -o /boot/grub/grub.cfg
            ;;
        3)
            arch-chroot "$MOUNT_POINT" mkdir -p /boot/efi/EFI/LIMINE
            arch-chroot "$MOUNT_POINT" cp /usr/share/limine/BOOTX64.EFI /boot/efi/EFI/LIMINE/
            arch-chroot "$MOUNT_POINT" cp /usr/share/limine/limine.sys /boot/
            print_status "Don't forget to create/edit /boot/limine.conf"
            ;;
        4)
            arch-chroot "$MOUNT_POINT" bootctl --path=/boot/efi install
            ;;
        *)
            print_error "Invalid choice"
            return 1
            ;;
    esac
    
    print_success "Bootloader reinstalled"
}

fix_initramfs() {
    if [[ ! -d "$MOUNT_POINT/etc" ]]; then
        print_error "System not mounted. Please mount the system first."
        return 1
    fi
    
    print_status "Updating system and regenerating initramfs..."
    arch-chroot "$MOUNT_POINT" pacman -Syu linux linux-headers
    arch-chroot "$MOUNT_POINT" mkinitcpio -P
    print_success "Initramfs fixed"
}

reset_password() {
    if [[ ! -d "$MOUNT_POINT/etc" ]]; then
        print_error "System not mounted. Please mount the system first."
        return 1
    fi
    
    print_status "Available users:"
    arch-chroot "$MOUNT_POINT" ls /home
    
    read -p "Enter username to reset password: " username
    arch-chroot "$MOUNT_POINT" passwd "$username"
    print_success "Password reset for $username"
}

backup_files() {
    if [[ ! -d "$MOUNT_POINT/home" ]]; then
        print_error "System not mounted. Please mount the system first."
        return 1
    fi
    
    read -p "Enter backup device path (e.g., /dev/sdb1): " backup_dev
    read -p "Enter backup mount point (e.g., /backup): " backup_mount
    
    [[ ! -d "$backup_mount" ]] && mkdir -p "$backup_mount"
    mount "$backup_dev" "$backup_mount"
    
    print_status "Backing up important files..."
    cp -r "$MOUNT_POINT/home" "$backup_mount/" || print_warning "Could not backup home"
    cp "$MOUNT_POINT/etc/fstab" "$backup_mount/" || print_warning "Could not backup fstab"
    arch-chroot "$MOUNT_POINT" pacman -Qqe > "$backup_mount/packages.txt" || print_warning "Could not backup package list"
    
    umount "$backup_mount"
    print_success "Backup completed"
}

# Main script logic
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -p|--partition)
                ENCRYPTED_PARTITION="$2"
                shift 2
                ;;
            -m|--mountpoint)
                MOUNT_POINT="$2"
                shift 2
                ;;
            -c|--cryptname)
                CRYPT_NAME="$2"
                shift 2
                ;;
            -b|--bootloader)
                BOOTLOADER="$2"
                shift 2
                ;;
            -f|--filesystem)
                FILESYSTEM="$2"
                shift 2
                ;;
            --auto-detect)
                AUTO_DETECT=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
    
    # Check dependencies
    check_dependencies
    
    # Set trap for cleanup
    trap cleanup_and_exit EXIT
    
    if [[ "${AUTO_DETECT:-false}" == "true" ]] || [[ $# -eq 0 ]]; then
        interactive_menu
    else
        # Run non-interactively
        [[ -z "$ENCRYPTED_PARTITION" ]] && detect_system
        unlock_encrypted_drive
        [[ -z "$FILESYSTEM" ]] && detect_filesystem
        mount_filesystem
        mount_boot_partitions
        mount_virtual_filesystems
        enter_chroot
    fi
}

# Run main function with all arguments
main "$@"