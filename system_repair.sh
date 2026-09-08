#!/bin/bash

# System Repair Script for Arch Linux Live ISO
# Allows disk selection, auto-detects encryption, mounts the system and chroots into it

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
SELECTED_DISK=""
SELECTED_PARTITION=""
ENCRYPTED_DISK=false
ROOT_DEVICE=""
CRYPT_NAME="cryptroot"
MOUNT_POINT="/mnt"
FILESYSTEM=""

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

check_dependencies() {
    print_status "Checking dependencies..."
    local deps=("cryptsetup" "lsblk" "blkid" "mount" "umount" "btrfs" "arch-chroot")
    local dep
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            print_error "Missing dependency: $dep"
            exit 1
        fi
    done
    print_success "All dependencies found"
}

select_disk() {
    print_status "Available disks:"
    mapfile -t disks < <(lsblk -dno NAME,SIZE,MODEL)

    if [[ ${#disks[@]} -eq 0 ]]; then
        print_error "No disks found."
        exit 1
    fi

    while true; do
        echo " 0) Quit"
        for i in "${!disks[@]}"; do
            echo "  $((i+1)). ${disks[$i]}"
        done
        read -rp "Select a disk: " choice

        if [[ "$choice" == "0" ]]; then
            print_status "Exiting."
            exit 0
        fi

        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#disks[@]} )); then
            local name
            name=$(awk '{print $1}' <<< "${disks[$((choice-1))]}")
            SELECTED_DISK="/dev/$name"
            print_success "Selected disk: $SELECTED_DISK"
            return
        fi

        print_error "Invalid selection, try again."
    done
}

pick_partition() {
    local -n parts=$1
    if [[ ${#parts[@]} -eq 1 ]]; then
        SELECTED_PARTITION="${parts[0]}"
        print_success "Using partition: $SELECTED_PARTITION"
        return
    fi

    while true; do
        print_status "Multiple matching partitions found:"
        echo " 0) Quit"
        for i in "${!parts[@]}"; do
            local size ftype
            size=$(lsblk -no SIZE "${parts[$i]}" 2>/dev/null || echo "?")
            ftype=$(lsblk -no FSTYPE "${parts[$i]}" 2>/dev/null || echo "?")
            echo "  $((i+1)). ${parts[$i]} ($size, $ftype)"
        done
        read -rp "Select a partition: " choice

        if [[ "$choice" == "0" ]]; then
            print_status "Exiting."
            exit 0
        fi

        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#parts[@]} )); then
            SELECTED_PARTITION="${parts[$((choice-1))]}"
            print_success "Selected partition: $SELECTED_PARTITION"
            return
        fi

        print_error "Invalid selection, try again."
    done
}

detect_encryption() {
    print_status "Scanning partitions of $SELECTED_DISK..."
    local partitions=()
    local part fstype
    while IFS= read -r part; do
        partitions+=("$part")
    done < <(lsblk -npr -o NAME,TYPE "$SELECTED_DISK" | awk '$2 == "part" { print $1 }')

    local luks_parts=() fs_parts=()
    for part in "${partitions[@]}"; do
        fstype=$(blkid -o value -s TYPE "$part" 2>/dev/null || echo "")
        case "$fstype" in
            crypto_LUKS) luks_parts+=("$part") ;;
            btrfs|ext4|xfs) fs_parts+=("$part") ;;
        esac
    done

    if (( ${#luks_parts[@]} > 0 )); then
        print_status "Encrypted (LUKS) partition detected."
        ENCRYPTED_DISK=true
        pick_partition luks_parts
        print_success "Using encrypted partition: $SELECTED_PARTITION"
    else
        print_status "No encryption detected on $SELECTED_DISK."
        if (( ${#fs_parts[@]} > 0 )); then
            pick_partition fs_parts
            print_success "Using filesystem partition: $SELECTED_PARTITION"
        else
            print_error "No mountable filesystem found on $SELECTED_DISK."
            exit 1
        fi
    fi
}

unlock_encrypted_drive() {
    print_status "Unlocking encrypted drive: $SELECTED_PARTITION"

    if [[ -e "/dev/mapper/$CRYPT_NAME" ]]; then
        print_warning "Device $CRYPT_NAME already exists, attempting to close first..."
        cryptsetup close "$CRYPT_NAME" || true
    fi

    if ! cryptsetup open "$SELECTED_PARTITION" "$CRYPT_NAME"; then
        print_error "Failed to unlock encrypted partition."
        print_status "Please check the passphrase and try again."
        exit 1
    fi

    print_success "Successfully unlocked encrypted partition"
}

detect_filesystem() {
    local device=$1
    print_status "Detecting filesystem on $device..."
    local fstype
    fstype=$(blkid -o value -s TYPE "$device" 2>/dev/null || echo "")

    case "$fstype" in
        btrfs) FILESYSTEM="btrfs" ;;
        ext4) FILESYSTEM="ext4" ;;
        xfs) FILESYSTEM="xfs" ;;
        *)
            print_status "Unable to auto-detect filesystem. Please specify:"
            echo "1) ext4"
            echo "2) btrfs"
            echo "3) xfs"
            read -rp "Choose filesystem [1-3]: " fs_choice
            case "$fs_choice" in
                1) FILESYSTEM="ext4" ;;
                2) FILESYSTEM="btrfs" ;;
                3) FILESYSTEM="xfs" ;;
                *) print_error "Invalid choice"; exit 1 ;;
            esac
            ;;
    esac

    print_success "Detected filesystem: $FILESYSTEM"
}

mount_filesystem() {
    local device=$1
    print_status "Mounting filesystem..."
    [[ ! -d "$MOUNT_POINT" ]] && mkdir -p "$MOUNT_POINT"

    case "$FILESYSTEM" in
        btrfs)
            mount_btrfs_subvolumes "$device"
            ;;
        ext4|xfs)
            mount "$device" "$MOUNT_POINT"
            print_success "Mounted $FILESYSTEM filesystem"
            ;;
        *)
            print_error "Unsupported filesystem: $FILESYSTEM"
            exit 1
            ;;
    esac
}

