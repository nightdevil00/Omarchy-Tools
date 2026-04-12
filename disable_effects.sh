#!/bin/bash

set -e

OMARCHY_PATH="$HOME/.local/share/omarchy"

disable_blur_opacity() {
  sed -i 's/blur_passes = 3/blur_passes = 0/' "$OMARCHY_PATH/config/hypr/hyprlock.conf"

  cat > "$OMARCHY_PATH/default/hypr/windows.conf" << 'EOF'
# See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
# Hyprland 0.53+ syntax
windowrule = suppress_event maximize, match:class .*

# Fix some dragging issues with XWayland
windowrule = no_focus on, match:class ^$, match:title ^$, match:xwayland 1, match:float 1, match:fullscreen 0, match:pin 0

# App-specific tweaks
source = ~/.local/share/omarchy/default/hypr/apps.conf
EOF

  cat > "$OMARCHY_PATH/default/hypr/apps/terminals.conf" << 'EOF'
# Define terminal tag to style them uniformly
windowrule = tag +terminal, match:class (Alacritty|kitty|com.mitchellh.ghostty)
EOF

  cat > "$OMARCHY_PATH/default/hypr/apps/browser.conf" << 'EOF'
# Browser types
windowrule = tag +chromium-based-browser, match:class ((google-)?[cC]hrom(e|ium)|[bB]rave-browser|[mM]icrosoft-edge|Vivaldi-stable|helium)
windowrule = tag +firefox-based-browser, match:class ([fF]irefox|zen|librewolf)

# Video apps: remove chromium browser tag
windowrule = tag -chromium-based-browser, match:class (chrome-youtube.com__-Default|chrome-app.zoom.us__wc_home-Default)

# Force chromium-based browsers into a tile to deal with --app bug
windowrule = tile on, match:tag chromium-based-browser
EOF

  sed -i '/^# No transparency on media windows$/, /^windowrule = opacity/d' "$OMARCHY_PATH/default/hypr/apps/system.conf"

  sed -i '/^windowrule = tag -default-opacity, match:class steam\.\*$/d' "$OMARCHY_PATH/default/hypr/apps/steam.conf"
  sed -i '/^windowrule = opacity 1 1, match:class steam\.\*$/d' "$OMARCHY_PATH/default/hypr/apps/steam.conf"

  sed -i '/^windowrule = tag -default-opacity, match:class com\.libretro\.RetroArch$/d' "$OMARCHY_PATH/default/hypr/apps/retroarch.conf"
  sed -i '/^windowrule = opacity 1 1, match:class com\.libretro\.RetroArch$/d' "$OMARCHY_PATH/default/hypr/apps/retroarch.conf"

  sed -i '/^windowrule = tag -default-opacity, match:class qemu$/d' "$OMARCHY_PATH/default/hypr/apps/qemu.conf"
  sed -i '/^windowrule = opacity 1 1, match:class qemu$/d' "$OMARCHY_PATH/default/hypr/apps/qemu.conf"

  sed -i '/^windowrule = tag -default-opacity, match:tag pip$/d' "$OMARCHY_PATH/default/hypr/apps/pip.conf"
  sed -i '/^windowrule = opacity 1 1, match:tag pip$/d' "$OMARCHY_PATH/default/hypr/apps/pip.conf"

  sed -i 's/opacity: 0.5;/opacity: 1.0;/g' "$OMARCHY_PATH/config/waybar/style.css"
  sed -i 's/opacity: 0;/opacity: 1.0;/g' "$OMARCHY_PATH/config/waybar/style.css"
}

