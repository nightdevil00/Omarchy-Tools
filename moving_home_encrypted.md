# Moving /home to a Separate Encrypted Drive (LUKS2 + Btrfs)

Guide for moving `/home` from the root drive to a dedicated encrypted drive on an
Omarchy/Arch system using systemd-based initramfs.

## System Overview

| Component | Device | UUID | Notes |
|-----------|--------|------|-------|
| Root (LUKS2) | nvme0n1p6 | `83c48ebd-...` | Mapped as `omarchy_root` |
| Root (btrfs) | /dev/mapper/omarchy_root | `109a5487-...` | Subvolumes: `@`, `@home`, `@log`, `@pkg` |
| Home (LUKS2) | nvme1n1p1 | `9d533db0-...` | Mapped as `omarchy_home` |
| Home (btrfs) | /dev/mapper/omarchy_home | `cef2c911-...` | Subvolume: `@home` |

## Prerequisites

- Empty target drive (nvme1n1)
- Root access
- Your initramfs uses `systemd` hooks (check `/etc/mkinitcpio.conf` HOOKS line)

## Finding UUIDs

You'll need UUIDs for fstab and crypttab. Here's how to find them:

```bash
# All block devices with UUIDs
sudo blkid

# Specific device UUIDs (LUKS partition and mapped device)
sudo blkid /dev/nvme1n1p1          # LUKS partition UUID (for crypttab)
sudo blkid /dev/mapper/omarchy_home # btrfs UUID (for fstab)

# Current system layout
lsblk -f

# Current mounts
findmnt
```

**Which UUID goes where:**
- **fstab** uses the **btrfs filesystem UUID** (from `mkfs.btrfs`, shown by `blkid /dev/mapper/omarchy_home`)
- **crypttab** uses the **LUKS partition UUID** (from `cryptsetup luksFormat`, shown by `blkid /dev/nvme1n1p1`)

## Step 1: Back Up Critical Config Files

```bash
sudo cp /etc/fstab /etc/fstab.bak.$(date +%s)
sudo cp /etc/crypttab /etc/crypttab.bak.$(date +%s)
```

## Step 2: Partition the Target Drive

```bash
sudo parted -s /dev/nvme1n1 mklabel gpt
sudo parted -s /dev/nvme1n1 mkpart primary 0% 100%
```

## Step 3: LUKS2 Encrypt the Partition

**Run interactively in your terminal** (requires password input):

```bash
sudo cryptsetup luksFormat \
  --type luks2 \
  --cipher aes-xts-plain64 \
  --key-size 512 \
  --hash sha512 \
  --iter-time 5000 \
  /dev/nvme1n1p1
```

Type `YES` when prompted for confirmation, then enter your passphrase.

## Step 4: Open the LUKS Container

**Run interactively in your terminal** (requires password input):

```bash
sudo cryptsetup open /dev/nvme1n1p1 omarchy_home
```

Verify it opened:

```bash
ls /dev/mapper/omarchy_home
```

## Step 5: Create Btrfs Filesystem and @home Subvolume

```bash
sudo mkfs.btrfs -L OMARCHY_HOME -f /dev/mapper/omarchy_home

sudo mkdir -p /mnt/omarchy_home
sudo mount -t btrfs -o noatime,compress=zstd:3,ssd,space_cache=v2 \
  /dev/mapper/omarchy_home /mnt/omarchy_home

sudo btrfs subvolume create /mnt/omarchy_home/@home

sudo btrfs subvolume list /mnt/omarchy_home
```

You should see `@home` in the output.

## Step 6: Copy /home Data

```bash
sudo rsync -aAXv --exclude='/.snapshots' /home/ /mnt/omarchy_home/@home/
```

Verify the copy:

```bash
du -sh /home/
sudo du -sh /mnt/omarchy_home/@home/
```

## Step 7: Update /etc/fstab

Replace the `/home` mount line. Change the UUID from the root btrfs UUID to the
new home btrfs UUID:

```bash
# Before (home on root drive):
UUID=109a5487-8303-4fdb-888d-75354acbe8d5  /home  btrfs  noatime,compress=zstd,subvol=@home  0 0

# After (home on dedicated drive):
UUID=cef2c911-f949-4352-8b5d-693c04a44494  /home  btrfs  noatime,compress=zstd,subvol=@home  0 0
```

The full fstab should look like:

```
UUID=109a5487-8303-4fdb-888d-75354acbe8d5  /                      btrfs  noatime,compress=zstd,subvol=@       0 0
UUID=cef2c911-f949-4352-8b5d-693c04a44494  /home                  btrfs  noatime,compress=zstd,subvol=@home   0 0
UUID=109a5487-8303-4fdb-888d-75354acbe8d5  /var/log               btrfs  noatime,compress=zstd,subvol=@log    0 0
UUID=109a5487-8303-4fdb-888d-75354acbe8d5  /var/cache/pacman/pkg  btrfs  noatime,compress=zstd,subvol=@pkg    0 0
UUID=86EB-A697  /boot                   vfat   umask=0077              0 2

# Btrfs swapfile for system hibernation
/swap/swapfile none swap defaults,pri=0 0 0
```

## Step 8: Update /etc/crypttab

Add an entry for the new encrypted home drive so it unlocks at boot:

```bash
# Add this line to /etc/crypttab:
omarchy_home  UUID=9d533db0-67eb-4513-81e6-84a1d232bf43  none  luks
```

The `none` means it will prompt for a passphrase at boot (same as root drive behavior).

## Step 9: Regenerate Initramfs

```bash
sudo mkinitcpio -P
```

## Step 10: Reboot and Verify

```bash
sudo reboot
```

After reboot, verify:

```bash
findmnt /home
lsblk -f /dev/nvme1n1
```

Expected output should show `/home` mounted from `omarchy_home` on `nvme1n1p1`.

## Accessing the Old Home (After Migration)

The old home still exists as the `@home` btrfs subvolume on the root drive.

Mount it:

```bash
sudo mkdir -p /mnt/old_home
sudo mount -t btrfs -o subvol=/@home,noatime /dev/mapper/omarchy_root /mnt/old_home
```

Access files at `/mnt/old_home/mihai/`.

Unmount when done:

```bash
sudo umount /mnt/old_home
```

## Rollback (If Something Goes Wrong)

If you need to revert, restore the original fstab:

```bash
sudo cp /etc/fstab.bak.* /etc/fstab
sudo mkinitcpio -P
sudo reboot
```

Then optionally remove the LUKS container:

```bash
sudo cryptsetup close omarchy_home
```

## Key Notes

- **Btrfs compression**: `zstd:3` matches the root drive settings
- **SSD optimizations**: `ssd` and `space_cache=v2` mount options
- **LUKS2**: Uses `aes-xts-plain64` cipher, 512-bit key, SHA-512 hash
- **Boot unlock**: The `systemd` initramfs hooks read `/etc/crypttab` and prompt
  for the passphrase at boot for both root and home drives
- **The root drive's `@home` subvolume remains intact** — it's just no longer mounted at `/home`
