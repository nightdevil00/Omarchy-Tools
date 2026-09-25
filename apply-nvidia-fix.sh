#!/usr/bin/env bash
#
# apply-nvidia-fix.sh — fix black video in Chromium-family browsers on NVIDIA (omacom/omarchy#13188)
#
# What it does (machine fix, no sudo needed):
#   Detects an NVIDIA GPU with GSP firmware (Turing/newer, device id >= 0x1e00).
#   If found, appends --disable-accelerated-video-decode to every Chromium-family
#   flags file you already have. Idempotent; backs up each file it touches.
#
# Why: Omarchy points LIBVA_DRIVER_NAME=nvidia at nvidia-vaapi-driver, which only
# supports Firefox. Chromium fails dmabuf import (EGL_BAD_MATCH) and renders
# video black while audio plays. Software decode loses nothing that worked.
#
# Usage:
#   ./apply-nvidia-fix.sh              # detect + fix flags files
#   ./apply-nvidia-fix.sh --dry-run    # show what would happen, change nothing
#   ./apply-nvidia-fix.sh --undo       # remove the flag again
#   ./apply-nvidia-fix.sh --force      # apply even without a detected GSP GPU
#   ./apply-nvidia-fix.sh --repo DIR   # ALSO git-apply nvidia-chromium-fix-13189.patch
#                                      # into an omarchy git checkout at DIR
#
# Exit codes: 0 = applied/ok, 1 = error, 2 = nothing to do (no GPU / no files)

set -euo pipefail

FLAG="--disable-accelerated-video-decode"
UNDO=0
DRY_RUN=0
FORCE=0
REPO_DIR=""

FLAGS_FILES=(
  "$HOME/.config/chromium-flags.conf"
  "$HOME/.config/chrome-flags.conf"
  "$HOME/.config/microsoft-edge-stable-flags.conf"
  "$HOME/.config/brave-flags.conf"
  "$HOME/.config/brave-origin-flags.conf"
)

for arg in "$@"; do
  case "$arg" in
    --undo)    UNDO=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --force)   FORCE=1 ;;
    --repo)    REPO_DIR="__next__" ;;
    *)
      if [[ $REPO_DIR == "__next__" ]]; then
        REPO_DIR="$arg"
      else
        echo "Unknown argument: $arg" >&2
        echo "Usage: $0 [--dry-run] [--undo] [--force] [--repo <omarchy-checkout>]" >&2
        exit 1
      fi
      ;;
  esac
done
[[ $REPO_DIR == "__next__" ]] && { echo "--repo needs a directory argument" >&2; exit 1; }

msg()  { printf '%s\n' "$*"; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# --- Detect NVIDIA GPU with GSP firmware (same rule as omarchy-hw-nvidia-gsp) ---
has_nvidia_gsp() {
  local pci="${OMARCHY_PCI_DEVICES_PATH:-/sys/bus/pci/devices}"
  local device dir
  for dir in "$pci"/*; do
    [[ -d $dir ]] || continue
    [[ $(< "$dir/vendor") == "0x10de" ]] || continue
    [[ $(< "$dir/class") == 0x03* ]] || continue
    device=$(< "$dir/device")
    (( device >= 0x1e00 )) && return 0
  done
  return 1
}

# --- Undo: strip the flag line from every flags file that has it ---
undo_flags() {
  local changed=0 f
  for f in "${FLAGS_FILES[@]}"; do
    [[ -f $f ]] && grep -qxF -- "$FLAG" "$f" || continue
    if (( DRY_RUN )); then
      msg "  [dry-run] would remove $FLAG from $f"
    else
      sed -i "\|^${FLAG}$|d" "$f"
      msg "  removed $FLAG from $f"
    fi
    changed=1
  done
  (( changed )) || msg "  nothing to undo — no flags file contains $FLAG"
}

# --- Apply: append the flag to every existing flags file ---
apply_flags() {
  local changed=0 f backup
  for f in "${FLAGS_FILES[@]}"; do
    [[ -f $f ]] || continue                      # only touch files that exist
    grep -qxF -- "$FLAG" "$f" && continue        # already fixed, skip
    if (( DRY_RUN )); then
      msg "  [dry-run] would append $FLAG to $f"
    else
      backup="$f.bak.$(date +%Y%m%d%H%M%S)"
      cp -p "$f" "$backup"
      printf '%s\n' "$FLAG" >>"$f"
      msg "  fixed $f (backup: $backup)"
    fi
    changed=1
  done
  (( changed )) || msg "  all existing flags files already fixed"
}

msg "== omarchy NVIDIA Chromium video fix (#13188) =="

# --- GPU check (skipped for --undo and --force) ---
if (( UNDO == 0 && FORCE == 0 )); then
  if has_nvidia_gsp; then
    msg "Detected NVIDIA GPU with GSP firmware — fix is needed."
  else
    msg "No NVIDIA GSP GPU detected on this machine."
    msg "Nothing to do (the fix only applies to that hardware). Use --force to override."
    exit 2
  fi
fi

if (( UNDO )); then
  msg "-- undo: removing forced software video decode --"
  undo_flags
else
  msg "-- apply: forcing software video decode in Chromium-family browsers --"
  apply_flags
fi

# --- Optional: apply the full repo patch to a git checkout ---
if [[ -n $REPO_DIR ]]; then
  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  patch_file="$script_dir/nvidia-chromium-fix-13189.patch"
  [[ -f $patch_file ]] || die "patch file not found: $patch_file"
  [[ -d $REPO_DIR/.git ]] || die "not a git checkout: $REPO_DIR"
  msg "-- repo: applying $patch_file to $REPO_DIR --"
  if (( DRY_RUN )); then
    (cd "$REPO_DIR" && git apply --check "$patch_file") \
      && msg "  [dry-run] patch applies cleanly" \
      || die "patch does not apply cleanly to $REPO_DIR"
  else
    (cd "$REPO_DIR" && git apply "$patch_file") && msg "  patch applied" \
      || die "patch failed to apply to $REPO_DIR"
  fi
fi

msg "Done. Restart any running Chromium-family browsers to pick up the change."
