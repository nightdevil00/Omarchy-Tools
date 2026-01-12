# System Recovery Guide: Mount LUK2 Encrypted Drive with arch-chroot

This guide helps you recover your system by mounting a LUK2 encrypted SSD/NVME drive using arch-chroot.

## Prerequisites

- Arch Linux live USB/ISO
- Encrypted drive with LUK2
- Knowledge of your encryption password

## Step 1: Boot from Live Media

1. Insert Arch Linux USB and boot from it
2. Select "Boot Arch Linux" from the boot menu
3. Wait for the live environment to load

## Step 2: Identify Encrypted Drive

List available block devices:
```bash
lsblk
```

Look for your encrypted partition (typically named something like `luks-xxx` or showing as `crypt`).

## Step 3: Unlock the LUK2 Drive

Replace `/dev/nvme0n1p3` with your actual encrypted partition:

```bash
cryptsetup open /dev/nvme0n1p3 cryptroot
```

Enter your encryption password when prompted.

## Step 4: Mount Filesystem

Mount the unlocked device (adjust mount points as needed):

```bash
# Mount root partition
mount /dev/mapper/cryptroot /mnt

# Mount boot partition (if separate)
mount /dev/nvme0n1p1 /mnt/boot

# Mount EFI partition (if separate)
mount /dev/nvme0n1p2 /mnt/boot/efi

mount -o subvol=@ /dev/mapper/crypt-drive /mnt
mount -o subvol=@home /dev/mapper/crypt-drive /mnt/home
mount -o subvol=@log /dev/mapper/crypt-drive /mnt/var/log
mount -o subvol=@pkg /dev/mapper/crypt-drive /mnt/var/cache/pacman/pkg
mount -o subvol=@.snapshots /dev/mapper/crypt-drive /mnt/.snapshots


```

## Step 5: Mount Virtual Filesystems

```bash
mount --bind /dev /mnt/dev
mount --bind /proc /mnt/proc
mount --bind /sys /mnt/sys
mount --bind /run /mnt/run
```

## Step 6: Enter arch-chroot

```bash
arch-chroot /mnt
```

## Step 7: Common Recovery Tasks

### Update System
```bash
pacman -Syu
```

### Reinstall GRUB
```bash
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
```

### Reinstall Limine Bootloader (UEFI)
```bash
# Install Limine to EFI
mkdir -p /boot/efi/EFI/LIMINE
cp /usr/share/limine/BOOTX64.EFI /boot/efi/EFI/LIMINE/
cp /usr/share/limine/limine.sys /boot/

# Create/update limine.conf
nano /boot/limine.conf

# Update EFI entry
efibootmgr --create --disk /dev/nvme0n1 --part 2 --label "Limine" --loader "\\EFI\\LIMINE\\BOOTX64.EFI"
```

### Fix initramfs
```bash
pacman -Syu linux linux-headers && mkinitcpio -P
```

### Reset Password
```bash
passwd username
```

## Step 8: Exit and Reboot

```bash
# Exit chroot
exit

# Unmount everything
umount -R /mnt

# Close encrypted device
cryptsetup close cryptroot

# Reboot
reboot
```

## Troubleshooting

### "No key available with this passphrase"
- Double-check you're using the correct partition
- Ensure caps lock is off
- Try different keyboard layouts

### "mount: wrong fs type"
- Check filesystem type with `blkid`
- Use appropriate mount command: `mount -t ext4 /dev/mapper/cryptroot /mnt`

### Boot partition not found
- Use `fdisk -l` to see all partitions
- Common boot partitions: `/dev/sda1`, `/dev/nvme0n1p1`, `/dev/nvme0n1p2`

## Save Important Data

Before making changes, backup critical data:
```bash
# Create backup directory
mkdir /backup
mount /dev/external_drive /backup

# Copy important files
cp -r /mnt/home/user/Documents /backup/
cp -r /mnt/home/user/Pictures /backup/
cp /mnt/etc/fstab /backup/
```

## Emergency Commands

### Check disk health
```bash
smartctl -a /dev/nvme0n1
```

### Filesystem check
```bash
fsck.ext4 /dev/mapper/cryptroot
```

### List installed packages
```bash
pacman -Qqe > /backup/packages.txt
```

Remember to replace device names and partition numbers with your actual system configuration.

## Limine Bootloader Configuration

### Sample limine.conf for LUK2 + UEFI

