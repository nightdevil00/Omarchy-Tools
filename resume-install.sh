#!/bin/bash
# Resume a Quattro (4.0) Omarchy install halted by the fix-synaptic-touchpad.sh
# psmouse bug (basecamp/omarchy#6985). Run as root from the live ISO.

set -euo pipefail

MNT=/mnt
TARGET_APPLY="$MNT/usr/bin/omarchy-apply-system"
TOUCHPAD_FIX="$MNT/usr/share/omarchy/install/hardware/fix-synaptic-touchpad.sh"

if (( EUID != 0 )); then
  echo "Error: run as root (sudo) from the live ISO" >&2
  exit 1
fi

if [[ ! -x $TARGET_APPLY ]]; then
  echo "Error: $TARGET_APPLY not found - is the install target still mounted at $MNT?" >&2
  echo "If you rebooted the ISO, remount the target's root btrfs subvol (@) at $MNT first." >&2
  exit 1
fi

USER_NAME="${1:-}"
if [[ -z $USER_NAME ]]; then
  USER_NAME=$(ls -1 "$MNT/home" 2>/dev/null | head -n1 || true)
fi
if [[ -z $USER_NAME ]] || ! grep -q "^${USER_NAME}:" "$MNT/etc/passwd"; then
  echo "Error: could not detect the install user. Pass it explicitly:" >&2
  echo "  $0 <username>" >&2
  exit 1
fi
echo "Install user: $USER_NAME"

echo "[1/4] Patching fix-synaptic-touchpad.sh to be non-fatal..."
if grep -q '|| true' "$TOUCHPAD_FIX" 2>/dev/null; then
  echo "      already patched"
else
  sed -i 's|^\(\s*modprobe psmouse synaptics_intertouch=1\)$|\1 2>/dev/null \|\| true|' "$TOUCHPAD_FIX"
fi

echo "[2/4] Checking network..."
if ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
  echo "      online - restoring online pacman mirrors (works around missing offline vulkan packages)"
  cp -f "$MNT/usr/share/omarchy/default/pacman/pacman-stable.conf" "$MNT/etc/pacman.conf"
  cp -f "$MNT/usr/share/omarchy/default/pacman/mirrorlist-stable" "$MNT/etc/pacman.d/mirrorlist"
  if grep -q '^\[offline\]' "$MNT/etc/pacman.conf"; then
    echo "Error: [offline] repo still present in $MNT/etc/pacman.conf after restore" >&2
    exit 1
  fi
  echo "      refreshing package databases (stale offline dbs cause 404s on version-pinned packages)"
  arch-chroot "$MNT" pacman -Sy
else
  echo "      offline - leaving offline mirror config untouched"
fi

echo "[3/4] Re-running system finalizer (this can take a while)..."
START_EPOCH=$(date +%s)
arch-chroot "$MNT" env --unset=XDG_RUNTIME_DIR \
  OMARCHY_PATH=/usr/share/omarchy \
  OMARCHY_INSTALL=/usr/share/omarchy/install \
  OMARCHY_INSTALL_USER="$USER_NAME" \
  OMARCHY_START_TIME="$(date '+%Y-%m-%d %H:%M:%S')" \
  OMARCHY_START_EPOCH="$START_EPOCH" \
  OMARCHY_MIRROR=stable \
  OMARCHY_ISO_REF=quattro \
  OMARCHY_RUNTIME_PACKAGE=omarchy \
  OMARCHY_SETTINGS_PACKAGE=omarchy-settings \
  OMARCHY_NVIM_PACKAGE=omarchy-nvim \
  OMARCHY_INSTALL_LOG_FILE=/var/log/omarchy-install.log \
  OMARCHY_LOG_TO_STDOUT=1 \
  /usr/bin/omarchy-apply-system --install-user "$USER_NAME" --first-install

echo ""
echo "Done. You can now reboot into Omarchy."
echo "If anything still fails, share this log:"
echo "  curl -sf -F \"file=@$MNT/var/log/omarchy-install.log\" -Fexpires=24 https://logs.omarchy.org/"