mount_btrfs_subvolumes() {
    local device=$1
    print_status "Scanning Btrfs subvolumes on $device..."

    mount "$device" "$MOUNT_POINT"

    btrfs subvolume list "$MOUNT_POINT" >/dev/null 2>&1 || print_warning "Could not list subvolumes"

    # Common subvolume patterns
    local common_subvols=("@" "@home" "@log" "@pkg" "@.snapshots" "@var" "@root")
    local found_subvols=()
    local subvol
    for subvol in "${common_subvols[@]}"; do
        if btrfs subvolume show "$MOUNT_POINT/$subvol" &>/dev/null; then
            found_subvols+=("$subvol")
        fi
    done

    umount "$MOUNT_POINT"

    if [[ ${#found_subvols[@]} -eq 0 ]]; then
        mount "$device" "$MOUNT_POINT"
        print_warning "No subvolumes detected, mounting as single volume"
    elif [[ " ${found_subvols[*]} " =~ " @ " ]]; then
        mount -o subvol=@ "$device" "$MOUNT_POINT"
        print_success "Mounted @ subvolume"

        for subvol in "${found_subvols[@]}"; do
            if [[ "$subvol" != "@" ]]; then
                local mount_path=""
                case "$subvol" in
                    "@home") mount_path="$MOUNT_POINT/home" ;;
                    "@log") mount_path="$MOUNT_POINT/var/log" ;;
                    "@pkg") mount_path="$MOUNT_POINT/var/cache/pacman/pkg" ;;
                    "@.snapshots") mount_path="$MOUNT_POINT/.snapshots" ;;
                    "@var") mount_path="$MOUNT_POINT/var" ;;
                    "@root") mount_path="$MOUNT_POINT/root" ;;
                    *) continue ;;
                esac

                [[ ! -d "$mount_path" ]] && mkdir -p "$mount_path"
                mount -o subvol="$subvol" "$device" "$mount_path"
                print_success "Mounted $subvol to $mount_path"
            fi
        done
    else
        mount -o subvol="${found_subvols[0]}" "$device" "$MOUNT_POINT"
        print_success "Mounted ${found_subvols[0]} as root"
    fi
}