Create `/boot/limine.conf` with the following content:

```conf
# Limine Bootloader Configuration
# Timeout in seconds before booting default entry
TIMEOUT=5

# Default boot entry
DEFAULT_ENTRY=Arch Linux

# Boot entry for encrypted Arch Linux (main subvolume @)
:Arch Linux
    PROTOCOL=linux
    KERNEL_PATH=boot:///vmlinuz-linux
    INITRD_PATH=boot:///initramfs-linux.img
    KERNEL_CMDLINE=cryptdevice=UUID=<LUKS_UUID>:cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw quiet

# Boot entry for encrypted Arch Linux (fallback initramfs)
:Arch Linux (fallback)
    PROTOCOL=linux
    KERNEL_PATH=boot:///vmlinuz-linux
    INITRD_PATH=boot:///initramfs-linux-fallback.img
    KERNEL_CMDLINE=cryptdevice=UUID=<LUKS_UUID>:cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw quiet

# Boot entry for recovery
:Arch Linux Recovery
    PROTOCOL=linux
    KERNEL_PATH=boot:///vmlinuz-linux
    INITRD_PATH=boot:///initramfs-linux.img
    KERNEL_CMDLINE=cryptdevice=UUID=<LUKS_UUID>:cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw systemd.unit=rescue.target

# Boot entry for snapshot rollback (if using @snapshots)
:Arch Linux (previous snapshot)
    PROTOCOL=linux
    KERNEL_PATH=boot:///vmlinuz-linux
    INITRD_PATH=boot:///initramfs-linux.img
    KERNEL_CMDLINE=cryptdevice=UUID=<LUKS_UUID>:cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@snapshots/@backup rw quiet

# Windows entry (if dual boot)
:Windows
    PROTOCOL=chainload
    IMAGE_PATH=chain:///EFI/Microsoft/Boot/bootmgfw.efi

# Reboot entry
:Reboot
    PROTOCOL=manual
    CMD=reboot

# Shutdown entry  
:Shutdown
    PROTOCOL=manual
    CMD=shutdown
```

### Finding Your LUKS UUID

Get the UUID of your encrypted partition:

```bash
# Before unlocking
blkid | grep crypto_LUKS

# Or after unlocking
ls -la /dev/disk/by-uuid/ | grep luks
```

Replace `<LUKS_UUID>` in the config with your actual UUID.

### Btrfs Subvolume Configuration

For Btrfs with subvolumes (most common structure):

```conf
KERNEL_CMDLINE=cryptdevice=UUID=<LUKS_UUID>:cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw quiet
```

Common Btrfs subvolume layouts:
- `@` - root filesystem
- `@home` - home directory (if separate)
- `@var` - /var directory (if separate)
- `@snapshots` - snapshot directory
- `@backup` - backup snapshots

For home on separate subvolume:
```conf
KERNEL_CMDLINE=cryptdevice=UUID=<LUKS_UUID>:cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw quiet home_subvol=@home
```

### Checking Your Btrfs Subvolumes

List all subvolumes:
```bash
btrfs subvolume list /mnt
```

Show default subvolume:
```bash
btrfs subvolume get-default /mnt
```

### Creating New Boot Entries for Different Subvolumes

If you need to boot from a different subvolume:

```conf
:Arch Linux (home subvolume)
    PROTOCOL=linux
    KERNEL_PATH=boot:///vmlinuz-linux
    INITRD_PATH=boot:///initramfs-linux.img
    KERNEL_CMDLINE=cryptdevice=UUID=<LUKS_UUID>:cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@home rw quiet
```

### Keyfile Support (Optional)

If using a keyfile stored in initramfs:

```conf
KERNEL_CMDLINE=cryptdevice=UUID=<LUKS_UUID>:cryptroot root=/dev/mapper/cryptroot cryptkey=rootfs:/path/to/keyfile rw quiet
```

### Testing Limine Configuration

1. Save the config file
2. Regenerate initramfs: `mkinitcpio -P`
3. Reboot and test
4. If it fails, boot with fallback or recovery entry

### Common Limine Issues

- **Kernel not found**: Check `KERNEL_PATH` points to correct kernel in `/boot`
- **Initramfs not found**: Verify `INITRD_PATH` matches actual initramfs files
- **Encryption fails**: Double-check LUKS UUID and partition mapping
- **Boot hangs**: Add `nomodeset` or `debug` to `KERNEL_CMDLINE` for troubleshooting