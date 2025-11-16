# System Update Script

This script automates the process of updating both official Arch Linux packages (using `pacman`) and AUR packages (using `yay`).

## How it works:

1.  **Temporarily disables `[omarchy]` repository:** It comments out the `[omarchy]` repository in `/etc/pacman.conf` to prevent issues during the update process.
2.  **Updates system packages:** Runs `sudo pacman -Syu --noconfirm` to update official packages.
3.  **Updates AUR packages:** Runs `yay -Syu --noconfirm` to update packages from the Arch User Repository.
4.  **Re-enables `[omarchy]` repository:** Uncomments the `[omarchy]` repository in `/etc/pacman.conf`.

## Usage:

To run the script, execute it from your terminal:

```bash
./update-system.sh
```

**Note:** This script requires `sudo` privileges for `pacman` operations and assumes `yay` is installed for AUR package management.