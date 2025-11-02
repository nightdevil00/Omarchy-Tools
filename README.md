1. setup_kb_backlight_fixed.sh - Allows keyboard backlight to be activated on Macbook Air 2017 (tested) under Omarchy (Arch Linux). You can bind it using bindd = SUPER, B,L, Toogle Keyboard Light, exec, ~/.config/hypr/scripts/setup_kb_backlight_fixed.sh
   
   <img width="293" height="117" alt="image" src="https://github.com/user-attachments/assets/e2300b37-efbd-4c55-9ab3-47c72b586ed7" />
2. The remove_transparency.sh script is a Bash script that modifies Hyprland configuration files to eliminate
  transparency effects. It achieves this by using sed to perform in-place substitutions (sed -i) on specific lines
  within several configuration files.

     The script targets the following files and applies these changes:
      * $HOME/.config/omarchy/current/theme/hyprland.conf: Replaces rgba color definitions for col.active_border and
        col.inactive_border with their rgb equivalents, effectively removing the alpha channel.
      * $HOME/.local/share/omarchy/default/hypr/windows.conf: Modifies windowrule entries to set window opacity to 1.0 1.0
        for all classes.
      * $HOME/.local/share/omarchy/default/hypr/looknfeel.conf: Similar to the theme file, it converts rgba border and
        general color definitions to rgb. It also changes an enabled = true setting to enabled = false.
      * $HOME/.local/share/omarchy/default/hypr/apps/browser.conf: Adjusts windowrule entries for chromium-based-browser
        and firefox-based-browser tags to set their opacity to 1 1.
   
     Each modification is conditional on the existence of the target file, preventing errors if a configuration file is
     not found.
3.  Description for `install_gaming_dependencies.sh`:
  This is a bash script that automates the installation of gaming-related software packages. It reads a list of package
  names from the list.txt file and then uses the yay AUR helper to install them. The script is configured to only
  install packages that are not already present (--needed) and to proceed without requiring user confirmation
  (--noconfirm).

  Description for `list.txt`:
  This is a plain text file containing a list of software package names, with each package listed on a new line. It
  acts as a manifest for the install_gaming_dependencies.sh script, providing the exact names of all the gaming
  dependencies to be installed. The list includes a variety of packages such as wine, steam, lutris, goverlay, and
  numerous 32-bit and 64-bit libraries essential for graphics, audio, and general system compatibility in a gaming
  environment.

  4. The sudo.sh script is a Bash script that modifies the system's /etc/sudoers file. Its primary function is to grant
  the user who executes the script passwordless sudo access specifically for running the pacman package manager
  command.

  Technically, the script performs the following steps:
   -. Backup: It creates a backup of the existing /etc/sudoers file, saving it as /etc/sudoers.bak.
   -. Conditional Modification: It checks if the line "$USER ALL=(ALL) NOPASSWD: /usr/bin/pacman" already exists in
      /etc/sudoers. If this specific entry is not found, the script appends it to the file. This configuration allows the
      user who runs the script to execute pacman commands with sudo without being prompted for a password.
   -. Syntax Validation: After potentially modifying the sudoers file, it runs sudo visudo -c to perform a syntax check.
      This is a critical step to ensure that the changes haven't introduced any errors that could break sudo
      functionality.
  -. Rollback on Error: If the visudo -c command indicates a syntax error, the script automatically restores the
      /etc/sudoers file from the previously created backup (/etc/sudoers.bak), preventing potential system lockout or
      sudo malfunctions.
      
   5. Install AUR Pkgs from GITHUB Mirror: -Download the script and make it executable with chmod +x
   Navigate to your home directory or where the script is located.
   Run the script with the name of the package you want to install.
  For example, to install the package btop: ./aur-install.sh btopp .The script will then download, build, and install the package. 
  Since package installation requires root privileges, you will be prompted to enter your sudo password during the final step.

 6. Set editor - allows for easier setting up the default editor for known text file format

<img width="643" height="429" alt="image" src="https://github.com/user-attachments/assets/23499507-9350-4091-a8b4-d91cbbb7bc91" />