mount_boot_partitions() {
    print_status "Looking for boot partitions on $SELECTED_DISK..."
    local efi_part="" boot_part=""
    local part partname label fstype
    while IFS= read -r part; do
        [[ "$part" == "$SELECTED_PARTITION" ]] && continue
        partname=$(basename "$part")
        label=$(lsblk -no LABEL "$part" 2>/dev/null || echo "")
        fstype=$(lsblk -no FSTYPE "$part" 2>/dev/null || echo "")

        case "$fstype" in
            vfat)
                if [[ "$label" == "EFI" ]] || [[ "$partname" =~ p?[12]$ ]]; then
                    efi_part="$part"
                fi
                ;;
            ext2|ext3|ext4)
                if [[ "$label" == "BOOT" ]] || [[ "$partname" =~ ^[^0-9]*1$ ]]; then
                    boot_part="$part"
                fi
                ;;
        esac
    done < <(lsblk -npr -o NAME,TYPE "$SELECTED_DISK" | awk '$2 == "part" { print $1 }')

    if [[ -n "$boot_part" ]]; then
        [[ ! -d "$MOUNT_POINT/boot" ]] && mkdir -p "$MOUNT_POINT/boot"
        mount "$boot_part" "$MOUNT_POINT/boot"
        print_success "Mounted boot partition: $boot_part"

        if [[ -n "$efi_part" ]]; then
            [[ ! -d "$MOUNT_POINT/boot/efi" ]] && mkdir -p "$MOUNT_POINT/boot/efi"
            mount "$efi_part" "$MOUNT_POINT/boot/efi"
            print_success "Mounted EFI partition: $efi_part"
        fi
    elif [[ -n "$efi_part" ]]; then
        [[ ! -d "$MOUNT_POINT/boot" ]] && mkdir -p "$MOUNT_POINT/boot"
        mount "$efi_part" "$MOUNT_POINT/boot"
        print_success "Mounted EFI partition as boot: $efi_part"
    else
        print_warning "No boot or EFI partition found, skipping."
    fi
}

mount_virtual_filesystems() {
    print_status "Mounting virtual filesystems..."
    local dir
    for dir in dev proc sys run; do
        [[ ! -d "$MOUNT_POINT/$dir" ]] && mkdir -p "$MOUNT_POINT/$dir"
        mount --bind "/$dir" "$MOUNT_POINT/$dir"
    done
    print_success "Mounted virtual filesystems"
}

enter_chroot() {
    print_status "Entering arch-chroot environment..."
    print_status "You can now perform system maintenance tasks."
    print_status "Common commands:"
    echo "  pacman -Syu                    # Update system"
    echo "  mkinitcpio -P                  # Regenerate initramfs"
    echo "  passwd username                # Reset password"
    echo "  systemctl enable service       # Enable service"
    echo "  exit                           # Leave chroot"

    arch-chroot "$MOUNT_POINT"
}

ask_chroot() {
    echo
    read -rp "Do you want to chroot into the system? (y/N): " answer
    case "${answer,,}" in
        y|yes)
            enter_chroot
            ;;
        *)
            print_status "Exiting without chrooting."
            ;;
    esac
}

cleanup_and_exit() {
    print_status "Cleaning up..."

    if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
        umount -R "$MOUNT_POINT" 2>/dev/null || true
        print_success "Unmounted filesystems"
    fi

    if [[ -e "/dev/mapper/$CRYPT_NAME" ]]; then
        cryptsetup close "$CRYPT_NAME" 2>/dev/null || true
        print_success "Closed encrypted device"
    fi

    print_success "Cleanup completed"
}

main() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root."
        exit 1
    fi

    check_dependencies
    trap cleanup_and_exit EXIT

    [[ ! -d "$MOUNT_POINT" ]] && mkdir -p "$MOUNT_POINT"

    select_disk
    detect_encryption

    if [[ "$ENCRYPTED_DISK" == "true" ]]; then
        unlock_encrypted_drive
        ROOT_DEVICE="/dev/mapper/$CRYPT_NAME"
    else
        ROOT_DEVICE="$SELECTED_PARTITION"
    fi

    detect_filesystem "$ROOT_DEVICE"
    mount_filesystem "$ROOT_DEVICE"
    mount_boot_partitions
    mount_virtual_filesystems

    ask_chroot
}

# Run main function
main "$@"