#!/bin/bash
# Interactive rescue: pick disk -> pick LUKS partition -> unlock -> mount btrfs
# layout + ESP -> arch-chroot (mkinitcpio -P). Run as root from the live ISO.

set -euo pipefail

MNT=/mnt
MAPPER=omarchy_root
GUM=$(command -v gum || true)

die() { echo "Error: $*" >&2; exit 1; }
(( EUID == 0 )) || die "run as root from the live ISO"

choose() {
  local title=$1; shift
  echo ""
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

pick_from() {
  local title=$1 prefix=$2
  shift 2
  local sel
  sel=$(choose "$title" "${@}")
  echo "${sel#$prefix}"
}

echo "== Omarchy rescue chroot =="

if [[ -e /dev/mapper/$MAPPER ]] && confirm "/dev/mapper/$MAPPER already exists - reuse it?"; then
  ROOT_SRC="/dev/mapper/$MAPPER"
else
  mapfile -t DISKS < <(lsblk -drno PATH,SIZE,MODEL | awk '$1 ~ /^\/dev\/(sd[a-z]+|nvme[0-9]+n[0-9]+|mmcblk[0-9]+)$/ {print $1"  "$2"  "$3}')
  (( ${#DISKS[@]} > 0 )) || die "no disks found"
  SEL=$(choose "Step 1/6: select the disk Omarchy was installed to" "${DISKS[@]}")
  DISK=$(echo "$SEL" | awk '{print $1}')

  mapfile -t PARTS < <(lsblk -rno PATH,SIZE,FSTYPE,PARTTYPENAME "$DISK" | awk '$3 != "" {print $1"  "$2"  "$3"  "$4}')
  (( ${#PARTS[@]} > 0 )) || die "no partitions found on $DISK"

  LUKS_GUESS=$(lsblk -rno PATH,FSTYPE "$DISK" | awk '$2=="crypto_LUKS"{print $1}' | head -n1)
  PROMPT="Step 2/6: select the LUKS2 partition containing Omarchy"
  [[ -n $LUKS_GUESS ]] && PROMPT+=" (likely $LUKS_GUESS)"
  SEL=$(choose "$PROMPT" "${PARTS[@]}")
  PART=$(echo "$SEL" | awk '{print $1}')

  FSTYPE=$(lsblk -rno FSTYPE "$PART")
  if [[ $FSTYPE == crypto_LUKS ]]; then
    confirm "Step 3/6: decrypt $PART?"
  elif confirm "$PART is $FSTYPE, not LUKS. Mount it as an unencrypted btrfs root?"; then
    ROOT_SRC="$PART"
  else
    die "aborted"
  fi

  if [[ -z ${ROOT_SRC:-} ]]; then
    while :; do
      echo ""
      read -rsp "Step 4/6: enter the LUKS passphrase for $PART: " PW
      echo ""
      if printf '%s' "$PW" | cryptsetup open "$PART" "$MAPPER" --key-file=- 2>/dev/null; then
        unset PW
        break
      fi
      unset PW
      echo "Wrong passphrase or unlock failed, try again."
      confirm "Retry?" || die "aborted"
    done
    ROOT_SRC="/dev/mapper/$MAPPER"
  fi
fi

FSTYPE=$(lsblk -rno FSTYPE "$ROOT_SRC" | head -n1)
[[ $FSTYPE == btrfs ]] || die "$ROOT_SRC is $FSTYPE, expected btrfs"

if mountpoint -q "$MNT"; then
  die "$MNT is already a mountpoint - unmount it first (umount -R $MNT)"
fi
[[ -e $MNT ]] || mkdir -p "$MNT"

echo ""
echo "Step 5/6: mounting btrfs subvolumes..."
mount -o subvol=@ "$ROOT_SRC" "$MNT"

declare -A SUBVOLS=( [@home]=/home [@log]=/var/log [@pkg]=/var/cache/pacman/pkg )
while IFS= read -r sv; do
  for name in "${!SUBVOLS[@]}"; do
    if [[ $sv == "$name" || $sv == "$name/"* ]]; then
      mkdir -p "$MNT${SUBVOLS[$name]}"
      mount -o subvol="$name" "$ROOT_SRC" "$MNT${SUBVOLS[$name]}"
    fi
  done
done < <(btrfs subvolume list "$MNT" | awk '{print $NF}')

ESP_SPEC=$(awk '$2=="/boot" {print $1; exit}' "$MNT/etc/fstab" 2>/dev/null || true)
if [[ -n $ESP_SPEC ]]; then
  echo "Mounting ESP ($ESP_SPEC) at $MNT/boot..."
  mount "$ESP_SPEC" "$MNT/boot"
else
  mapfile -t EFIS < <(lsblk -rno PATH,FSTYPE,PARTTYPENAME | awk 'tolower($0) ~ /vfat|efi/ {print $1"  "$2"  "$3}')
  if (( ${#EFIS[@]} > 0 )); then
    SEL=$(choose "No /boot entry in fstab - select the EFI partition" "${EFIS[@]}")
    ESP=$(echo "$SEL" | awk '{print $1}')
    mount "$ESP" "$MNT/boot"
  else
    echo "Warning: no ESP mounted - mkinitcpio/Limine work will fail without /boot"
  fi
fi

echo ""
echo "Mounted:"
findmnt -R "$MNT" -o TARGET,SOURCE,FSTYPE
echo ""

ACTION=$(choose "Step 6/6: what now?" \
  "Run mkinitcpio -P now" \
  "Open a shell in the installed system" \
  "Both (mkinitcpio -P, then shell)" \
  "Nothing - just clean up")

CHROOT_RC=0
case "$ACTION" in
  "Run mkinitcpio -P now") arch-chroot "$MNT" mkinitcpio -P || CHROOT_RC=$? ;;
  "Open a shell in the installed system") arch-chroot "$MNT" || CHROOT_RC=$? ;;
  "Both (mkinitcpio -P, then shell)")
    arch-chroot "$MNT" mkinitcpio -P || CHROOT_RC=$?
    (( CHROOT_RC == 0 )) && { echo ""; arch-chroot "$MNT" || CHROOT_RC=$?; }
    ;;
esac

if confirm "Clean up (unmount everything and close LUKS)?"; then
  umount -R "$MNT" 2>/dev/null || true
  [[ $ROOT_SRC == /dev/mapper/* ]] && cryptsetup close "$MAPPER" 2>/dev/null || true
  echo "Cleanup done."
else
  echo "Leaving mounts in place at $MNT."
fi
exit "$CHROOT_RC"
