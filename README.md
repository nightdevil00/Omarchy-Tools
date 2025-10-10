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
