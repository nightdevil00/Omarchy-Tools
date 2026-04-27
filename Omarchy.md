# Omarchy: Complete System Explanation

## Table of Contents
1. [Overview](#overview)
2. [Directory Structure](#directory-structure)
3. [Installation Process](#installation-process)
4. [Configuration System](#configuration-system)
5. [Theme System](#theme-system)
6. [Autostart Mechanism](#autostart-mechanism)
7. [Bin Scripts Reference](#bin-scripts-reference)
8. [Applications Installed](#applications-installed)
9. [Key Bindings](#key-bindings)
10. [Hooks System](#hooks-system)
11. [Migration System](#migration-system)
12. [Package Management](#package-management)
13. [Hardware Support](#hardware-support)

---

## Overview

**Omarchy** is a beautiful, modern, and opinionated Linux distribution by DHH (David Heinemeier Hansson). It's built on top of Arch Linux and uses the Hyprland Wayland compositor as its window manager. Version: **3.6.1**

### Core Philosophy
- **Opinionated defaults**: Sensible defaults for developers and power users
- **Unified theming**: Single `colors.toml` drives colors across all applications
- **Toggle-based configuration**: Features can be enabled/disabled via flag files
- **Template-driven configs**: `{{ variable }}` placeholders in templates auto-fill with theme colors

### Key Technologies
- **Window Manager**: Hyprland (Wayland)
- **Status Bar**: Waybar
- **Launcher**: Walker + Elephant
- **Notifications**: Mako
- **Terminal**: Alacritty (default), with Ghostty and Kitty support
- **Shell**: Bash with custom functions
- **Editor**: Neovim with LazyVim distribution
- **Bootloader**: Limine (primary)
- **Login Manager**:SDDM set to autologin
- **Audio**: PipeWire + WirePlumber
- **Display Server**: Wayland (no X11 except XWayland for compatibility)

---

## Directory Structure

```
Omarchy Installation Paths:
├── ~/.local/share/omarchy/          # Main installation (OMARCHY_PATH)
│   ├── bin/                        # All omarchy-* commands (100+ scripts)
│   ├── config/                     # Default configs copied to ~/.config
│   ├── default/                    # System defaults and templates
│   │   ├── themed/                # Theme templates (*.tpl files)
│   │   ├── hypr/                  # Hyprland default configs
│   │   ├── waybar/                # Waybar defaults + indicators
│   │   ├── walker/                # Walker launcher themes
│   │   ├── mako/                  # Mako notification base config
│   │   ├── plymouth/              # Boot splash theme
│   │   ├── limine/                # Bootloader config
│   │   ├── bash/                  # Bash configuration
│   │   ├── sddm/                  # SDDM login theme
│   │   └── ...
│   ├── themes/                     # Built-in themes (14+ themes)
│   │   ├── tokyo-night/
│   │   ├── nord/
│   │   ├── vantablack/
│   │   ├── white/
│   │   └── ...
│   ├── migrations/                 # Install-time migrations
│   ├── applications/               # Desktop entries
│   ├── install/                    # Installation scripts
│   │   ├── helpers/               # Helper functions
│   │   ├── preflight/             # Pre-install checks
│   │   ├── packaging/             # Package installation
│   │   ├── config/                # Configuration setup
│   │   ├── login/                 # Bootloader setup
│   │   └── post-install/          # Post-install tasks
│   └── version                     # Version file (3.6.1)
│
├── ~/.config/omarchy/              # User omarchy configuration
│   ├── current/                    # Active theme files
│   │   ├── theme/                 # Generated theme configs
│   │   │   ├── colors.toml       # Active theme colors
│   │   │   ├── waybar.css        # Theme-generated CSS
│   │   │   ├── hyprland.conf    # Theme variables
│   │   │   ├── mako.ini         # Notification colors
│   │   │   ├── swayosd.css      # OSD styling
│   │   │   ├── walker.css        # Launcher styling
│   │   │   ├── kitty.conf       # Terminal colors
│   │   │   ├── alacritty.toml   # Terminal colors
│   │   │   ├── ghostty.conf     # Terminal colors
│   │   │   ├── obsidian.css     # Obsidian theme
│   │   │   ├── vscode.json      # VSCode theme
│   │   │   ├── chromium.theme   # Browser theme
│   │   │   ├── keyboard.rgb     # Keyboard RGB
│   │   │   ├── btop.theme       # System monitor theme
│   │   │   ├── backgrounds/     # Wallpaper images
│   │   │   └── background       # Symlink to current wallpaper
│   │   └── theme.name           # Current theme name
│   ├── themes/                    # User-installed themes
│   ├── themed/                    # User template overrides
│   ├── hooks/                     # Custom hook scripts
│   │   ├── theme-set             # Main theme-set hook
│   │   ├── theme-set.d/          # Theme-set hook scripts
│   │   └── *.sample              # Sample hooks
│   ├── branding/                  # Custom branding
│   └── extensions/               # Menu extensions
│
├── ~/.local/state/omarchy/        # Runtime state
│   ├── migrations/                # Completed migration tracking
│   │   ├── *.sh                  # Migration scripts run
│   │   └── skipped/              # Skipped migrations
│   └── toggles/                  # Toggle flag files
│       └── hypr/                 # Hyprland toggle flags
│           ├── flags.conf
│           ├── internal-monitor-disable.conf
│           ├── window-no-gaps.conf
│           └── single-window-aspect-ratio.conf
│
└── ~/.config/                     # Standard Linux config directory
    ├── hypr/                      # Hyprland configuration
    │   ├── hyprland.conf         # Main config (sources defaults + theme)
    │   ├── hypridle.conf         # Idle management
    │   ├── hyprlock.conf         # Lock screen
    │   ├── hyprsunset.conf       # Night light
    │   ├── autostart.conf        # User autostart overrides
    │   ├── bindings.conf         # User keybinding overrides
    │   ├── looknfeel.conf        # User appearance overrides
    │   ├── input.conf            # User input overrides
    │   ├── monitors.conf         # Monitor layout (nwg-displays)
    │   └── workspaces.conf       # Workspace assignments
    ├── waybar/                   # Waybar config + theme CSS
    ├── walker/                   # Walker launcher config
    ├── mako/ -> omarchy/current/theme/mako.ini (symlink)
    ├── swayosd/                  # OSD config + theme CSS
    ├── tmux/                     # Tmux config
    ├── nvim/                     # Neovim config (LazyVim)
    ├── starship.toml             # Starship prompt
    ├── uwsm/                     # UWSM session manager
    ├── systemd/user/             # User systemd services
    │   ├── omarchy-battery-monitor.service
    │   ├── omarchy-battery-monitor.timer
    │   ├── elephant.service
    │   └── app-walker@autostart.service
    ├── autostart/                # XDG autostart entries
    │   └── walker.desktop
    └── omarchy/                  # (see above)
```

---

## Installation Process

### 1. Boot/Install Script (`boot.sh`)

The `boot.sh` script is designed for curl-pipe installation:

```bash
curl -fsSL https://omarchy.org/install.sh | sh
```

**What it does:**
1. Displays ANSI art logo
2. Sets the git branch (`OMARCHY_REF` env var, defaults to `master`)
3. Configures the package mirror based on branch:
   - `master` → `stable-mirror.omarchy.org`
   - `rc` → `rc-mirror.omarchy.org`
   - `dev` → `edge-mirror.omarchy.org`
4. Installs `git` if not present
5. Clones the repository to `~/.local/share/omarchy/`
6. Checks out the specified branch
7. Sources `install.sh`

### 2. Main Install Script (`install.sh`)

**Location**: `~/.local/share/omarchy/install.sh`

Sources these component scripts in order:

```bash
source "$OMARCHY_INSTALL/helpers/all.sh"      # Logging, errors, presentation
source "$OMARCHY_INSTALL/preflight/all.sh"    # Pre-install checks
source "$OMARCHY_INSTALL/packaging/all.sh"    # Package installation
source "$OMARCHY_INSTALL/config/all.sh"        # Configuration setup
source "$OMARCHY_INSTALL/login/all.sh"         # Bootloader setup
source "$OMARCHY_INSTALL/post-install/all.sh"   # Cleanup tasks
```

### 3. Preflight Checks (`preflight/all.sh`)

Runs these checks before installation:

| Script | Purpose |
|--------|---------|
| `guard.sh` | Ensures system is ready for omarchy |
| `begin.sh` | Initial setup messages |
| `show-env.sh` | Displays environment information |
| `pacman.sh` | Configures pacman with omarchy mirrors |
| `migrations.sh` | Runs pending migrations |
| `first-run-mode.sh` | Sets up first-run detection |
| `disable-mkinitcpio.sh` | Disables mkinitcpio if using limine |

### 4. Package Installation (`packaging/all.sh`)

Installs packages in this order:

| Script | What it installs |
|--------|-----------------|
| `base.sh` | Core omarchy packages (hyprland, waybar, terminal, etc.) |
| `fonts.sh` | Omarchy icon font + nerd fonts |
| `nvim.sh` | Neovim with LazyVim distribution |
| `icons.sh` | Application icons to `~/.local/share/applications/icons/` |
| `webapps.sh` | 15 web applications (HEY, Basecamp, Discord, etc.) |
| `tuis.sh` | TUI applications (Disk Usage, Docker/lazydocker) |
| `npx.sh` | NPX wrappers (opencode, codex, gemini, copilot, etc.) |
| `asus-rog.sh` | ASUS ROG laptop support (if detected) |
| `framework16.sh` | Framework 16 keyboard support (if detected) |
| `surface.sh` | Microsoft Surface support (if detected) |

### 5. Configuration (`config/all.sh`)

Sets up all system configuration:

**Core Configuration:**
- `config.sh` - Copy default configs to `~/.config/`
- `theme.sh` - Set initial theme
- `branding.sh` - Set omarchy branding
- `git.sh` - Git configuration
- `gpg.sh` - GPG setup
- `timezones.sh` - Timezone configuration

**System Tweaks:**
- `increase-sudo-tries.sh` - More sudo attempts
- `increase-lockout-limit.sh` - Reduce lockout time
- `ssh-flakiness.sh` - SSH connection tuning
- `increase-file-watchers.sh` - Increase inotify limits
- `detect-keyboard-layout.sh` - Auto-detect keyboard
- `xcompose.sh` - XCompose for custom key combos
- `mise-work.sh` - Mise version manager setup
- `docker.sh` - Docker configuration
- `mimetypes.sh` - File type associations
- `user-dirs.sh` - User directory setup
- `fast-shutdown.sh` - Faster system shutdown
- `kernel-modules-hook.sh` - Kernel module management
- `powerprofilesctl-rules.sh` - Power profile rules
- `wifi-powersave-rules.sh` - WiFi power saving
- `omarchy-toggles.sh` - Initialize toggle system

**Hardware Configuration:**
- Network, Bluetooth, Printers, USB autosuspend
- Intel: video acceleration, thermald, lpmd, IPU7 camera, PTL kernel
- ASUS: display, touchpad, audio, microphone fixes
- Framework: audio input, QMK HID
- Apple: SPI keyboard, suspend, T2 chip
- Surface, Dell XPS, and more

### 6. Login Setup (`login/all.sh`)

Configures the display manager/bootloader:

| Script | Purpose |
|--------|---------|
| `plymouth.sh` | Boot splash screen with theme colors |
| `default-keyring.sh` | GNOME keyring setup |
| `sddm.sh` | SDDM login manager |
| `limine-snapper.sh` | Limine bootloader + snapper snapshots |

### 7. Post-Install (`post-install/all.sh`)

Final cleanup tasks:

| Script | Purpose |
|--------|---------|
| `hibernation.sh` | Configure hibernation support |
| `pacman.sh` | Final pacman configuration |
| `allow-reboot.sh` | Allow reboot without password |
| `finished.sh` | Display completion message |

---

## Configuration System

Omarchy uses a **layered configuration system** where defaults are sourced first, then user overrides, then theme variables, and finally dynamic toggles.

### Hyprland Config Loading Order

The main `~/.config/hypr/hyprland.conf` loads configs in this order:

```
1. ~/.local/share/omarchy/default/hypr/autostart.conf    # Services to start
2. ~/.local/share/omarchy/default/hypr/envs.conf        # Environment variables
3. ~/.local/share/omarchy/default/hypr/looknfeel.conf    # Appearance (gaps, borders, animations)
4. ~/.local/share/omarchy/default/hypr/input.conf        # Input device config
5. ~/.local/share/omarchy/default/hypr/windows.conf     # Window rules
6. ~/.config/hypr/bindings.conf                          # User keybinding overrides
7. ~/.local/share/omarchy/default/hypr/bindings/*.conf   # Default keybindings
8. ~/.config/hypr/looknfeel.conf                         # User appearance overrides
9. ~/.config/hypr/input.conf                             # User input overrides
10. ~/.config/hypr/monitors.conf                         # Monitor layout
11. ~/.config/hypr/workspaces.conf                       # Workspace assignments
12. ~/.config/omarchy/current/theme/hyprland.conf       # Theme variables
13. ~/.local/state/omarchy/toggles/hypr/*.conf          # Dynamic toggle flags
```

### Key Configuration Files

#### 1. Environment Variables (`default/hypr/envs.conf`)

Forces Wayland for all applications:

```bash
env = GDK_BACKEND,wayland,x11,*        # GTK apps
env = QT_QPA_PLATFORM,wayland;xcb     # Qt apps
env = SDL_VIDEODRIVER,wayland,x11      # SDL apps
env = MOZ_ENABLE_WAYLAND,1             # Firefox
env = ELECTRON_OZONE_PLATFORM_HINT,wayland  # Electron apps
env = XDG_SESSION_TYPE,wayland
env = XDG_CURRENT_DESKTOP,Hyprland
```

Sets cursor size and XCompose:

```bash
env = XCURSOR_SIZE,24
env = HYPRCURSOR_SIZE,24
env = XCOMPOSEFILE,~/.XCompose
```

#### 2. Look & Feel (`default/hypr/looknfeel.conf`)

**Window Gaps and Borders:**
```bash
general {
    gaps_in = 5          # Inner gaps between windows
    gaps_out = 10         # Outer gaps to screen edge
    border_size = 2        # Window border width
}
```

**Active/Inactive Border Colors:**
```bash
$activeBorderColor = rgba(33ccffee) rgba(00ff99ee) 45deg
$inactiveBorderColor = rgba(595959aa)

general {
    col.active_border = $activeBorderColor
    col.inactive_border = $inactiveBorderColor
}
```

**Blur and Shadows:**
```bash
decoration {
    rounding = 0         # Window corner rounding
    shadow {
        enabled = true
        range = 2
        render_power = 3
    }
    blur {
        enabled = true
        size = 2
        passes = 2
        brightness = 0.60
        contrast = 0.75
    }
}
```

**Animations (Bezier curves):**
```bash
animations {
    bezier = easeOutQuint,0.23,1,0.32,1
    animation = windows, 1, 3.79, easeOutQuint
    animation = fadeIn, 1, 1.73, almostLinear
    # ... more animations
}
```

**Layout:**
```bash
general { layout = dwindle }  # or "scrolling" for niri-like
dwindle {
    pseudotile = true
    preserve_split = true
    force_split = 2        # Always split on right
}
```

#### 3. Input Configuration (`default/hypr/input.conf`)

```bash
input {
    kb_layout = us
    kb_options = compose:caps    # Caps lock = compose key
    follow_mouse = 1
    sensitivity = 0
    touchpad {
        natural_scroll = false
    }
    accel_profile = []
}
```

#### 4. Window Rules (`default/hypr/windows.conf`)

Tags all windows with `default-opacity`, applies transparency:

```bash
windowrulev2 = tag, class:(.*), tag:default-opacity
windowrulev2 = opacity 0.97 0.9, tag:default-opacity
```

Sources application-specific configs:

```bash
source = ~/.local/share/omarchy/default/hypr/apps/*.conf
```

#### 5. Waybar Configuration (`config/waybar/`)

**Main Config** (`config.jsonc`):
- Position: top, height 26px
- Left: Omarchy menu button, workspaces (1-10)
- Center: Clock, update indicator, voxtype indicator, screen recording indicator
- Right: Tray, Bluetooth, Network, Audio, CPU, Battery

**Theme CSS** (`style.css`):
```css
@import url("~/.config/omarchy/current/theme/waybar.css");

* {
    border: none;
    border-radius: 0;
    font-family: "JetBrainsMono Nerd Font";
    font-size: 12px;
}
```

#### 6. Mako Configuration (`default/mako/core.ini`)

```ini
[config]
max-visible = 5
default-timeout = 5000
width = 420
height = 0
outer-margin = 20 20 20 20
padding = 10 15
border-size = 2
font = sans-serif 14

[urgency=critical]
timeout = 0
layer = overlay
```

App-specific rules hide Spotify notifications and do-not-disturb mode notifications.

---

## Theme System

The theme system is one of Omarchy's most powerful features. A single `colors.toml` file drives colors across all applications.

### Theme File Structure

Each theme (in `themes/<theme-name>/`) contains:

| File | Purpose | Required |
|------|---------|----------|
| `colors.toml` | Color definitions (accent, background, foreground, color0-15) | ✅ Yes |
| `vscode.json` | VS Code theme extension name | No |
| `neovim.lua` | LazyVim/Neovim configuration | No |
| `btop.theme` | btop system monitor colors | No |
| `icons.theme` | GNOME icon theme name | No |
| `chromium.theme` | Browser theme RGB values | No |
| `keyboard.rgb` | Keyboard RGB lighting config | No |
| `light.mode` | Marks theme as light mode | No |
| `preview.png` | Theme preview image | No |
| `backgrounds/` | Wallpaper images (0-3*.jpg/png) | No |
| `waybar.css` | Waybar-specific CSS overrides | No |
| `hyprland.conf` | Hyprland-specific config overrides | No |

### colors.toml Format

Example from Tokyo Night theme:

```toml
# UI Colors
accent = "#7aa2f7"         # Main accent (borders, highlights)
cursor = "#c0caf5"         # Terminal cursor
foreground = "#a9b1d6"     # Main text color
background = "#1a1b26"     # Main background
selection_foreground = "#c0caf5"
selection_background = "#7aa2f7"

# ANSI Normal Colors (color0-7)
color0 = "#32344a"   # Black
color1 = "#f7768e"   # Red
color2 = "#9ece6a"   # Green
color3 = "#e0af68"   # Yellow
color4 = "#7aa2f7"   # Blue
color5 = "#ad8ee6"   # Magenta
color6 = "#449dab"   # Cyan
color7 = "#787c99"   # White

# ANSI Bright Colors (color8-15)
color8 = "#444b6a"
color9 = "#ff7a93"
color10 = "#b9f27c"
color11 = "#ff9e64"
color12 = "#7da6ff"
color13 = "#bb9af7"
color14 = "#0db9d7"
color15 = "#acb0d0"
```

### Built-in Themes

| Theme | Background | Accent | Light Mode |
|-------|------------|--------|------------|
| tokyo-night | `#1a1b26` (dark blue-black) | `#7aa2f7` (purple) | No |
| nord | `#2e3440` (cold blue-gray) | `#81a1c1` (light blue) | No |
| vantablack | `#000000` (pure black) | `#8d8d8d` (gray) | No |
| white | `#ffffff` (pure white) | `#6e6e6e` (gray) | Yes |
| rose-pine | `#faf4ed` (warm cream) | `#56949f` (muted blue) | Yes |
| flexoki-light | `#f8f5f2` (warm white) | `#797564` (olive) | Yes |
| everforest | `#2d353b` (dark green-gray) | `#a7c080` (green) | No |
| catppuccin | `#1e1e2e` (dark purple) | `#89b4fa` (blue) | No |
| kanagawa | `#1f1f28` (dark blue) | `#7e99a0` (muted teal) | No |
| miasma | `#1f1d2e` (dark purple) | `#cba6f7` (mauve) | No |
| ristretto | `#2a2a2a` (dark gray) | `#d4a373` (brown) | No |
| retro-82 | `#0f0f0f` (near black) | `#00ff00` (green) | No |
| osaka-jade | `#0f1419` (dark) | `#81c8be` (jade) | No |
| matte-black | `#1a1a1a` (matte black) | `#c9c5b8` (off-white) | No |
| hackerman | `#0a0a0a` (matrix black) | `#00ff41` (matrix green) | No |

### Template System

Templates in `default/themed/*.tpl` use `{{ variable }}` placeholders that get replaced with values from `colors.toml`.

**Available Template Variables:**

| Variable | Example Value | Description |
|----------|---------------|-------------|
| `{{ accent }}` | `#7aa2f7` | Full hex color |
| `{{ accent_strip }}` | `7aa2f7` | Hex without # |
| `{{ accent_rgb }}` | `122,162,247` | Decimal RGB |
| `{{ background }}` | `#1a1b26` | Background color |
| `{{ foreground }}` | `#a9b1d6` | Text color |
| `{{ cursor }}` | `#c0caf5` | Cursor color |
| `{{ color0 }}` through `{{ color15 }}` | `#32344a` | ANSI colors |
| `{{ selection_background }}` | `#7aa2f7` | Selection background |
| `{{ selection_foreground }}` | `#c0caf5` | Selection text |

**Example Template** (`default/themed/waybar.css.tpl`):
```css
@define-color foreground {{ foreground }};
@define-color background {{ background }};
```

**Example Template** (`default/themed/hyprland.conf.tpl`):
```bash
$activeBorderColor = rgb({{ accent_strip }})

general {
    col.active_border = $activeBorderColor
}

group {
    col.border_active = $activeBorderColor
}
```

### How Theme Setting Works

When you run `omarchy-theme-set <theme-name>`:

1. **Clean next-theme directory**: `rm -rf ~/.config/omarchy/current/next-theme`

2. **Copy official theme**: Copies from `~/.local/share/omarchy/themes/<name>/`

3. **Overlay user customizations**: Copies from `~/.config/omarchy/themes/<name>/` (overwrites official)

4. **Generate templates**: `omarchy-theme-set-templates` processes all `*.tpl` files:
   - Reads `colors.toml` to build sed replacement script
   - Processes `default/themed/*.tpl` and `~/.config/omarchy/themed/*.tpl`
   - Replaces `{{ variable }}`, `{{ variable_strip }}`, `{{ variable_rgb }}`
   - Outputs to `next-theme/` directory

5. **Atomic swap**: `mv next-theme current/theme`

6. **Store theme name**: Writes to `~/.config/omarchy/current/theme.name`

7. **Set background**: Cycles to next background image

8. **Restart components**:
   - Waybar, SwayOSD, Terminal (Alacritty/Kitty/Ghostty)
   - Hyprland (reload config), btop, opencode, mako

9. **Update app-specific themes**:
   - GNOME theme (`omarchy-theme-set-gnome`)
   - Chromium/Brave theme (`omarchy-theme-set-browser`)
   - VS Code/VSCodium/Cursor (`omarchy-theme-set-vscode`)
   - Obsidian vaults (`omarchy-theme-set-obsidian`)
   - Keyboard RGB (`omarchy-theme-set-keyboard`)

10. **Call hooks**: Runs `~/.config/omarchy/hooks/theme-set` which calls scripts in `theme-set.d/`

### Theme Hook System

Located at `~/.config/omarchy/hooks/theme-set`:

The main hook script:
1. Extracts all colors from `colors.toml`
2. Converts hex to RGB for applications that need it
3. Exports all color variables
4. Runs all executable scripts in `theme-set.d/*.sh`

**Hook Scripts in `theme-set.d/`:**

| Script | Purpose |
|--------|---------|
| `00-fish.sh` | Update fish shell colors |
| `00-fzf.sh` | Update fzf colors |
| `10-gtk.sh` | Update GTK theme |
| `10-qt6ct.sh` | Update Qt theme |
| `10-spotify.sh` | Update Spotify theme |
| `10-superfile.sh` | Update superfile file manager |
| `10-vicinae.sh` | Update vicinae colors |
| `15-typora.sh` | Update Typora theme |
| `20-nwg-dock-hyprland.sh` | Update nwg-dock |
| `20-zed.sh` | Update Zed editor theme |
| `25-swaync.sh` | Update SwayNC notifications |
| `26-foot-live-colors.sh` | Update foot terminal |
| `30-cursor.sh` | Update Cursor editor |
| `30-vscode.sh` | Update VS Code (redundant with main) |
| `30-windsurf.sh` | Update Windsurf editor |
| `35-obsidian-terminal.sh` | Update Obsidian terminal |
| `40-cava.sh` | Update CAVA visualizer |
| `40-firefox.sh` | Update Firefox theme |
| `40-qutebrowser.sh` | Update qutebrowser |
| `40-steam.sh` | Update Steam theme |
| `40-zen.sh` | Update Zen browser |
| `50-cliamp.sh` | Update Cliamp music player |
| `50-heroic.sh` | Update Heroic Games Launcher |

### Keyboard RGB Theming

For supported keyboards (ASUS ROG, Framework 16):

**ASUS ROG** (`omarchy-theme-set-keyboard-asus-rog`):
- Uses `asusctl` to set keyboard colors
- Reads `keyboard.rgb` file from theme

**Framework 16** (`omarchy-theme-set-keyboard-f16`):
- Uses `qmk_hid` via Python
- Converts RGB to HSV for QMK firmware
- Sets per-layer colors

---

## Autostart Mechanism

Omarchy uses multiple autostart mechanisms to launch applications and services.

### 1. Hyprland exec-once (Primary Method)

Location: `~/.local/share/omarchy/default/hypr/autostart.conf`

```
exec-once = uwsm-app -- hypridle           # Idle management
exec-once = uwsm-app -- mako              # Notifications
exec-once = uwsm-app -- waybar            # Status bar (if toggle allows)
exec-once = uwsm-app -- fcitx5            # Input method
exec-once = uwsm-app -- swaybg            # Wallpaper
exec-once = uwsm-app -- swayosd-server   # OSD
exec-once = /usr/lib/polkit-gnome/...     # Auth agent
exec-once = omarchy-cmd-first-run         # First-run setup
exec-once = omarchy-powerprofiles-init    # Power profile
exec-once = omarchy-hyprland-monitor-watch # Monitor hotplug
```

The `uwsm-app` wrapper launches apps with proper environment variables for Wayland sessions.

### 2. Systemd User Services

**Enabled Services:**

| Service | Type | Purpose |
|---------|------|---------|
| `elephant.service` | Simple | Elephant launcher daemon (restart on failure) |
| `omarchy-battery-monitor.timer` | Timer | Runs battery check every 30 seconds |
| `app-walker@autostart.service` | App | Walker launcher service |

**Service Files:**

`elephant.service`:
```ini
[Unit]
Description=Elephant
After=graphical-session.target

[Service]
Type=simple
ExecStart=elephant
Restart=on-failure

[Install]
WantedBy=graphical-session.target
```

`omarchy-battery-monitor.timer`:
```ini
[Unit]
Description=Omarchy Battery Monitor Timer

[Timer]
OnBootSec=1min
OnUnitActiveSec=30sec
AccuracySec=10sec

[Install]
WantedBy=timers.target
```

`omarchy-recover-internal-monitor.service`:
```ini
[Unit]
Description=Recover internal monitor toggle
Before=graphical-session-pre.target
ConditionPathExists=%h/.local/state/omarchy/toggles/hypr/internal-monitor-disable.conf

[Service]
Type=oneshot
ExecStart=%h/.local/share/omarchy/bin/omarchy-hw-recover-internal-monitor
```

### 3. XDG Autostart

Location: `~/.config/autostart/`

| Desktop File | Application | Status |
|-------------|-------------|--------|
| `walker.desktop` | `walker --gapplication-service` | Active |
| `org.fcitx.Fcitx5.desktop` | Fcitx5 | Disabled (started by Hyprland) |

### 4. First-Run Script (`omarchy-cmd-first-run`)

Runs once after first login, executes scripts from `~/.local/share/omarchy/install/first-run/`:

| Script | Purpose |
|--------|---------|
| `battery-monitor.sh` | Enables battery monitoring timer |
| `recover-internal-monitor.sh` | Sets up monitor recovery |
| `cleanup-reboot-sudoers.sh` | Removes temporary sudoers entries |
| `firewall.sh` | Configures UFW firewall |
| `dns-resolver.sh` | Sets up DNS resolution |
| `gnome-theme.sh` | Applies GNOME theme settings |
| `elephant.sh` | Enables elephant service |
| `welcome.sh` | Shows welcome message |
| `wifi.sh` | Sets up WiFi |

---

## Bin Scripts Reference

All omarchy commands start with `omarchy-`. Here's the complete reference organized by prefix.

### Naming Convention (from AGENTS.md)

| Prefix | Purpose |
|--------|---------|
| `cmd-` | Check if commands exist, misc utilities |
| `pkg-` | Package management helpers |
| `hw-` | Hardware detection (exit codes for conditionals) |
| `refresh-` | Copy default config to user's `~/.config/` |
| `restart-` | Restart a component |
| `launch-` | Open applications |
| `install-` | Install optional software |
| `setup-` | Interactive setup wizards |
| `toggle-` | Toggle features on/off |
| `theme-` | Theme management |
| `update-` | Update components |

### Battery Management (`battery-*`)

| Script | Purpose | Returns/Does |
|--------|---------|----------------|
| `omarchy-ac-present` | Check AC power | Exit 0 if connected |
| `omarchy-battery-capacity` | Get battery Wh | Integer (e.g., 50) |
| `omarchy-battery-monitor` | Monitor battery (for timer) | Notifications at <10% |
| `omarchy-battery-present` | Check battery exists | Exit 0 if present |
| `omarchy-battery-remaining` | Get battery % | Integer (e.g., 85) |
| `omarchy-battery-remaining-time` | Get time remaining | String (e.g., "2h 30m") |
| `omarchy-battery-status` | Full status string | "Battery 85% · 2h 30m left · ↓ 12W / 50Wh" |

### Brightness Control (`brightness-*`)

| Script | Purpose | Commands Used |
|--------|---------|---------------|
| `omarchy-brightness-display` | Adjust display brightness | `brightnessctl`, `swayosd-client` |
| `omarchy-brightness-display-apple` | Apple Studio/XDR display | `asdcontrol`, `sudo` |
| `omarchy-brightness-keyboard` | Keyboard backlight | `brightnessctl`, `swayosd-client` |

### Version/Channel Management

| Script | Purpose |
|--------|---------|
| `omarchy-branch-set [master\|rc\|dev]` | Set git branch |
| `omarchy-channel-set [stable\|rc\|edge\|dev]` | Set package channel + branch |
| `omarchy-version` | Display current version (3.6.1) |
| `omarchy-version-branch` | Display current git branch |
| `omarchy-version-channel` | Display current channel |
| `omarchy-version-pkgs` | Date of last package upgrade |

### Command Utilities (`cmd-*`)

| Script | Purpose |
|--------|---------|
| `omarchy-cmd-audio-switch` | Switch audio output (Super+AudioSwitch) |
| `omarchy-cmd-first-run` | Complete first-run tasks |
| `omarchy-cmd-mic-mute` | Toggle microphone (with hardware LED support) |
| `omarchy-cmd-mic-mute-thinkpad` | ThinkPad mic mute with LED |
| `omarchy-cmd-mic-mute-xps` | Dell XPS mic mute with ALSA |
| `omarchy-cmd-missing cmd1 cmd2` | Return true if any missing |
| `omarchy-cmd-present cmd1 cmd2` | Return true if all present |
| `omarchy-cmd-screensaver` | Run TTE screensaver |
| `omarchy-cmd-screenshot [mode]` | Take screenshot (region/window/full) |
| `omarchy-cmd-screenrecord [options]` | Record screen with audio/webcam |
| `omarchy-cmd-share [type]` | Share via LocalSend |
| `omarchy-cmd-terminal-cwd` | Get terminal working directory |

### Configuration Refresh (`refresh-*`)

| Script | Purpose |
|--------|---------|
| `omarchy-refresh-config <path>` | Copy default config to `~/.config/` |
| `omarchy-refresh-applications` | Reinstall all .desktop files |
| `omarchy-refresh-chromium` | Refresh Chromium flags |
| `omarchy-refresh-fastfetch` | Refresh fastfetch config |
| `omarchy-refresh-hypridle` | Refresh hypridle + restart |
| `omarchy-refresh-hyprland` | Refresh all Hyprland configs |
| `omarchy-refresh-hyprlock` | Refresh hyprlock config |
| `omarchy-refresh-hyprsunset` | Refresh hyprsunset + restart |
| `omarchy-refresh-limine` | Refresh Limine + rebuild |
| `omarchy-refresh-pacman [channel]` | Reset pacman config |
| `omarchy-refresh-plymouth` | Refresh Plymouth + initramfs |
| `omarchy-refresh-sddm` | Refresh SDDM theme |
| `omarchy-refresh-swayosd` | Refresh SwayOSD + restart |
| `omarchy-refresh-tmux` | Refresh tmux + reload |
| `omarchy-refresh-walker` | Refresh Walker + restart |
| `omarchy-refresh-waybar` | Refresh Waybar + restart |

### Hardware Detection (`hw-*`)

These scripts return exit codes for use in conditionals:

| Script | Detects |
|--------|---------|
| `omarchy-hw-asus-expertbook-b9406` | ASUS ExpertBook B9406 (Intel PTL) |
| `omarchy-hw-asus-rog` | ASUS ROG machines |
| `omarchy-hw-dell-xps-oled` | Dell XPS with LG OLED panel |
| `omarchy-hw-external-monitors` | External monitor connected |
| `omarchy-hw-framework16` | Framework Laptop 16 |
| `omarchy-hw-hybrid-gpu` | Hybrid GPU (supergfxctl/lspci) |
| `omarchy-hw-intel` | Intel CPU |
| `omarchy-hw-intel-ptl` | Intel Panther Lake GPU |
| `omarchy-hw-match "pattern"` | Match DMI product name |
| `omarchy-hw-recover-internal-monitor` | Clear internal-monitor-disable |
| `omarchy-hw-surface` | Microsoft Surface devices |
| `omarchy-hw-touchpad` | Find touchpad device name |
| `omarchy-hw-vulkan` | Vulkan availability |

### Hyprland Window Manager (`hyprland-*`)

| Script | Purpose |
|--------|---------|
| `omarchy-hyprland-active-window-transparency-toggle` | Toggle window transparency |
| `omarchy-hyprland-monitor-focused` | Print focused monitor name |
| `omarchy-hyprland-monitor-internal [on\|off\|toggle]` | Enable/disable laptop display |
| `omarchy-hyprland-monitor-scaling-cycle` | Cycle display scale (1→1.25→1.6→2→3→1) |
| `omarchy-hyprland-monitor-watch` | Listen for monitor hotplug |
| `omarchy-hyprland-toggle <flag>` | Toggle Hyprland flags |
| `omarchy-hyprland-window-close-all` | Close all windows |
| `omarchy-hyprland-window-gaps-toggle` | Toggle window gaps |
| `omarchy-hyprland-window-pop [W H X Y]` | Pop window out (float+pin) |
| `omarchy-hyprland-window-single-square-aspect-toggle` | Toggle square aspect |
| `omarchy-hyprland-workspace-layout-toggle` | Toggle dwindle/scrolling |

### Installation Scripts (`install-*`)

| Script | Purpose | Notes |
|--------|---------|-------|
| `omarchy-install-chromium-google-account` | Enable Google sign-in | Adds OAuth credentials |
| `omarchy-install-dev-env <env>` | Install dev environment | Ruby, Node, Python, Go, etc. |
| `omarchy-install-docker-dbs [db...]` | Install DBs in Docker | MySQL, PostgreSQL, Redis, etc. |
| `omarchy-install-dropbox` | Install Dropbox | + systemd service |
| `omarchy-install-geforce-now` | Install GeForce Now | Via Flatpak |
| `omarchy-install-nordvpn` | Install NordVPN | + GUI, requires reboot |
| `omarchy-install-once` | Install ONCE service | TUI for services |
| `omarchy-install-steam` | Install Steam | + graphics drivers |
| `omarchy-install-tailscale` | Install Tailscale VPN | + web admin |
| `omarchy-install-terminal [term]` | Install terminal | alacritty/ghostty/kitty |
| `omarchy-install-vscode` | Install VS Code | + theme, disable auto-update |
| `omarchy-install-xbox-controllers` | Install xpadneo driver | For Xbox controllers |

**Development Environments** (`omarchy-install-dev-env`):
- Ruby (via mise)
- Node.js (via mise)
- Bun
- Deno
- Go
- PHP + Composer
- Python + Poetry
- Elixir + Phoenix
- Rust
- Java
- Zig
- OCaml
- .NET
- Clojure
- Scala

### Application Launchers (`launch-*`)

| Script | Purpose |
|--------|---------|
| `omarchy-launch-about` | Launch fastfetch TUI |
| `omarchy-launch-audio` | Launch wiremix (audio TUI) |
| `omarchy-launch-bluetooth` | Launch bluetui |
| `omarchy-launch-browser [--private]` | Launch default browser |
| `omarchy-launch-editor` | Launch $EDITOR (nvim) |
| `omarchy-launch-floating-terminal-with-presentation` | Floating terminal with logo |
| `omarchy-launch-or-focus <pattern> <cmd>` | Launch or focus window |
| `omarchy-launch-or-focus-tui <cmd>` | Launch or focus TUI |
| `omarchy-launch-screensaver` | Launch TTE screensaver |
| `omarchy-launch-tui <cmd>` | Launch TUI in terminal |
| `omarchy-launch-walker` | Launch Walker with elephant |
| `omarchy-launch-webapp <url>` | Launch URL as web app |
| `omarchy-launch-wifi` | Launch impala (wifi TUI) |

### Toggle Scripts (`toggle-*`)

Toggle scripts create/remove flag files in `~/.local/state/omarchy/toggles/`. Presence = enabled, absence = disabled.

| Script | Purpose | Flag File |
|--------|---------|-----------|
| `omarchy-toggle <flag>` | Generic toggle | `toggles/$flag` |
| `omarchy-toggle-enabled <flag>` | Check if enabled | Exit 0 if exists |
| `omarchy-toggle-hybrid-gpu` | Toggle GPU mode | Via supergfxctl |
| `omarchy-toggle-idle` | Toggle idle lock | Stops/starts hypridle |
| `omarchy-toggle-nightlight` | Toggle night light | 4000K ↔ 6000K |
| `omarchy-toggle-notification-silencing` | Do not disturb | Mako mode toggle |
| `omarchy-toggle-screensaver` | Enable/disable screensaver | |
| `omarchy-toggle-suspend` | Enable/disable suspend | |
| `omarchy-toggle-touchpad [on\|off\|toggle]` | Enable/disable touchpad | `hypr/touchpad-disabled.conf` |
| `omarchy-toggle-waybar` | Toggle Waybar visibility | |

### Theme Management (`theme-*`)

| Script | Purpose |
|--------|---------|
| `omarchy-theme-bg-install` | Open background images folder |
| `omarchy-theme-bg-next` | Cycle to next background |
| `omarchy-theme-bg-set <path>` | Set specific background |
| `omarchy-theme-current` | Display current theme name |
| `omarchy-theme-install <git-url>` | Install theme from git |
| `omarchy-theme-list` | List all installed themes |
| `omarchy-theme-refresh` | Rebuild current theme |
| `omarchy-theme-remove [name]` | Remove a theme |
| `omarchy-theme-set <name>` | Set and apply theme (main command) |
| `omarchy-theme-set-browser` | Sync theme to Chromium/Brave |
| `omarchy-theme-set-gnome` | Sync theme to GNOME |
| `omarchy-theme-set-keyboard` | Set keyboard RGB |
| `omarchy-theme-set-keyboard-asus-rog` | ASUS ROG keyboard |
| `omarchy-theme-set-keyboard-f16` | Framework 16 keyboard |
| `omarchy-theme-set-obsidian` | Sync theme to Obsidian |
| `omarchy-theme-set-plymouth` | Configure boot splash |
| `omarchy-theme-set-templates` | Generate configs from templates |
| `omarchy-theme-set-vscode` | Sync theme to VS Code/Codium/Cursor |
| `omarchy-theme-update` | Update all git-based themes |

### Update Scripts (`update-*`)

| Script | Purpose |
|--------|---------|
| `omarchy-update [-y]` | Main update (git + packages + migrations) |
| `omarchy-update-analyze-logs` | Check for initramfs errors |
| `omarchy-update-aur-pkgs` | Update AUR packages |
| `omarchy-update-available` | Check for updates |
| `omarchy-update-available-reset` | Reset update notification |
| `omarchy-update-branch <branch>` | Switch update branch |
| `omarchy-update-confirm` | Interactive update confirmation |
| `omarchy-update-firmware` | Update system firmware |
| `omarchy-update-git` | Pull latest from git |
| `omarchy-update-keyring` | Update archlinux-keyring |
| `omarchy-update-orphan-pkgs` | Remove orphan packages |
| `omarchy-update-perform` | Run full system update |
| `omarchy-update-restart` | Restart after update |
| `omarchy-update-system-pkgs` | Update system packages |
| `omarchy-update-time` | Update system time |
| `omarchy-update-without-idle` | Update without idle daemon |

### TUI Management (`tui-*`)

| Script | Purpose |
|--------|---------|
| `omarchy-tui-install [name cmd style icon]` | Create TUI shortcut |
| `omarchy-tui-remove [name...]` | Remove TUI shortcuts |
| `omarchy-tui-remove-all` | Remove all TUIs |

**Pre-installed TUIs:**
- **Disk Usage**: Runs `dust -r` in floating terminal
- **Docker**: Runs `lazydocker` in tiled terminal

### Other Important Scripts

| Script | Purpose |
|--------|---------|
| `omarchy-debug [--no-sudo] [--print]` | Generate debug info to `/tmp/omarchy-debug.log` |
| `omarchy-dev-add-migration [--no-edit]` | Create new migration script |
| `omarchy-migrate` | Run pending migrations |
| `omarchy-menu` | Main Omarchy Menu (submenus) |
| `omarchy-menu-keybindings` | Display Hyprland keybindings |
| `omarchy-notification-dismiss <summary>` | Dismiss mako notification |
| `omarchy-pkg-add pkg1 pkg2` | Install packages (pacman) |
| `omarchy-pkg-aur-add pkg1 pkg2` | Install AUR packages (yay) |
| `omarchy-pkg-aur-install` | Fuzzy-find AUR packages to install |
| `omarchy-pkg-drop pkg1 pkg2` | Remove packages |
| `omarchy-pkg-install` | Fuzzy-find official packages |
| `omarchy-powerprofiles-init` | Set power profile on boot |
| `omarchy-powerprofiles-list` | List available profiles |
| `omarchy-powerprofiles-set <ac\|battery>` | Set power profile |
| `omarchy-reinstall` | Reinstall everything |
| `omarchy-reinstall-configs` | Reset all configs |
| `omarchy-reinstall-git` | Reinstall from git |
| `omarchy-reinstall-pkgs` | Reinstall packages |
| `omarchy-remove-dev-env <env>` | Remove dev environment |
| `omarchy-remove-preinstalls` | Remove all preinstalled apps |
| `omarchy-snapshot <create\|restore>` | Snapper snapshots |
| `omarchy-state <set\|clear> <name>` | Manage state files |
| `omarchy-sudo-keepalive` | Keep sudo alive in background |
| `omarchy-sudo-passwordless-toggle [mins]` | Toggle passwordless sudo |
| `omarchy-sudo-reset` | Reset sudo lockout |
| `omarchy-system-logout` | Logout (close windows first) |
| `omarchy-system-reboot` | Reboot (close windows first) |
| `omarchy-system-shutdown` | Shutdown (close windows first) |
| `omarchy-tz-select` | Interactive timezone selection |
| `omarchy-upload-log` | Upload log to 0x0.st |
| `omarchy-voxtype-install` | Install Voxtype dictation |
| `omarchy-voxtype-remove` | Remove Voxtype |
| `omarchy-voxtype-config` | Configure Voxtype |
| `omarchy-voxtype-model` | Change Voxtype model |
| `omarchy-voxtype-status` | Check Voxtype status |
| `omarchy-windows-vm` | Windows VM management |
| `omarchy-wifi-powersave` | Toggle WiFi power saving |

---

## Applications Installed

### Base System Packages (`omarchy-base.packages`)

**Core Wayland Stack:**
- `hyprland` - Window manager
- `hypridle` - Idle management
- `hyprlock` - Lock screen
- `hyprpicker` - Color picker
- `hyprsunset` - Night light
- `hyprland-guiutils` - GUI utilities
- `hyprland-preview-share-picker` - Screen share picker

**Session Management:**
- `uwsm` - Wayland session manager
- `polkit-gnome` - Authentication agent

**Desktop Components:**
- `swaybg` - Wallpaper setter
- `swayosd` - On-screen display (volume/brightness)
- `waybar` - Status bar
- `mako` - Notification daemon
- `xdg-desktop-portal-hyprland` - XDG portal
- `xdg-desktop-portal-gtk` - GTK portal
- `xdg-terminal-exec` - Terminal launcher

**Terminals:**
- `alacritty` - Default terminal (GPU accelerated)
- `ghostty` - Alternative terminal (themed)

**Shell & CLI:**
- `bash-completion` - Bash completions
- `starship` - Cross-shell prompt
- `tmux` - Terminal multiplexer
- `zoxide` - Smart cd replacement

**Editors & Development:**
- `nvim` - Neovim editor
- `tree-sitter-cli` - Syntax highlighting
- `luarocks` - Lua package manager
- `clang`, `llvm` - C/C++ compiler
- `rust` - Rust toolchain
- `ruby` - Ruby interpreter
- `python-gobject` - Python GObject bindings
- `python-poetry-core` - Python packaging
- `dotnet-runtime-9.0` - .NET runtime
- `github-cli` - GitHub CLI
- `cmake` - Build system

**File Management:**
- `nautilus` - GNOME Files
- `nautilus-python` - Nautilus extensions
- `gvfs-mtp` - MTP support
- `gvfs-nfs` - NFS support
- `gvfs-smb` - SMB/CIFS support

**CLI Tools:**
- `eza` - Modern `ls` replacement
- `fd` - Modern `find` replacement
- `ripgrep` - Fast text search
- `fzf` - Fuzzy finder
- `bat` - Syntax-highlighted `cat`
- `jq` - JSON processor
- `xmlstarlet` - XML processor
- `plocate` - Fast file search
- `tldr` - Simplified man pages
- `mise` - Tool version manager

**Multimedia:**
- `mpv` - Video player
- `imv` - Image viewer
- `obs-studio` - Screen recording
- `gpu-screen-recorder` - GPU-accelerated recording
- `satty` - Screenshot annotation
- `pinta` - Image editing
- `spotify` - Music streaming (AUR)
- `playerctl` - Media player control
- `kdenlive` - Video editor

**Office & Productivity:**
- `typora` - Markdown editor
- `obsidian` - Note-taking
- `libreoffice-fresh` - Office suite
- `evince` - PDF viewer
- `gnome-calculator` - Calculator

**System Tools:**
- `docker`, `docker-buildx`, `docker-compose` - Container tools
- `btop` - System monitor
- `dust` - Disk usage analyzer
- `brightnessctl` - Brightness control
- `pamixer` - Audio control
- `wireplumber` - PipeWire session manager
- `pipewire` - Audio server
- `iwd` - Wireless daemon
- `bluetui` - Bluetooth TUI
- `bolt` - Thunderbolt support
- `cups` - Print server
- `power-profiles-daemon` - Power management
- `ufw` - Firewall
- `gnome-keyring` - Password storage
- `libsecret` - Secret storage
- `1password-beta`, `1password-cli` - Password manager
- `fastfetch` - System information
- `inxi` - Hardware information
- `imagemagick` - Image manipulation
- `ffmpegthumbnailer` - Video thumbnails
- `yay` - AUR helper

**Fonts:**
- `ttf-jetbrains-mono-nerd` - Primary monospace font
- `ttf-ia-writer` - Writing font
- `noto-fonts` - Google Noto fonts
- `noto-fonts-cjk` - CJK characters
- `noto-fonts-emoji` - Emoji
- `woff2-font-awesome` - Font Awesome icons
- `yaru-icon-theme` - Icon theme

### Web Applications (15 total)

Installed via `omarchy-webapp-install`:

| Application | URL | Icon |
|-------------|-----|------|
| HEY | https://app.hey.com | HEY.png |
| Basecamp | https://launchpad.37signals.com | Basecamp.png |
| WhatsApp | https://web.whatsapp.com/ | WhatsApp.png |
| Google Photos | https://photos.google.com/ | Google Photos.png |
| Google Contacts | https://contacts.google.com/ | Google Contacts.png |
| Google Messages | https://messages.google.com/ | Google Messages.png |
| Google Maps | https://maps.google.com/ | Google Maps.png |
| ChatGPT | https://chatgpt.com/ | ChatGPT.png |
| YouTube | https://youtube.com/ | YouTube.png |
| GitHub | https://github.com/ | GitHub.png |
| X (Twitter) | https://x.com/ | X.png |
| Figma | https://figma.com/ | Figma.png |
| Discord | https://discord.com/ | Discord.png |
| Zoom | https://app.zoom.us/ | Zoom.png |
| Fizzy | https://app.fizzy.do/ | Fizzy.png |

Web apps are launched as standalone windows using `xdg-open` with `x-scheme-handler` MIME types.

### NPX Wrappers (installed via `npx.sh`)

| Command | Package | Purpose |
|---------|---------|---------|
| `codex` | `@openai/codex` | OpenAI Codex CLI |
| `gemini` | `@google/gemini-cli` | Google Gemini CLI |
| `copilot` | `@github/copilot` | GitHub Copilot CLI |
| `opencode` | `opencode-ai` | OpenCode AI assistant |
| `playwright-cli` | `playwright` | Playwright automation |
| `pi` | `@mariozechner/pi-coding-agent` | Pi coding agent |

### Optional Installs

**Via `omarchy-install-dev-env`:**
- Ruby, Node.js, Bun, Deno, Go, PHP, Python, Elixir/Phoenix, Rust, Java, Zig, OCaml, .NET, Clojure, Scala

**Via `omarchy-install-docker-dbs`:**
- MySQL (port 3306)
- PostgreSQL (port 5432)
- Redis (port 6379)
- MongoDB (port 27017)
- MariaDB (port 3306)
- MSSQL (port 1433)

**Via `omarchy-install-voxtype`:**
- `voxtype-bin` - Voice typing
- `wtype` - Wayland typing simulation
- Downloads AI model (~150MB)
- Configures systemd service
- Toggle with Super+Ctrl+X

---

## Key Bindings

Omarchy uses Hyprland's `bindd` (described bindings) for all key combinations. Here's the complete reference:

### Modifier Keys
- `SUPER` = Windows/Command key
- `ALT` = Alt key
- `CTRL` = Control key
- `SHIFT` = Shift key

### Window Management

| Keybinding | Action |
|------------|--------|
| `Super + W` | Close window |
| `Ctrl + Alt + Delete` | Close all windows |
| `Super + J` | Toggle split (dwindle/master) |
| `Super + P` | Toggle pseudo-tiling |
| `Super + T` | Toggle floating/tiling |
| `Super + F` | Full screen |
| `Super + Ctrl + F` | Tiled full screen |
| `Super + Alt + F` | Full width |
| `Super + O` | Pop window out (float + pin) |
| `Super + L` | Toggle workspace layout (dwindle ↔ scrolling) |

### Focus Movement

| Keybinding | Action |
|------------|--------|
| `Super + Left/Right/Up/Down` | Focus window in direction |
| `Super + Tab` | Next workspace |
| `Super + Shift + Tab` | Previous workspace |
| `Super + Ctrl + Tab` | Former workspace |
| `Alt + Tab` | Cycle applications |
| `Alt + Shift + Tab` | Cycle applications (reverse) |
| `Ctrl + Alt + Tab` | Cycle monitors |
| `Ctrl + Alt + Shift + Tab` | Cycle monitors (reverse) |

### Workspaces (1-10)

| Keybinding | Action |
|------------|--------|
| `Super + 1-0` | Switch to workspace |
| `Super + Shift + 1-0` | Move window to workspace |
| `Super + Shift + Alt + 1-0` | Move window silently to workspace |

### Monitor Movement

| Keybinding | Action |
|------------|--------|
| `Super + Shift + Alt + Arrow` | Move workspace to monitor |

### Window Resize/Move

| Keybinding | Action |
|------------|--------|
| `Super + -/=` | Resize window (shrink/expand) |
| `Super + Shift + -/=` | Resize window vertically |
| `Super + LMB drag` | Move window |
| `Super + RMB drag` | Resize window |
| `Super + Shift + Arrow` | Swap window with adjacent |

### Scratchpad

| Keybinding | Action |
|------------|--------|
| `Super + S` | Toggle scratchpad |
| `Super + Alt + S` | Move window to scratchpad |

### Groups

| Keybinding | Action |
|------------|--------|
| `Super + G` | Toggle window grouping |
| `Super + Alt + G` | Move window out of group |
| `Super + Alt + Arrow` | Move window into group |
| `Super + Alt + Tab` | Next window in group |
| `Super + Alt + Shift + Tab` | Previous window in group |
| `Super + Ctrl + Arrow` | Navigate grouped windows |
| `Super + Alt + Scroll` | Scroll through grouped windows |
| `Super + Alt + 1-5` | Activate group window by number |

### Monitor Scaling

| Keybinding | Action |
|------------|--------|
| `Super + /` | Cycle monitor scaling (1→1.25→1.6→2→3→1) |
| `Super + Alt + /` | Cycle backwards |

### Workspace Scroll

| Keybinding | Action |
|------------|--------|
| `Super + Scroll` | Scroll through workspaces |

### Multimedia Keys

| Keybinding | Action |
|------------|--------|
| `XF86AudioRaise` | Volume up (with OSD) |
| `XF86AudioLower` | Volume down (with OSD) |
| `XF86AudioMute` | Toggle mute (with OSD) |
| `XF86AudioNext/Prev` | Media next/previous |
| `XF86AudioPlay/Pause` | Media play/pause |
| `Alt + AudioRaise/Lower` | 1% volume adjustment |
| `Super + Mute` | Switch audio output |

### Brightness

| Keybinding | Action |
|------------|--------|
| `XF86MonBrightnessUp/Down` | Adjust brightness (5% steps) |
| `Ctrl + F1/F2` | Apple Display brightness |

### Keyboard Backlight

| Keybinding | Action |
|------------|--------|
| `XF86KbdBrightnessUp/Down` | Adjust keyboard brightness |
| `XF86KbdBrightnessUp/Down` (with Shift?) | Cycle keyboard brightness |

### Touchpad

| Keybinding | Action |
|------------|--------|
| `XF86TouchpadToggle/On/Off` | Toggle touchpad |

### Clipboard

| Keybinding | Action |
|------------|--------|
| `Super + C` | Copy (sends Ctrl+Insert) |
| `Super + V` | Paste (sends Shift+Insert) |
| `Super + X` | Cut (sends Ctrl+X) |
| `Super + Ctrl + V` | Open clipboard manager (Walker) |

### Launchers

| Keybinding | Action |
|------------|--------|
| `Super + Space` | Launch Walker |
| `Super + Alt + Space` | Launch Omarchy Menu |

### Applications

| Keybinding | Action |
|------------|--------|
| `Super + Return` | Launch terminal |
| `Super + Alt + Return` | Launch tmux |
| `Super + Shift + Return/B` | Launch browser |
| `Super + Shift + F` | Launch file manager |
| `Super + Shift + M` | Launch music (Spotify) |
| `Super + Shift + N` | Launch editor (nvim) |
| `Super + Shift + D` | Launch Docker (lazydocker) |
| `Super + 1-0` (bindings) | Launch/custom apps |

### Utilities

| Keybinding | Action |
|------------|--------|
| `Super + Z` | Toggle Waybar |
| `Super + Shift + Z` | Cycle themes |
| `Super + Ctrl + Z` | Zoom in |
| `Super + Ctrl + Alt + Z` | Reset zoom |
| `Super + ,` | Cycle backgrounds |
| `Super + .` | Toggle window transparency |
| `Super + ;` | Toggle window gaps |
| `Super + Alt + L` | Lock screen |
| `Super + Alt + I` | Toggle idle lock |
| `Super + Alt + N` | Toggle night light |
| `Super + Alt + D` | Toggle notification silencing |
| `Super + Alt + S` | Toggle screensaver |
| `Super + Alt + P` | Toggle touchpad |
| `Super + Alt + M` | Toggle internal monitor |
| `Super + Alt + L` | Toggle lid switch |

### Screenshots & Recording

| Keybinding | Action |
|------------|--------|
| `Print` | Screenshot (region mode) |
| `Alt + Print` | Screen record (toggle) |
| `Super + Print` | Color picker |
| `Super + Ctrl + S` | Share via LocalSend |
| `Super + Shift + P` | Screenshot to clipboard |

### System Info

| Keybinding | Action |
|------------|--------|
| `Super + Ctrl + Alt + T` | Show battery status |
| `Super + Ctrl + Alt + B` | Show battery time remaining |
| `Super + Ctrl + Alt + U` | Show system uptime |

### Dictation

| Keybinding | Action |
|------------|--------|
| `Super + Ctrl + X` | Toggle Voxtype dictation |

---

## Hooks System

Hooks allow custom scripts to run at specific points in Omarchy's operation.

### Hook Locations

| Hook File | When it runs |
|-----------|--------------|
| `~/.config/omarchy/hooks/theme-set` | After theme is set |
| `~/.config/omarchy/hooks/theme-set.d/*.sh` | Child scripts of theme-set |
| `~/.config/omarchy/hooks/post-update` | After system update |
| `~/.config/omarchy/hooks/font-set` | After font is changed |
| `~/.config/omarchy/hooks/battery-low` | When battery < 10% |

### Sample Hooks

Located at `~/.config/omarchy/hooks/*.sample` - remove `.sample` to activate.

**theme-set.sample** - Template for theme-set hook:
```bash
#!/bin/bash
# This hook runs after a theme is set
# Available environment variables: primary_background, primary_foreground, etc.
echo "Theme set successfully!"
```

**post-update.sample** - Template for post-update hook:
```bash
#!/bin/bash
# This hook runs after system update
# Use it to perform custom tasks after updates
```

**font-set.sample** - Template for font-set hook:
```bash
#!/bin/bash
# This hook runs after system font is changed
# $1 is the new font name
echo "Font changed to $1"
```

**battery-low.sample** - Template for battery-low hook:
```bash
#!/bin/bash
# This hook runs when battery is below 10%
# Use it for custom low-battery actions
```

### Theme-Set Hook Details

The main `theme-set` hook (`~/.config/omarchy/hooks/theme-set`):

1. Sources `colors.toml` and extracts all color values
2. Converts hex colors to RGB
3. Exports all color variables for child scripts
4. Runs all executable scripts in `theme-set.d/*.sh`
5. Checks if any apps need restart (tracked via `require_restart`)
6. Sends notification if restart required

Child scripts in `theme-set.d/` receive these environment variables:
- `$primary_foreground`, `$primary_background`
- `$cursor_color`, `$selection_foreground`, `$selection_background`
- `$normal_black` through `$normal_white` (color0-7)
- `$bright_black` through `$bright_white` (color8-15)
- `$rgb_primary_foreground`, `$rgb_primary_background` (decimal RGB)
- All other color variables in RGB format

To mark an app for restart notification:
```bash
require_restart "app-name"  # Adds to restart list
```

---

## Migration System

Migrations allow Omarchy to evolve the system configuration over time, similar to database migrations.

### How Migrations Work

1. **Migration scripts** are stored in `~/.local/share/omarchy/migrations/*.sh`
2. Each script is named after the **unix timestamp** of the last git commit
3. When `omarchy-migrate` runs, it:
   - Iterates through all migration scripts
   - Checks if a corresponding file exists in `~/.local/state/omarchy/migrations/`
   - If not, runs the migration script
   - On success, touches the state file
   - On failure, asks to skip (touches `skipped/` file)

### Migration Script Format

Migrations have **no shebang line** and typically start with an echo:

```bash
echo "Disable fingerprint in hyprlock if fingerprint auth is not configured"

if omarchy-cmd-missing fprintd-list || ! fprintd-list "$USER" 2>/dev/null | grep -q "finger"; then
  sed -i 's/fingerprint:enabled = .*/fingerprint:enabled = false/' ~/.config/hypr/hyprlock.conf
fi
```

### Creating a Migration

Use `omarchy-dev-add-migration [--no-edit]`:

1. Takes the unix timestamp of the last git commit
2. Creates a new script at `~/.local/share/omarchy/migrations/<timestamp>.sh`
3. Opens it in editor (unless `--no-edit`)
4. During `omarchy-migrate`, this script will run on all systems

### Migration State Tracking

| Location | Purpose |
|----------|---------|
| `~/.local/state/omarchy/migrations/*.sh` | Completed migrations (empty files) |
| `~/.local/state/omarchy/migrations/skipped/*.sh` | Skipped migrations |

### Current Migration Count

As of this writing, there are **283 migration scripts** in the migrations directory, showing the active development of Omarchy.

---

## Package Management

Omarchy provides wrapper scripts around `pacman` and `yay` for consistent package management.

### Official Repositories (pacman)

| Script | Purpose |
|--------|---------|
| `omarchy-pkg-add pkg1 pkg2` | Install packages (handles both pacman + AUR) |
| `omarchy-pkg-present pkg1 pkg2` | Return true if all installed |
| `omarchy-pkg-missing pkg1 pkg2` | Return true if any missing |
| `omarchy-pkg-drop pkg1 pkg2` | Remove packages (ignore if not installed) |
| `omarchy-pkg-install` | Fuzzy-find official packages to install (uses fzf) |
| `omarchy-pkg-remove` | Fuzzy-find installed packages to remove |

### AUR (yay)

| Script | Purpose |
|--------|---------|
| `omarchy-pkg-aur-add pkg1 pkg2` | Install AUR packages |
| `omarchy-pkg-aur-install` | Fuzzy-find AUR packages to install |
| `omarchy-pkg-aur-accessible` | Check if AUR is up |

### Package Channels

Omarchy has three package channels that determine which pacman mirror is used:

| Channel | Mirror | Branch |
|---------|--------|--------|
| `stable` | `stable-mirror.omarchy.org` | master |
| `rc` | `rc-mirror.omarchy.org` | rc |
| `edge` | `edge-mirror.omarchy.org` | dev |

Switch channels with:
```bash
omarchy-channel-set [stable|rc|edge|dev]
```

This updates:
1. `/etc/pacman.conf` with channel-specific settings
2. `/etc/pacman.d/mirrorlist` with channel mirror
3. Sets the git branch via `omarchy-branch-set`

---

## Hardware Support

Omarchy includes extensive hardware support scripts for various laptop models.

### Intel Systems

| Script | Purpose |
|--------|---------|
| `install/packaging/base.sh` | Intel video acceleration (VA-API) |
| `config/hardware/intel/video-acceleration.sh` | Configure i915 driver |
| `config/hardware/intel/lpmd.sh` | Intel Low Power Mode Daemon |
| `config/hardware/intel/thermald.sh` | Thermal management |
| `config/hardware/intel/ipu7-camera.sh` | Intel IPU7 camera support |
| `config/hardware/intel/ptl-kernel.sh` | Panther Lake kernel |
| `config/hardware/intel/fix-wifi7-eht.sh` | WiFi 7 EHT fixes |

### ASUS Laptops

| Script | Purpose |
|--------|---------|
| `install/packaging/asus-rog.sh` | Install asusctl (if ROG detected) |
| `config/hardware/asus/fix-asus-ptl-b9406-display.sh` | ExpertBook B9406 display |
| `config/hardware/asus/fix-asus-ptl-b9406-touchpad.sh` | ExpertBook B9406 touchpad |
| `config/hardware/asus/fix-audio-mixer.sh` | Audio mixer fixes |
| `config/hardware/asus/fix-mic.sh` | Microphone fixes |
| `config/hardware/asus/fix-z13-touchpad.sh` | ROG Z13 touchpad |
| `omarchy-theme-set-keyboard-asus-rog` | ASUS ROG keyboard RGB |

### Framework Laptops

| Script | Purpose |
|--------|---------|
| `install/packaging/framework16.sh` | Install qmk-hid (if F16 detected) |
| `config/hardware/framework/fix-f13-amd-audio-input.sh` | F13 AMD audio |
| `config/hardware/framework/qmk-hid.sh` | QMK HID configuration |
| `udev/framework16-qmk-hid.rules` | Udev rules for keyboard |
| `omarchy-theme-set-keyboard-f16` | Framework 16 keyboard RGB |

### Apple MacBooks (T2)

| Script | Purpose |
|--------|---------|
| `config/hardware/apple/fix-spi-keyboard.sh` | SPI keyboard driver |
| `config/hardware/apple/fix-suspend-nvme.sh` | NVMe suspend fix |
| `config/hardware/apple/fix-t2.sh` | T2 chip support |
| `install/packaging/surface.sh` | Linux-t2 kernel + firmware |
| `brightness-display-apple` | Apple Studio/XDR brightness |

### Microsoft Surface

| Script | Purpose |
|--------|---------|
| `install/packaging/surface.sh` | Surface kernel + firmware |
| `config/hardware/surface.sh` | Surface-specific config |
| `config/hardware/fix-surface-keyboard.sh` | Surface keyboard |

### Dell XPS

| Script | Purpose |
|--------|---------|
| `config/hardware/dell/fix-xps-haptic-touchpad.sh` | Haptic touchpad |
| `omarchy-cmd-mic-mute-xps` | XPS mic mute with LED |

### Other Hardware

| Script | Purpose |
|--------|---------|
| `config/hardware/fix-fkeys.sh` | Function key behavior |
| `config/hardware/bluetooth.sh` | Bluetooth configuration |
| `config/hardware/printer.sh` | Printer support (CUPS) |
| `config/hardware/usb-autosuspend.sh` | USB power saving |
| `config/hardware/ignore-power-button.sh` | Ignore power button presses |
| `config/hardware/nvidia.sh` | NVIDIA driver support |
| `config/hardware/vulkan.sh` | Vulkan configuration |
| `config/hardware/fix-bcm43xx.sh` | Broadcom WiFi |
| `config/hardware/fix-yt6801-ethernet-adapter.sh` | Realtek Ethernet |
| `config/hardware/fix-synaptic-touchpad.sh` | Synaptic touchpad |
| `config/hardware/fix-tuxedo-backlight.sh` | Tuxedo keyboard backlight |
| `omarchy-hw-vulkan` | Detect Vulkan support |
| `omarchy-hw-hybrid-gpu` | Detect hybrid GPU |

### Haptic Touchpad Support

For Synaptics touchpads with haptic feedback (`omarchy-haptic-touchpad`):

- Python daemon that monitors `/dev/input/event*`
- Sends HID feature reports to `/dev/hidraw*`
- Configurable intensity (0-100)
- Vendor ID: 06CB (Synaptics)

---

## Summary

Omarchy is a comprehensive Linux distribution that provides:

1. **Complete desktop environment** - Hyprland + Waybar + Walker + all utilities
2. **Unified theming** - Single `colors.toml` drives 20+ applications
3. **Template system** - `{{ variable }}` placeholders auto-fill with theme colors
4. **Toggle system** - Features enabled/disabled via flag files
5. **Migration system** - Smooth updates as Omarchy evolves
6. **Hook system** - Custom scripts at key points (theme-set, post-update)
7. **Hardware support** - Extensive laptop support (ASUS, Framework, Apple, Surface, Dell)
8. **Developer tools** - Multiple language runtimes, Neovim, VS Code, Docker
9. **AI integration** - Voxtype dictation, OpenCode, Codex, Gemini, Copilot
10. **Web applications** - 15 preconfigured web apps with standalone windows

The entire system is managed through 100+ `omarchy-*` commands that handle everything from theme switching to package management to hardware configuration.