enable_blur_opacity() {
  sed -i 's/blur_passes = 0/blur_passes = 3/' "$OMARCHY_PATH/config/hypr/hyprlock.conf"

  cat > "$OMARCHY_PATH/default/hypr/windows.conf" << 'EOF'
# See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
# Hyprland 0.53+ syntax
windowrule = suppress_event maximize, match:class .*

# Tag all windows for default opacity (apps can override with -default-opacity tag)
windowrule = tag +default-opacity, match:class .*

# Fix some dragging issues with XWayland
windowrule = no_focus on, match:class ^$, match:title ^$, match:xwayland 1, match:float 1, match:fullscreen 0, match:pin 0

# App-specific tweaks (may remove default-opacity tag)
source = ~/.local/share/omarchy/default/hypr/apps.conf

# Apply default opacity after apps have had a chance to opt out
windowrule = opacity 0.97 0.9, match:tag default-opacity
EOF

  cat > "$OMARCHY_PATH/default/hypr/apps/terminals.conf" << 'EOF'
# Define terminal tag to style them uniformly
windowrule = tag +terminal, match:class (Alacritty|kitty|com.mitchellh.ghostty)
windowrule = tag -default-opacity, match:tag terminal
windowrule = opacity 0.97 0.9, match:tag terminal
EOF

  cat > "$OMARCHY_PATH/default/hypr/apps/browser.conf" << 'EOF'
# Browser types
windowrule = tag +chromium-based-browser, match:class ((google-)?[cC]hrom(e|ium)|[bB]rave-browser|[mM]icrosoft-edge|Vivaldi-stable|helium)
windowrule = tag +firefox-based-browser, match:class ([fF]irefox|zen|librewolf)
windowrule = tag -default-opacity, match:tag chromium-based-browser
windowrule = tag -default-opacity, match:tag firefox-based-browser

# Video apps: remove chromium browser tag so they don't get opacity applied
windowrule = tag -chromium-based-browser, match:class (chrome-youtube.com__-Default|chrome-app.zoom.us__wc_home-Default)
windowrule = tag -default-opacity, match:class (chrome-youtube.com__-Default|chrome-app.zoom.us__wc_home-Default)

# Force chromium-based browsers into a tile to deal with --app bug
windowrule = tile on, match:tag chromium-based-browser

# Only a subtle opacity change, but not for video sites
windowrule = opacity 1.0 0.97, match:tag chromium-based-browser
windowrule = opacity 1.0 0.97, match:tag firefox-based-browser
EOF

  if ! grep -q "# No transparency on media windows" "$OMARCHY_PATH/default/hypr/apps/system.conf"; then
    cat >> "$OMARCHY_PATH/default/hypr/apps/system.conf" << 'EOF'

# No transparency on media windows
windowrule = tag -default-opacity, match:class ^(zoom|vlc|mpv|org.kde.kdenlive|com.obsproject.Studio|com.github.PintaProject.Pinta|imv|org.gnome.NautilusPreviewer)$
windowrule = opacity 1 1, match:class ^(zoom|vlc|mpv|org.kde.kdenlive|com.obsproject.Studio|com.github.PintaProject.Pinta|imv|org.gnome.NautilusPreviewer)$
EOF
  fi

  cat >> "$OMARCHY_PATH/default/hypr/apps/steam.conf" << 'EOF'
windowrule = tag -default-opacity, match:class steam.*
windowrule = opacity 1 1, match:class steam.*
EOF

  cat >> "$OMARCHY_PATH/default/hypr/apps/retroarch.conf" << 'EOF'
windowrule = tag -default-opacity, match:class com.libretro.RetroArch
windowrule = opacity 1 1, match:class com.libretro.RetroArch
EOF

  if ! grep -q "tag -default-opacity" "$OMARCHY_PATH/default/hypr/apps/qemu.conf"; then
    cat >> "$OMARCHY_PATH/default/hypr/apps/qemu.conf" << 'EOF'
windowrule = tag -default-opacity, match:class qemu
windowrule = opacity 1 1, match:class qemu
EOF
  fi

  if ! grep -q "opacity 1 1, match:tag pip" "$OMARCHY_PATH/default/hypr/apps/pip.conf"; then
    sed -i '/^windowrule = border_size 0, match:tag pip$/a windowrule = opacity 1 1, match:tag pip' "$OMARCHY_PATH/default/hypr/apps/pip.conf"
  fi

  sed -i 's/opacity: 1.0;/opacity: 0.5;/g' "$OMARCHY_PATH/config/waybar/style.css"
  sed -i 's/opacity: 1.0;/opacity: 0;/g' "$OMARCHY_PATH/config/waybar/style.css"
}

case "$1" in
  enable)
    enable_blur_opacity
    ;;
  disable)
    disable_blur_opacity
    ;;
  *)
    echo "Usage: $0 {enable|disable}"
    exit 1
    ;;
esac