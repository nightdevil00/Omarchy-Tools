#!/bin/bash
# Interactive rescue: unlock LUKS, mount the Omarchy btrfs layout, arch-chroot.
# Run as root from the live ISO. Optional args are executed inside the chroot,
# e.g.: ./chroot-rescue.sh mkinitcpio -P

set -euo pipefail

MNT=/mnt
MAPPER=omarchy_root
GUM=$(command -v gum || true)

die() { echo "Error: $*" >&2; exit 1; }
(( EUID == 0 )) || die "run as root from the live ISO"

choose() {
  local title=$1; shift
  echo "$title"
  if [[ -n $GUM ]]; then
    gum choose "${@}"
  else
    local i=1
    for opt in "$@"; do echo "  $i) $opt"; ((i++)); done
    local n
    read -rp "#? " n
    (( n >= 1 && n <= $# )) || die "invalid choice"
    eval "echo \${$n}"
  fi
}

confirm() {
  local msg=$1
  if [[ -n $GUM ]]; then gum confirm "$msg"
  else read -rp "$msg [y/N] " a; [[ ${a,,} == y* ]]
  fi
}

mapfile -t LUKS_PARTS < <(lsblk -rno PATH,TYPE | awk '$2=="crypto_LUKS"{print $1}')
(( ${#LUKS_PARTS[@]} > 0 )) || die "no LUKS partitions found (already unlocked? booting the wrong media?)"

if [[ -e /dev/mapper/$MAPPER ]] && confirm "/dev/mapper/$MAPPER already exists - reuse it?"; then
  PART="(already open)"
else
  if (( ${#LUKS_PARTS[@]} == 1 )); then
    PART=${LUKS_PARTS[0]}
    confirm "Unlock $PART as /dev/mapper/$MAPPER?" || die "aborted"
  else
    PART=$(choose "Multiple LUKS partitions found - which one?" "${LUKS_PARTS[@]}")
  fi
  [[ -e /dev/mapper/$MAPPER ]] || cryptsetup open "$PART" "$MAPPER"
fi

FSTYPE=$(lsblk -rno FSTYPE "/dev/mapper/$MAPPER" | head -n1)
[[ $FSTYPE == btrfs ]] || die "/dev/mapper/$MAPPER is $FSTYPE, expected btrfs"

if mountpoint -q "$MNT"; then
  die "$MNT is already a mountpoint - unmount it first (umount -R $MNT)"
fi
[[ -e $MNT ]] || mkdir -p "$MNT"

echo "Mounting root subvolume @ at $MNT..."
mount -o subvol=@ "/dev/mapper/$MAPPER" "$MNT"

declare -A SUBVOLS=( [@home]=/home [@log]=/var/log [@pkg]=/var/cache/pacman/pkg )
while IFS= read -r sv; do
  for name in "${!SUBVOLS[@]}"; do
    if [[ $sv == "$name" || $sv == "$name/"* ]]; then
      mkdir -p "$MNT${SUBVOLS[$name]}"
      mount -o subvol="$name" "/dev/mapper/$MAPPER" "$MNT${SUBVOLS[$name]}"
    fi
  done
done < <(btrfs subvolume list "$MNT" | awk '{print $NF}')

ESP_SPEC=$(awk '$2=="/boot" {print $1; exit}' "$MNT/etc/fstab" 2>/dev/null || true)
if [[ -n $ESP_SPEC ]]; then
  echo "Mounting ESP ($ESP_SPEC) at $MNT/boot..."
  mount "$ESP_SPEC" "$MNT/boot"
else
  mapfile -t EFIS < <(lsblk -rno PATH,FSTYPE,PARTTYPENAME | awk 'tolower($0) ~ /vfat|efi/ {print $1}')
  if (( ${#EFIS[@]} > 0 )) && confirm "No /boot entry in fstab - pick an EFI partition to mount at $MNT/boot?"; then
    ESP=$(choose "Which EFI partition?" "${EFIS[@]}")
    mount "$ESP" "$MNT/boot"
  else
    echo "Warning: no ESP mounted - mkinitcpio/Limine work will fail without /boot"
  fi
fi

echo ""
echo "Mounted:"
findmnt -R "$MNT" -o TARGET,SOURCE,FSTYPE
echo ""

CHROOT_RC=0
if (( $# > 0 )); then
  arch-chroot "$MNT" "$@" || CHROOT_RC=$?
else
  echo "Dropping into the target. Useful now: mkinitcpio -P"
  arch-chroot "$MNT" || CHROOT_RC=$?
fi
if confirm "Clean up (unmount everything and close LUKS)?"; then
  umount -R "$MNT" 2>/dev/null || true
  cryptsetup close "$MAPPER" 2>/dev/null || true
  echo "Cleanup done."
else
  echo "Leaving mounts in place at $MNT."
fi
exit "$CHROOT_RC"
