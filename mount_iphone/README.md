# iPhone Mounter Script for Linux

A simple bash script to easily mount and unmount an iPhone on a Linux system, specifically designed for Arch Linux but adaptable for other distributions.

This script automates the process of mounting your iPhone using `ifuse`, allowing you to access its file system in a file manager like Nautilus.

## Features

*   **Mount & Unmount:** Easily mount and unmount your iPhone.
*   **Dependency Check:** Automatically checks if required tools (`ifuse`, `libimobiledevice`) are installed.
*   **Automatic Dependency Installation:** If dependencies are missing, it offers to install them using `pacman`.
*   **User Guidance:** Provides step-by-step instructions during the mounting process.
*   **Error Handling:** Includes basic troubleshooting advice if mounting fails.

## Dependencies

This script relies on the following packages:
*   `ifuse`
*   `libimobiledevice`
*   `usbmuxd`

The script will attempt to install these for you if you are using an Arch-based Linux distribution. On other systems, you will need to install them manually using your package manager (e.g., `sudo apt install ifuse libimobiledevice-utils usbmuxd` on Debian/Ubuntu).

## Installation

1.  Place the `mount_iphone.sh` script in a convenient directory (e.g., your home directory or `~/.local/bin`).
2.  Make the script executable:
    ```bash
    chmod +x mount_iphone.sh
    ```

## Usage

Make sure you run the script from your terminal.

### To Mount Your iPhone:

1.  Connect your iPhone to your computer via USB.
2.  On your iPhone, you should see a "Trust This Computer" prompt. Tap "Trust" and enter your passcode if prompted.
3.  Run the script:
    ```bash
    ./mount_iphone.sh
    ```
4.  Follow the on-screen prompts. Your iPhone will be mounted in the `~/iphone` directory.

### To Unmount Your iPhone:

1.  Ensure no applications are using files on the mounted iPhone.
2.  Run the script with the `unmount` argument:
    ```bash
    ./mount_iphone.sh unmount
    ```

## Troubleshooting

If you encounter issues with mounting, the script will provide some basic troubleshooting steps. Here are some common solutions:

*   **Reconnect the iPhone:** Unplug the USB cable and plug it back in.
*   **Re-trust the computer:** Sometimes the trust relationship needs to be reset. You might need to go into your iPhone's settings (`Settings > General > Reset > Reset Location & Privacy`) and then reconnect the phone to get the "Trust" prompt again.
*   **Restart `usbmuxd`:** This service is essential for communication with the iPhone. Restart it with:
    ```bash
    sudo systemctl restart usbmuxd
    ```

---
