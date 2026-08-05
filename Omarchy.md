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

**Omarchy** is a beautiful, modern, and opinionated Linux distribution by DHH (David Heinemeier Hansson). It's built on top of Arch Linux and uses the Hyprland Wayland compositor as its window manager. Version: **4.0.0** (Quattro — package-backed layout).

### Core Philosophy
- **Opinionated defaults**: Sensible defaults for developers and power users
- **Unified theming**: Single `colors.toml` drives colors across all applications
- **Package-backed install**: Omarchy is installed as an Arch package (installed under `/usr/share/omarchy/`), not a git clone in `$HOME`
- **Single CLI**: Everything is exposed through one `omarchy` command that dispatches to 300+ `omarchy-*` scripts
- **Template-driven configs**: `{{ variable }}` placeholders in templates auto-fill with theme colors
- **Toggle-based configuration**: Features can be enabled/disabled via flag files

### Key Technologies
- **Window Manager**: Hyprland (Wayland), configured in **Lua** (`hyprland.lua`)
- **Shell (status bar, panels, notifications, OSD)**: **Omarchy Shell** — a Quickshell-based bar, control centers, notification daemon, and launcher in a single process (`omarchy-shell`)
- **Launcher**: Omarchy menu / launcher built on Quickshell
- **Notifications**: Quickshell notification daemon (panels)
- **Terminal**: Alacritty (default), with Ghostty, Foot, and Kitty support
- **Shell**: Bash with custom functions
- **Editor**: Neovim with the `omarchy-nvim` (LazyVim) distribution
- **Bootloader**: Limine (primary)
- **Boot Splash**: Plymouth (theme colored from active theme)
- **Login Manager**: SDDM set to autologin
- **Audio**: PipeWire + WirePlumber
- **Display Server**: Wayland (no X11 except XWayland for compatibility)

### Key Facts
- `OMARCHY_PATH` = `/usr/share/omarchy/` (read-only, managed by the package manager)
- 300+ `omarchy-*` scripts live in `/usr/share/omarchy/bin/` and are dispatched through the `omarchy` CLI
- The shell, launcher, notifications, OSD, and lock screen are all Quickshell components
- 22 built-in themes, each driven by a single `colors.toml`

---

## Directory Structure

```
Omarchy Installation Paths:
├── /usr/share/omarchy/               # Package install (OMARCHY_PATH - read-only)
│   ├── bin/                          # All omarchy-* commands (300+ scripts)
│   ├── config/                       # Default user configs (copied to ~/.config)
│   │   ├── omarchy/                  # shell.json, menu extensions, themed/, hooks/
│   │   ├── hypr/                     # Hyprland user config templates
│   │   ├── alacritty/ foot/ ghostty/ kitty/   # Terminal config templates
│   │   ├── btop/ tmux/ starship.toml git/ chromium/ fcitx5/ ...
│   ├── default/                      # System defaults and templates
│   │   ├── hypr/                     # Lua Hyprland configs (Lua modules)
│   │   │   ├── hyprland.lua          # Composition helpers (o.*, hl.*)
│   │   │   ├── helpers.lua           # Helper library
│   │   │   ├── envs.lua              # Environment variables (Wayland forcing)
│   │   │   ├── looknfeel.lua         # Appearance (gaps, borders, animations)
│   │   │   ├── input.lua             # Input device config
│   │   │   ├── windows.lua           # Window rules (o.window helper)
│   │   │   ├── autostart.lua         # exec-once services
│   │   │   ├── bindings.lua          # Loads bindings/*
│   │   │   └── bindings/             # tiling, utilities, applications, media, clipboard, voxtype
│   │   ├── themed/                   # Theme templates (*.tpl files)
│   │   ├── bash/ bashrc/ chromium/ firefox/ fontconfig/ fonts/ gpg/
│   │   ├── limine/ plymouth/ sddm/ snapper/ systemd/ udev/ uwsm/
│   │   ├── pacman/                   # Mirror + repo configs per channel
│   │   ├── voxtype/ tensaku/ xdg-terminal-exec/ environment.d/
│   │   └── omarchy/                  # launcher.hides, omarchy-menu.jsonc defaults
│   ├── shell/                        # Omarchy Shell (Quickshell) source
│   │   ├── shell.qml                 # Main shell entry
│   │   ├── Ui/                       # QML UI kit (Panel, Button, Bar, etc.)
│   │   ├── plugins/                  # Built-in shell plugins (bar widgets)
│   │   └── services/                 # bar, menu, notifications, OSD, lock, etc.
│   ├── themes/                       # Built-in themes (22 themes)
│   │   ├── tokyo-night/ nord/ lumon/ vantablack/ white/ ...
│   ├── migrations/                   # Update migrations (55 scripts)
│   ├── applications/                 # Desktop entries (web apps, TUIs)
│   ├── install/                      # Installation scripts
│   │   ├── omarchy-base.packages     # Core package list (ISO pacstrap)
│   │   ├── omarchy-other.packages    # Optional/detected packages
│   │   ├── config/                   # System configuration setup
│   │   ├── hardware/                 # Hardware detection + fixes
│   │   ├── login/                    # SDDM setup
│   │   ├── post-install/             # Cleanup tasks
│   │   └── user/                     # Per-user setup (first-run, git, theme)
│   └── version                       # Version file (4.0.0.alpha)
│
├── ~/.config/hypr/                   # User Hyprland configuration (Lua)
│   ├── hyprland.lua                  # Main config (loads defaults, then user files)
│   ├── bindings.lua                  # User keybinding overrides
│   ├── monitors.lua                  # Display configuration
│   ├── input.lua                     # Keyboard/mouse settings
│   ├── looknfeel.lua                 # Appearance overrides
│   ├── autostart.lua                 # User autostart overrides
│   ├── envs.conf                     # Extra env vars (conf syntax)
│   ├── xdph.conf                     # XDG desktop portal config
│   ├── hyprlock.conf                 # Lock screen
│   └── hyprsunset.conf               # Night light
│
├── ~/.config/omarchy/                # User omarchy configuration
│   ├── shell.json                    # Shell config: bar layout, plugins, idle
│   ├── themes/                       # User-installed themes (real directories)
│   ├── themed/                       # User template overrides (*.tpl)
│   ├── hooks/                        # Custom hook scripts
│   │   ├── theme-set.d/              # Theme-set hook scripts
│   │   ├── post-boot.d/ post-update.d/ font-set.d/ battery-low.d/ ...
│   ├── plugins/<owner>.<id>/         # Cloned / user-owned shell plugins
│   ├── extensions/                   # Menu extensions (omarchy-menu.jsonc)
│   ├── dock/                         # Dock configuration
│   └── branding/                     # about.txt, screensaver.txt branding
│
├── ~/.local/state/omarchy/           # Runtime state
│   ├── current/                      # Active theme state
│   │   ├── theme/                    # Generated theme configs
│   │   │   ├── colors.toml           # Active theme colors
│   │   │   ├── alacritty.toml        # Terminal colors
│   │   │   ├── hyprland.lua          # Theme Hyprland variables
│   │   │   ├── btop.theme            # System monitor theme
│   │   │   ├── shell.toml            # Shell palette
│   │   │   ├── backgrounds/          # Wallpaper images
│   │   │   └── ... (all generated .tpl outputs)
│   │   ├── background                # Symlink to current wallpaper
│   │   └── theme.name                # Current theme name
│   ├── migrations/                   # Completed migration tracking
│   ├── toggles/                      # Toggle flag files
│   │   └── hypr/                     # Hyprland toggle flags (*.conf)
│   ├── notifications.json            # Notification history
│   ├── clipboard-history.json        # Clipboard manager history
│   └── ...
│
└── ~/.config/                        # Standard Linux config directory
    ├── alacritty/ foot/ ghostty/ kitty/   # Terminal configs
    ├── btop/ tmux/ starship.toml git/ fastfetch/
    ├── systemd/user/                 # User systemd services
    └── autostart/                    # XDG autostart entries
```

---

## Installation Process

Omarchy 4.0 is **package-backed** ("Quattro" layout). Omarchy itself ships as an Arch package installed to `/usr/share/omarchy/`, so updates flow through the normal package manager rather than a git pull.

### 1. Channels & Mirrors

Omarchy installs packages from its own pacman mirror, selected by channel:

| Channel | Mirror |
|---------|--------|
| `stable` | `stable-mirror.omarchy.org` |
| `rc` | `rc-mirror.omarchy.org` |
| `edge` | `edge-mirror.omarchy.org` |
| `dev` | `dev-mirror.omarchy.org` |

Set the channel with `omarchy channel set <stable|rc|edge|dev>`.

### 2. Base Packages

The ISO pacstraps the list in `/usr/share/omarchy/install/omarchy-base.packages` and adds detected hardware packages from `omarchy-other.packages`. `omarchy reinstall pkgs` reinstalls the same set from the active channel.

### 3. System Setup

- `omarchy setup system` — apply Omarchy system setup (mirrors, config, hardware)
- `omarchy setup hardware` — apply hardware-specific packages and configuration (auto-detects the machine)
- `omarchy first run` — finish first-login setup (per-user tasks, default keyring, git, theme, battery monitoring, firewall)

### 4. Per-User Setup (`install/user/`)

Sets up `git.sh`, `mise.sh` (version manager), `theme.sh` (initial theme), `chromium.sh`, `default-keyring.sh`, `xcompose.sh`, plus first-run scripts.

### 5. Legacy Upgrades

Systems still running the old `~/.local/share/omarchy/` git-checkout layout are migrated with:

```bash
omarchy upgrade to quattro
```

This converts a legacy install to the package-backed layout (optionally `--dev` for a dev checkout, or `--channel <stable|rc|edge>`).

---

## Configuration System

Omarchy uses a **layered configuration system**: defaults are sourced first, then user overrides, then theme variables, and finally dynamic toggles.

### Hyprland (Lua-based)

Hyprland is configured in Lua. The main entry `~/.config/hypr/hyprland.lua` loads the defaults from `/usr/share/omarchy/default/hypr/`, then your user files, then the theme, then toggles:

```
1. /usr/share/omarchy/default/hypr/bootstrap.lua      # Lua bootstrap + paths
2. /usr/share/omarchy/default/hypr/helpers.lua        # o.* / hl.* helper library
3. /usr/share/omarchy/default/hypr/envs.lua           # Environment variables
4. /usr/share/omarchy/default/hypr/input.lua          # Input device config
5. /usr/share/omarchy/default/hypr/looknfeel.lua      # Appearance (gaps, borders, animations)
6. /usr/share/omarchy/default/hypr/windows.lua        # Window rules
7. /usr/share/omarchy/default/hypr/autostart.lua      # exec-once services
8. /usr/share/omarchy/default/hypr/bindings/*.lua     # Default keybindings
9. /usr/share/omarchy/default/hypr/workspace-layouts.lua
10. /usr/share/omarchy/default/hypr/apps.lua          # App-specific config
11. ~/.config/hypr/hyprland.lua                       # User main overrides
12. ~/.config/hypr/bindings.lua                       # User keybinding overrides
13. ~/.config/hypr/autostart.lua                      # User autostart
14. ~/.config/hypr/looknfeel.lua                      # User appearance overrides
15. ~/.config/hypr/input.lua                          # User input overrides
16. ~/.config/hypr/monitors.lua                       # Monitor layout
17. ~/.config/omarchy/current/theme/hyprland.lua      # Theme variables
18. ~/.local/state/omarchy/toggles/hypr/*.conf        # Dynamic toggle flags
```

**Lua helpers** provided by `helpers.lua`:

| Helper | Purpose | Example |
|--------|---------|---------|
| `o.bind(mods, description, action, opts)` | Describe a keybinding | `o.bind("SUPER + W", "Close window", hl.dsp.window.close())` |
| `o.bind_toggle(...)` | Toggle-style binding | `o.bind_toggle("SUPER + CTRL + N", "Toggle nightlight", "nightlight")` |
| `o.window(match, rules)` | Add a window rule | `o.window("class:(Firefox)", { opacity = 0.9 })` |
| `hl.config({...})` | Set Hyprland config | `hl.config({ general = { gaps_in = 5 } })` |
| `hl.env("KEY", "value")` | Set environment variable | `hl.env("GDK_BACKEND", "wayland,x11,*")` |
| `hl.curve(...)` / `hl.animation(...)` | Define animation curves/animations | `hl.curve("easeOutQuint", {...})` |
| `hl.monitor({...})` | Configure a monitor | `hl.monitor({ output = "eDP-1", mode = "1920x1080@60" })` |
| `hl.dsp.*` | Hyprland dispatcher helpers | `hl.dsp.focus({ workspace = "e+1" })` |
| `o.launch(...)` | Launch wrapped in uwsm-app | `o.launch("udiskie ...")` |

**Key behaviors:**
- Hyprland auto-reloads on config save (no restart needed for most changes)
- After any Hyprland config change, validate with `hyprctl reload` followed by `hyprctl configerrors`
- `omarchy refresh hyprland` resets all user Hyprland Lua configs to defaults

### Environment Variables (`default/hypr/envs.lua`)

Forces Wayland for all applications:

```lua
hl.env("GDK_BACKEND", "wayland,x11,*")          -- GTK apps
hl.env("QT_QPA_PLATFORM", "wayland;xcb")        -- Qt apps
hl.env("MOZ_ENABLE_WAYLAND", "1")               -- Firefox
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")  -- Electron apps
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCOMPOSEFILE", "~/.XCompose")
```

### Look & Feel (`default/hypr/looknfeel.lua`)

```lua
hl.config({
  general = {
    gaps_in = 5,          -- Inner gaps between windows
    gaps_out = 10,        -- Outer gaps to screen edge
    border_size = 2,      -- Window border width
    layout = "dwindle",   -- or "scrolling" (niri-like) / "master"
  },
  decoration = {
    rounding = 0,         -- Window corner rounding
    shadow  = { enabled = false },
    blur    = { enabled = false },
  },
})
```

Animations use named curves (`easeOutQuint`, `almostLinear`, `linear`, `quick`) defined via `hl.curve(...)` and applied with `hl.animation({ leaf = "windows", speed = 3.79, bezier = "easeOutQuint" })`.

### Omarchy Shell (`~/.config/omarchy/shell.json`)

The bar, notifications, control centers, OSD, and lock screen all run inside a single Quickshell process (`omarchy-shell`). `shell.json` controls:

```jsonc
{
  "version": 1,
  "idle": { "screensaver": 150, "lock": 300 },   // seconds since idle
  "bar": {
    "position": "top",
    "transparent": false,
    "centerAnchor": "omarchy.clock",
    "layout": {
      "left":   [ { "id": "omarchy.menu" }, { "id": "omarchy.workspaces" } ],
      "center": [ { "id": "omarchy.indicators" }, { "id": "omarchy.clock" }, { "id": "omarchy.weather" }, { "id": "omarchy.system-update" } ],
      "right":  [ { "id": "omarchy.tray" }, { "id": "omarchy.model-usage" }, { "id": "omarchy.bluetooth" }, { "id": "omarchy.network" }, { "id": "omarchy.audio" }, { "id": "omarchy.monitor" }, { "id": "omarchy.power" }, { "id": "hancore.shibumi.control-center" } ]
    }
  },
  "plugins": [ { "id": "community.window-switcher" }, ... ],
  "disabledPlugins": [ "omarchy.lock" ]
}
```

The shell hot-reloads `shell.json` on save. `idle.screensaver` and `idle.lock` are seconds since user idle began.

### Window Rules

Window rules live in Lua and use Omarchy's `o.window(match, rules)` helper (see `/usr/share/omarchy/default/hypr/windows.lua`). Always consult the current Hyprland wiki before writing rules, as the syntax changes frequently: https://wiki.hypr.land/Configuring/Window-Rules/

---

## Theme System

The theme system is one of Omarchy's most powerful features. A single `colors.toml` file drives colors across all applications.

### Theme File Structure

Each theme (in `/usr/share/omarchy/themes/<theme-name>/`) contains:

| File | Purpose | Required |
|------|---------|----------|
| `colors.toml` | Color definitions (accent, background, foreground, color0-15) | ✅ Yes |
| `vscode.json` | VS Code theme extension name | No |
| `neovim.lua` | LazyVim/Neovim configuration | No |
| `btop.theme` | btop system monitor colors | No |
| `icons.theme` | GNOME icon theme name | No |
| `chromium.theme` | Browser theme RGB values | No |
| `keyboard.rgb` | Keyboard RGB lighting config | No |
| `preview.png` | Theme preview image | No |
| `backgrounds/` | Wallpaper images (0-3*.jpg/png) | No |
| `hyprland.lua` | Hyprland-specific config overrides | No |

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

### Built-in Themes (22)

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
| catppuccin-latte | Light catppuccin | `#1e66f5` (blue) | Yes |
| kanagawa | `#1f1f28` (dark blue) | `#7e99a0` (muted teal) | No |
| miasma | `#1f1d2e` (dark purple) | `#cba6f7` (mauve) | No |
| ristretto | `#2a2a2a` (dark gray) | `#d4a373` (brown) | No |
| retro-82 | `#0f0f0f` (near black) | `#00ff00` (green) | No |
| osaka-jade | `#0f1419` (dark) | `#81c8be` (jade) | No |
| matte-black | `#1a1a1a` (matte black) | `#c9c5b8` (off-white) | No |
| hackerman | `#0a0a0a` (matrix black) | `#00ff41` (matrix green) | No |
| gruvbox | `#282828` (dark gray) | `#d65d0e` (orange) | No |
| ethereal | `#14101f` (deep purple) | `#c792ea` (orchid) | No |
| last-horizon | `#1c1c1c` (near black) | `#7f8490` (steel) | No |
| lumon | `#1b1d1f` (dark slate) | `#d8e2e8` (ice blue) | No |
| lupine | `#202026` (dark blue-gray) | `#f2a7b3` (rose) | No |
| solitude | `#0d1117` (near black) | `#58a6ff` (blue) | No |

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

Built-in templates (in `/usr/share/omarchy/default/themed/`):
- `alacritty.toml.tpl`, `foot.ini.tpl`, `ghostty.conf.tpl`, `kitty.conf.tpl` — terminal colors
- `hyprland.lua.tpl` — Hyprland border/group colors
- `btop.theme.tpl` — system monitor colors
- `chromium.theme.tpl`, `vscode-theme.json.tpl`, `claude.json.tpl`, `pi.json.tpl` — app themes
- `helix.toml.tpl`, `neovim.lua.tpl`, `obsidian.css.tpl` — editor themes
- `keyboard.rgb.tpl`, `gum_env.lua.tpl`, `shell.toml.tpl` — misc

User overrides go in `~/.config/omarchy/themed/*.tpl`.

### How Theme Setting Works

When you run `omarchy theme set <theme-name>` (`omarchy-theme-set`):

1. **Resolve theme**: Prefers a user-installed copy in `~/.config/omarchy/themes/<name>/`, otherwise uses the built-in `/usr/share/omarchy/themes/<name>/`
2. **Generate templates**: `omarchy-theme-set-templates` processes every `*.tpl` file (built-in + user `~/.config/omarchy/themed/`), substituting `{{ variable }}`, `{{ variable_strip }}`, `{{ variable_rgb }}`
3. **Atomic swap**: Generated configs are written to `~/.local/state/omarchy/current/theme/`
4. **Store theme name**: Writes `~/.local/state/omarchy/current/theme.name`
5. **Set background**: Cycles to the next background image (`~/.local/state/omarchy/current/background` symlink)
6. **Restart components**: Shell palette, terminal(s), btop, opencode, Hyprland reload
7. **Update app-specific themes**: GNOME, Chromium/Brave, VS Code/Codium/Cursor, Obsidian, keyboard RGB
8. **Call hooks**: Runs scripts in `~/.config/omarchy/hooks/theme-set.d/` with exported color variables

### Theme Commands

```bash
omarchy theme list          # List available themes
omarchy theme current       # Show current theme
omarchy theme set <name>    # Apply theme ("Tokyo Night" and "tokyo-night" both work)
omarchy theme refresh       # Rebuild current theme from templates
omarchy theme install <url> # Install a theme from git
omarchy theme update        # Update user-installed git themes
omarchy theme remove <name> # Remove a user-installed theme
omarchy theme bg next       # Cycle background
omarchy theme bg set <img>  # Set specific background
omarchy theme bg install    # Open the user background folder
```

### Shell Plugins & the Bar

Bar widgets are **shell plugins**. Built-in plugins ship in `/usr/share/omarchy/shell/plugins/`; user plugins live in `~/.config/omarchy/plugins/<owner>.<id>/`.

```bash
omarchy plugin list                     # List discovered plugins
omarchy plugin enable <id> [placement]  # Enable a plugin
omarchy plugin disable <id>             # Disable a plugin
omarchy plugin clone <id>               # Clone a built-in plugin into user config
omarchy plugin add <git-url>            # Install a plugin from git
omarchy plugin update <id>              # Update git plugins
omarchy bar move <id> <placement>       # Move a widget in the bar
```

To customize a built-in widget, never edit `/usr/share/omarchy/shell/plugins/`. Clone it into the user directory instead:

```bash
omarchy plugin clone omarchy.workspaces
# Edit ~/.config/omarchy/plugins/<username>.workspaces/; saved changes reload automatically.
```

### Keyboard RGB Theming

For supported keyboards (ASUS ROG, Framework 16):

**ASUS ROG**: uses `asusctl` to set keyboard colors, reading `keyboard.rgb` from the theme.
**Framework 16**: uses `qmk_hid` via Python, converting RGB to HSV for QMK firmware and setting per-layer colors.

---

## Autostart Mechanism

Omarchy uses multiple autostart mechanisms to launch applications and services.

### 1. Hyprland `autostart.lua` (Primary Method)

Location: `/usr/share/omarchy/default/hypr/autostart.lua`

```lua
hl.on("hyprland.start", function()
  hl.exec_cmd("systemctl --user import-environment $(env | cut -d'=' -f 1)")
  hl.exec_cmd("dbus-update-activation-environment --systemd --all")

  hl.exec_cmd("quickshell -n -p $OMARCHY_PATH/shell")   -- Omarchy Shell
  hl.exec_cmd("omarchy-first-run")
  hl.exec_cmd("omarchy-powerprofiles-init")
  hl.exec_cmd(o.launch("omarchy-hyprland-monitor-watch"))  -- Monitor hotplug
  hl.exec_cmd(o.launch("udiskie --automount --no-notify --no-tray"))

  -- Run post-boot hooks after startup config has loaded.
  hl.exec_cmd("sleep 2 && omarchy-hook post-boot")
end)
```

### 2. Systemd User Services

| Service | Purpose |
|---------|---------|
| `voxtype.service` | Voxtype dictation daemon (if installed) |
| `graphical-session-pre.target.wants` | Pre-session services (e.g., monitor recovery) |
| `graphical-session.target.wants` | Session services |
| `default.target.wants` | Always-on services |

### 3. First-Run Script (`omarchy first run`)

Runs once after first login to finish user setup: battery monitoring, firewall, DNS, GNOME theme, git/SSH, default keyring, and a welcome notification.

### 4. Shell Services

The Omarchy Shell runs several Quickshell services from `/usr/share/omarchy/shell/services/`: `bar`, `menu`, `notifications`, `osd`, `clipboard`, `emojis`, `lock`, `panels`, `reminders`, `image-picker`, `dev-gallery`, and more.

---

## Bin Scripts Reference

All Omarchy commands are dispatched through the single `omarchy` CLI: `omarchy <group> <action> [args...]`. Under the hood each maps to an `omarchy-*` script in `/usr/share/omarchy/bin/`.

```bash
omarchy commands            # List every documented command
omarchy <group> --help      # Show commands in a group
omarchy <group> <action> --help  # Help for a specific command
omarchy commands --json     # Machine-readable listing
```

### Naming/Group Conventions

| Group | Purpose | Prefix |
|-------|---------|--------|
| `omarchy audio` | Audio control | `audio-*` |
| `omarchy bar` | Bar layout and widgets | `bar-*` |
| `omarchy battery` | Battery status | `battery-*` |
| `omarchy brightness` | Display/keyboard brightness | `brightness-*` |
| `omarchy capture` | Screenshots and recording | `capture-*` |
| `omarchy default` | Default app/agent/terminal/editor | `default-*` |
| `omarchy hw` | Hardware detection (exit codes) | `hw-*` |
| `omarchy launch` | Launch applications | `launch-*` |
| `omarchy menu` | Omarchy menus | `menu-*` |
| `omarchy notification` | Notifications | `notification-*` |
| `omarchy pkg` | Package management | `pkg-*` |
| `omarchy plugin` | Shell plugin management | `plugin-*` |
| `omarchy plymouth` | Boot splash | `plymouth-*` |
| `omarchy refresh` | Copy defaults to ~/.config | `refresh-*` |
| `omarchy restart` | Restart components | `restart-*` |
| `omarchy setup` | Interactive setup wizards | `setup-*` |
| `omarchy theme` | Theme management | `theme-*` |
| `omarchy toggle` | Toggle features on/off | `toggle-*` |
| `omarchy update` | Updates | `update-*` |
| `omarchy remove` | Remove installs | `remove-*` |

### Audio (`audio-*`)

| Command | Purpose |
|---------|---------|
| `omarchy audio output volume <raise|lower|mute-toggle|+N|-N>` | Adjust volume, show OSD |
| `omarchy audio output switch` | Switch output while preserving mute |
| `omarchy audio output sink` | Print the effective sink |
| `omarchy audio input set default <node> <name>` | Set default input |
| `omarchy audio input mute` | Toggle mic mute (drives hardware LED) |
| `omarchy audio source switch [next|previous]` | Cycle media source |
| `omarchy audio tuning <on|off|status>` | Speaker tuning for supported laptops |

### Brightness (`brightness-*`)

| Command | Purpose |
|---------|---------|
| `omarchy brightness display [+N%|N%-|off|on]` | Adjust display brightness (`brightnessctl` + OSD) |
| `omarchy brightness display ddc <monitor> [...]` | DDC/CI display brightness |
| `omarchy brightness display apple [...]` | Apple Studio/XDR brightness (`asdcontrol`) |
| `omarchy brightness keyboard <up|down|cycle|off|restore>` | Keyboard backlight |
| `omarchy brightness keyboard mute <on|off>` | Mic-mute LED |

### Battery (`battery-*`)

| Command | Purpose |
|---------|---------|
| `omarchy battery present` | Exit 0 if a battery exists |
| `omarchy battery status [--shell]` | "Battery 85% · 2h 30m left · ↓ 12W / 50Wh" |
| `omarchy power present` | Exit 0 if AC power connected |

### Capture (`capture-*`)

| Command | Purpose |
|---------|---------|
| `omarchy capture screenshot [smart|region|windows|fullscreen] [slurp|copy|save]` | Take a screenshot (satty editor) |
| `omarchy capture screenrecording [--fullscreen] [--with-audio] [--with-webcam]` | GPU-accelerated recording |
| `omarchy capture screenrecording with webcam` | Recording with webcam overlay |
| `omarchy capture webcam resize <smaller|larger|reset>` | Resize webcam overlay |
| `omarchy capture text` | Extract text from a screenshot region (OCR) |

### Defaults (`default-*`)

| Command | Purpose |
|---------|---------|
| `omarchy default terminal [alacritty|foot|ghostty|kitty]` | Set default terminal (`xdg-terminal-exec`) |
| `omarchy default browser [chromium|chrome|brave|edge|firefox|zen]` | Set default browser |
| `omarchy default editor [code|cursor|zed|helix|vim|emacs|nvim]` | Set default editor |
| `omarchy default agent [pi|omp|opencode|claude|codex|grok|gemini|copilot|crush]` | Set and launch default coding agent |

### Hardware Detection (`hw-*`)

These return exit codes for use in conditionals:

| Script | Detects |
|--------|---------|
| `omarchy-hw-intel` / `omarchy-hw-intel-ptl` / `omarchy-hw-intel-sof` | Intel CPU / Panther Lake / SOF audio |
| `omarchy-hw-nvidia` / `omarchy-hw-nvidia-gsp` / `omarchy-hw-nvidia-without-gsp` | NVIDIA GPU / GSP firmware |
| `omarchy-hw-hybrid-gpu` | Hybrid GPU |
| `omarchy-hw-asus-rog` / `omarchy-hw-asus-expertbook-b9406` / `omarchy-hw-asus-zenbook-ux5406aa` | ASUS machines |
| `omarchy-hw-framework16` | Framework Laptop 16 |
| `omarchy-hw-dell-xps-oled` / `omarchy-hw-dell-xps-haptic-touchpad` | Dell XPS panels/touchpads |
| `omarchy-hw-surface` | Microsoft Surface |
| `omarchy-hw-fingerprint` | Fingerprint reader |
| `omarchy-hw-touchpad` / `omarchy-hw-touchscreen` | Input devices |
| `omarchy-hw-laptop` / `omarchy-hw-clamshell` / `omarchy-hw-laptop-closed` | Laptop form factors |
| `omarchy-hw-display` / `omarchy-hw-external-monitors` / `omarchy-hw-webcam` | Outputs/cameras |
| `omarchy-hw-vulkan` | Vulkan availability |
| `omarchy-hw-match "pattern"` | Match DMI product name |

### Launchers (`launch-*`)

| Command | Purpose |
|---------|---------|
| `omarchy launch terminal [command...]` | Launch terminal in the active terminal's cwd |
| `omarchy launch terminal tmux` | Launch/attach the Work tmux session |
| `omarchy launch browser [--private]` | Default browser |
| `omarchy launch editor` | `$EDITOR` (nvim) |
| `omarchy launch webapp <url>` | URL as a standalone web app |
| `omarchy launch tui <cmd>` | TUI in terminal with Omarchy styling |
| `omarchy launch spotify` / `omarchy launch signal` | Launch or install when missing |
| `omarchy launch screensaver` | TTE screensaver in a styled terminal |
| `omarchy launch or focus <pattern> <cmd>` | Launch or focus a window |

### Menus (`menu-*`)

| Command | Purpose |
|---------|---------|
| `omarchy menu [toggle|summon|close|refresh|ping] [route]` | Control the Omarchy menu |
| `omarchy menu keybindings` | Interactive keybinding search |
| `omarchy menu tmux keybindings` | Annotated tmux keybindings |
| `omarchy menu clipboard` / `omarchy menu emoji` | Clipboard manager / emoji picker |
| `omarchy menu select` / `omarchy menu input` | Generic option/text pickers |
| `omarchy menu images` / `omarchy menu file` | Image/file pickers |

### Notifications (`notification-*`)

| Command | Purpose |
|---------|---------|
| `omarchy notification send [-g glyph] [-u urgency] <headline> [description]` | Send an Omarchy notification |
| `omarchy notification time` / `battery` / `weather` | Time/battery/weather panels |
| `omarchy notification dismiss <summary>` | Dismiss by summary |
| `omarchy reminder <minutes> [message]` | Set a desktop reminder |
| `omarchy osd [-i icon] [-m text] [-p progress]` | Show the Quickshell OSD |

### Package Management (`pkg-*`)

| Command | Purpose |
|---------|---------|
| `omarchy pkg add <pkgs...>` | Install Arch packages if missing |
| `omarchy pkg drop <pkgs...>` | Remove packages (ignore if absent) |
| `omarchy pkg present` / `omarchy pkg missing` | Exit-code checks |
| `omarchy pkg install` / `omarchy pkg remove` | Fuzzy-finder TUIs |
| `omarchy pkg aur add <pkgs...>` | Install AUR packages (yay) |
| `omarchy pkg aur install` | Fuzzy-find AUR packages |
| `omarchy pkg aur accessible` | Exit 0 if AUR is reachable |

### Plugin Management (`plugin-*`)

See the [Shell Plugins & the Bar](#shell-plugins--the-bar) section.

### Plymouth (`plymouth-*`)

| Command | Purpose |
|---------|---------|
| `omarchy plymouth set <bg-hex> <text-hex> <logo.png>` | Set boot theme colors and logo |
| `omarchy plymouth set by theme <theme>` | Theme the boot splash from an Omarchy theme |
| `omarchy plymouth preview ...` | Preview a boot screen |
| `omarchy plymouth reset` | Restore defaults |
| `omarchy plymouth current` / `list` | Show/list boot themes |

### Refresh (`refresh-*`)

Reset user config to defaults (backs up first):

| Command | Purpose |
|---------|---------|
| `omarchy refresh shell` | Reset `shell.json` |
| `omarchy refresh hyprland` | Reset all Hyprland Lua configs |
| `omarchy refresh config <path>` | Copy one shipped config (e.g., `omarchy/shell.json`) |
| `omarchy refresh hyprsunset` / `tmux` / `chromium` | Refresh specific configs |
| `omarchy refresh pacman` | Reset pacman config + mirror, update packages |
| `omarchy refresh plymouth` / `limine` / `sddm` | Rebuild boot components |
| `omarchy refresh applications` | Reinstall launchers and mise wrappers |

### Restart (`restart-*`)

| Command | Purpose |
|---------|---------|
| `omarchy restart shell` | Restart the Omarchy Shell |
| `omarchy restart terminal` | Reload all supported terminals |
| `omarchy restart hyprctl` | Reload Hyprland config |
| `omarchy restart hyprsunset` | Restart night light |
| `omarchy restart app <name>` | Kill + relaunch via uwsm |
| `omarchy restart audio` | Restart audio services, recover stuck USB devices |
| `omarchy restart btop` / `opencode` / `tmux` | Reload their configs |

### Setup (`setup-*`)

| Command | Purpose |
|---------|---------|
| `omarchy setup system` | Apply Omarchy system setup |
| `omarchy setup hardware` | Apply hardware-specific config |
| `omarchy setup lock` | Configure Quickshell lock screen auth |
| `omarchy setup security fingerprint` | Fingerprint auth (sudo/polkit/lock) |
| `omarchy setup security fido2` | FIDO2 auth |
| `omarchy setup security sshd [--key=...]` | OpenSSH server setup |
| `omarchy setup direct boot` | Add EFI boot entry for the Omarchy UKI |

### Theme (`theme-*`)

See the [Theme System](#theme-system) section.

### Toggles (`toggle-*`)

Toggle scripts create/remove flag files in `~/.local/state/omarchy/toggles/`. Presence = enabled, absence = disabled.

| Command | Purpose |
|---------|---------|
| `omarchy toggle <flag> [toggle|on|off]` | Generic toggle |
| `omarchy toggle enabled <flag>` | Check if enabled |
| `omarchy toggle bar` | Toggle bar visibility (keeps shell running) |
| `omarchy toggle nightlight [--status]` | Night light (blue light filter) |
| `omarchy toggle notification silencing` | Do-not-disturb |
| `omarchy toggle idle [toggle|stay-awake|allow-idle|status]` | Idle behavior |
| `omarchy toggle screensaver` / `suspend` | Feature availability |
| `omarchy toggle touchpad [on|off|toggle]` | Touchpad |
| `omarchy toggle touchscreen [on|off|toggle]` | Touchscreen |
| `omarchy toggle hybrid gpu` | Switch GPU mode via supergfxd |

### Update (`update-*`)

| Command | Purpose |
|---------|---------|
| `omarchy update [-y]` | Full update (packages + migrations + restarts) |
| `omarchy update system pkgs` | pacman update |
| `omarchy update aur pkgs` | AUR update |
| `omarchy update keyring` | Refresh keyrings |
| `omarchy update firmware` | fwupd firmware update |
| `omarchy update analyze logs` | Check update log for failures |
| `omarchy update orphan pkgs` | Remove orphans |
| `omarchy update available` | Check for updates |
| `omarchy update restart` | Prompt for reboot/restarts after update |

### System (`system-*`)

| Command | Purpose |
|---------|---------|
| `omarchy system lock` | Lock and turn off display |
| `omarchy system logout` / `reboot` / `shutdown` | Session control (closes windows first) |
| `omarchy system wake` | Wake displays, restore brightness |
| `omarchy system stats [--bar-widget]` | CPU/memory stats for the shell |
| `omarchy version` | Print installed version |
| `omarchy version channel` | Active mirror + channel |
| `omarchy channel set <stable|rc|edge|dev>` | Switch channel |

### Other Important Commands

| Command | Purpose |
|---------|---------|
| `omarchy debug [--no-sudo] [--print]` | Generate debug info |
| `omarchy migrate [--pending]` | Run pending migrations |
| `omarchy migrate notify` | Notify when migrations are pending |
| `omarchy dev add migration [--no-edit]` | Create a new migration |
| `omarchy dev link <path>` / `omarchy dev unlink` | Point Omarchy at a dev checkout |
| `omarchy hook install <name> <script>` | Install an automation hook |
| `omarchy install docker dbs` | DBs in Docker (see Applications) |
| `omarchy install dev env <env>` | Dev environment (mise) |
| `omarchy install voxtype` | Dictation setup |
| `omarchy remove gaming steam` / `heroic` / etc. | Remove gaming setups |
| `omarchy snapshot <create|restore>` | Snapper snapshots |
| `omarchy transcode ...` | Transcode images/video |
| `omarchy share <clipboard|file|folder>` | LocalSend sharing |
| `omarchy dns [Cloudflare|Google|DHCP|Custom]` | DNS provider |
| `omarchy font list` / `font current` / `font set` | Monospace font |
| `omarchy display text size [size|reset]` | Scale text everywhere |
| `omarchy sudo passwordless [MINUTES]` | Passwordless sudo toggle |
| `omarchy shell <target> <method> [args...]` | IPC call into the running shell |
| `omarchy upgrade to quattro` | Migrate legacy install to package layout |

---

## Applications Installed

### Base System Packages (`omarchy-base.packages`)

**Core Wayland Stack:**
- `hyprland`, `hyprland-guiutils`, `hyprland-preview-share-picker`, `hyprpicker`, `hyprsunset`
- `quickshell-git` — the Omarchy Shell engine
- `uwsm` — Wayland session manager
- `xdg-desktop-portal-hyprland`, `xdg-desktop-portal-gtk`, `xdg-terminal-exec`

**Desktop Components:**
- `grim`, `slurp`, `satty` — screenshots
- `gpu-screen-recorder` — GPU-accelerated recording
- `tesseract` — OCR
- `localsend` — sharing
- `clipboard`: `wl-clipboard`, `wtype`
- `swaybg` (via hyprland), OSD is provided by the Omarchy Shell

**Terminals:**
- `alacritty` (default), `ghostty`, `foot` (all themed)

**Shell & CLI:**
- `bash-completion`, `starship`, `tmux`, `zoxide`, `eza`, `fd`, `ripgrep`, `fzf`, `bat`, `jq`, `tldr`, `plocate`, `mise`, `git`

**Editors & Development:**
- `nvim` + `omarchy-nvim` (LazyVim distribution)
- `helix`, `tree-sitter-cli`, `luarocks`, `clang`, `llvm`, `ruby`, `python-gobject`, `python-poetry-core`, `dotnet-runtime`, `mise`

**File Management:**
- `nautilus` + `nautilus-python`, `gvfs-mtp`, `gvfs-nfs`, `gvfs-smb`, `sushi` (file previews)

**Multimedia:**
- `mpv` + `mpv-mpris`, `imv`, `obs-studio`, `kdenlive`, `pinta`, `cliamp` (music TUI), `yt-dlp`

**Office & Productivity:**
- `obsidian`, `xournalpp`, `libreoffice-fresh`, `evince`, `omawrite`, `omacalc`

**System Tools:**
- `docker`, `docker-buildx`, `docker-compose`, `lazydocker`, `lazygit`
- `btop`, `dua-cli`, `brightnessctl`, `ddcutil`, `pamixer`, `asdcontrol`
- `pipewire`, `wireplumber` (via `omarchy-other.packages`)
- `networkmanager`, `bluez`, `iwd`, `bluetui`, `bolt`, `cups`
- `power-profiles-daemon`, `ufw` + `ufw-docker`, `gnome-keyring`, `libsecret`
- `fastfetch`, `inxi`, `imagemagick`, `ffmpegthumbnailer`
- `yay`, `expac`, `pacman-contrib`

**Fonts:**
- `ttf-jetbrains-mono-nerd-basic` — primary monospace font
- `ttf-ia-writer` — writing font
- `noto-fonts`, `noto-fonts-cjk`, `noto-fonts-emoji`
- `woff2-font-awesome` — icon font
- `yaru-icon-theme` — icon theme

### Web Applications

Installed as `.desktop` entries in `/usr/share/omarchy/applications/`, launched as standalone windows via `omarchy-launch-webapp`:

| Application | URL |
|-------------|-----|
| HEY | https://app.hey.com |
| Basecamp | https://launchpad.37signals.com |
| WhatsApp | https://web.whatsapp.com/ |
| Google Photos | https://photos.google.com/ |
| Google Contacts | https://contacts.google.com/ |
| Google Messages | https://messages.google.com/ |
| Google Maps | https://maps.google.com/ |
| ChatGPT | https://chatgpt.com/ |
| YouTube | https://youtube.com/ |
| X (Twitter) | https://x.com/ |
| Discord | https://discord.com/ |
| Zoom | https://app.zoom.us/ |

### TUI Applications

- **Disk Usage**: runs `dua-cli` in a floating terminal
- **Docker**: runs `lazydocker` in a tiled terminal
- **Music**: runs `cliamp`

### Preinstalled Applications

- **Neovim** — `omarchy-nvim` LazyVim distribution
- **Obsidian**, **Typora** (optional), **xournalpp**
- **1Password** (optional), **Signal** (optional), **Spotify** (optional)
- **Gaming** (optional): Steam, Heroic, Lutris, Battle.net, Minecraft, RetroArch, Xbox Cloud, GeForce NOW (installed via `omarchy install gaming ...` / removed via `omarchy remove gaming ...`)

### Dev Environments

Via `omarchy install dev env <env>` (mise-backed): Ruby, Node.js, Bun, Deno, Go, PHP/Laravel/Symfony, Python, Elixir/Phoenix, Rust, Java, Zig, .NET, OCaml, Clojure, Scala.

### Docker Databases

Via `omarchy install docker dbs [db...]`: MySQL (3306), PostgreSQL (5432), Redis (6379), MongoDB (27017), MariaDB (3306), MSSQL (1433).

### Voxtype Dictation

Via `omarchy install voxtype`:
- `voxtype` — local voice typing
- `wtype` — Wayland typing simulation
- Downloads an AI model (~150MB), configures a systemd service
- Toggle with `Super + Ctrl + X` (or `F9` push-to-talk)

### Coding Agents

`omarchy default agent <name>` sets and launches a default coding agent: `opencode`, `codex`, `gemini`, `claude`, `copilot`, `grok`, `pi`, `omp`, `crush`.

---

## Key Bindings

Omarchy defines keybindings in Lua using the described `o.bind(...)` helper. View all bindings interactively with `omarchy menu keybindings` (`Super + K`).

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
| `Super + J` | Toggle window split |
| `Super + P` | Pseudo-window |
| `Super + T` | Toggle floating/tiling |
| `Super + F` | Full screen |
| `Super + Ctrl + F` | Tiled full screen |
| `Super + Alt + F` | Full width (maximized) |
| `Super + O` | Pop window out (float + pin) |
| `Super + Alt + Home` | Save window width |
| `Super + Home` | Restore window width |
| `Super + L` | Toggle workspace layout |

### Focus Movement

| Keybinding | Action |
|------------|--------|
| `Super + Left/Right/Up/Down` | Focus window in direction |
| `Super + Tab` | Next workspace |
| `Super + Shift + Tab` | Previous workspace |
| `Super + Ctrl + Tab` | Former workspace |
| `Alt + Tab` / `Alt + Shift + Tab` | Cycle windows (next/previous, bring to top) |
| `Ctrl + Alt + Tab` | Next monitor |
| `Ctrl + Alt + Shift + Tab` | Previous monitor |

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
| `Super + =/-` | Expand/shrink window width |
| `Super + Shift + =/-` | Resize window vertically |
| `Super + Alt + =/-` | Fine resize (25px) |
| `Super + Ctrl + =/-` | Coarse resize (300px) |
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
| `Super + /` | Monitor scaling up |
| `Super + Alt + /` | Monitor scaling down |

### Workspace Scroll

| Keybinding | Action |
|------------|--------|
| `Super + Scroll` | Scroll through workspaces |

### Menus & Panels

| Keybinding | Action |
|------------|--------|
| `Super + Space` | Omarchy menu |
| `Super + Escape` | System menu |
| `Super + K` | Show keybindings |
| `Super + Alt + K` | Show tmux keybindings |
| `Super + Ctrl + E` | Emojis |
| `Super + Ctrl + C` | Capture menu |
| `Super + Ctrl + O` | Toggle menu |
| `Super + Ctrl + H` | Hardware menu |
| `Super + Ctrl + Space` | Background switcher |
| `Super + Shift + Ctrl + Space` | Theme menu |
| `Super + Shift + Space` | Toggle top bar |
| `Super + Ctrl + A` | Audio panel |
| `Super + Ctrl + B` | Bluetooth panel |
| `Super + Ctrl + D` | Display panel |
| `Super + Ctrl + Alt + D` | Calendar |
| `Super + Ctrl + W` | Network panel |
| `Super + Ctrl + P` | Power panel |
| `Super + Ctrl + T` | Activity (btop) |
| `Super + Shift + Ctrl + A` | Agent |
| `Super + Shift + =` | Calculator |

### Window Appearance

| Keybinding | Action |
|------------|--------|
| `Super + Backspace` | Toggle window transparency |
| `Super + Shift + Backspace` | Toggle window gaps |
| `Super + Ctrl + Backspace` | Toggle single-window square aspect |

### Notifications

| Keybinding | Action |
|------------|--------|
| `Super + ,` | Dismiss last notification |
| `Super + Shift + ,` | Dismiss all notifications |
| `Super + Ctrl + ,` | Toggle notification silencing |
| `Super + Alt + ,` | Invoke last notification |
| `Super + Shift + Alt + ,` | Open notification history |

### System

| Keybinding | Action |
|------------|--------|
| `Super + Ctrl + I` | Toggle locking on idle |
| `Super + Ctrl + N` | Toggle nightlight |
| `Super + Ctrl + Delete` | Toggle laptop display |
| `Super + Ctrl + Alt + Delete` | Toggle display mirroring |
| `Super + Ctrl + L` | Lock system |

### Multimedia Keys

| Keybinding | Action |
|------------|--------|
| `XF86AudioRaise/LowerVolume` | Volume up/down (with OSD) |
| `XF86AudioMute` | Mute |
| `XF86AudioMicMute` | Mute microphone |
| `Alt + AudioRaise/Lower` | 1% volume adjustment |
| `Shift + AudioMute` | Switch audio output |
| `Shift + AudioPause/Play` | Switch media source |
| `XF86AudioNext/Prev/Play/Pause` | Media controls |
| `XF86Eject` | Eject media |

### Brightness

| Keybinding | Action |
|------------|--------|
| `XF86MonBrightnessUp/Down` | Adjust brightness (5% steps) |
| `Shift + MonBrightnessUp/Down` | Brightness max/min |
| `Alt + MonBrightnessUp/Down` | 1% brightness adjustment |

### Keyboard Backlight

| Keybinding | Action |
|------------|--------|
| `XF86KbdBrightnessUp/Down` | Adjust keyboard brightness |
| `XF86KbdLightOnOff` | Cycle keyboard backlight |

### Touchpad & Touchscreen

| Keybinding | Action |
|------------|--------|
| `XF86TouchpadToggle/On/Off` | Toggle touchpad |

### Clipboard

| Keybinding | Action |
|------------|--------|
| `Super + C` | Universal copy |
| `Super + V` | Universal paste |
| `Super + X` | Universal cut |
| `Super + Ctrl + V` | Clipboard manager |

### Applications

| Keybinding | Action |
|------------|--------|
| `Super + Return` | Launch terminal |
| `Super + Alt + Return` | Launch tmux |
| `Super + Shift + Return` / `Super + Shift + B` | Launch browser |
| `Super + Shift + Alt + B` | Launch browser (private) |
| `Super + Shift + F` | Launch file manager |
| `Super + Alt + Shift + F` | Launch file manager (cwd) |
| `Super + Shift + N` | Launch editor (nvim) |

### Preinstalled Applications

| Keybinding | Action |
|------------|--------|
| `Super + Shift + M` | Music (Spotify) |
| `Super + Shift + Alt + M` | Music TUI (cliamp) |
| `Super + Shift + D` | Docker (lazydocker) |
| `Super + Shift + G` | Signal |
| `Super + Shift + O` | Obsidian |
| `Super + Shift + W` | Omawrite |
| `Super + Shift + Slash` | Passwords (1Password) |
| `Super + Shift + A` | ChatGPT |
| `Super + Shift + Alt + A` | Grok |
| `Super + Shift + C` | Calendar (HEY) |
| `Super + Shift + E` | Email (HEY) |
| `Super + Shift + Alt + E` | New email |
| `Super + Shift + Y` | YouTube |
| `Super + Shift + Alt + G` | WhatsApp |
| `Super + Shift + Ctrl + G` | Google Messages |
| `Super + Shift + P` | Google Photos |
| `Super + Shift + S` | Google Maps |
| `Super + Shift + X` | X |
| `Super + Shift + Alt + X` | X Post |

### Screenshots & Recording

| Keybinding | Action |
|------------|--------|
| `Print` | Screenshot |
| `Alt + Print` | Screen recording (toggle) |
| `Super + Print` | Color picker |
| `Super + Ctrl + Print` | Extract text (OCR) from screenshot |
| `Super + Alt + code:34` | Webcam overlay smaller |
| `Super + Alt + code:35` | Webcam overlay larger |
| `Super + Ctrl + S` | Share via LocalSend |
| `Super + Ctrl + .` | Transcode |

### Reminders & Info

| Keybinding | Action |
|------------|--------|
| `Super + Ctrl + R` | Set reminder |
| `Super + Ctrl + Alt + R` | Show reminders |
| `Super + Shift + Ctrl + R` | Clear reminders |
| `Super + Ctrl + Alt + T` | Show time |
| `Super + Ctrl + Alt + B` | Show battery remaining |
| `Super + Ctrl + Alt + W` | Toggle weather |
| `Super + Ctrl + Z` | Zoom in |
| `Super + Ctrl + Alt + Z` | Reset zoom |

### Dictation (if Voxtype installed)

| Keybinding | Action |
|------------|--------|
| `Super + Ctrl + X` | Toggle dictation |
| `F9` | Push-to-talk (start/stop) |

---

## Hooks System

Hooks allow custom scripts to run at specific points in Omarchy's operation. Hooks live in `~/.config/omarchy/hooks/<name>.d/` — one directory per event, holding any number of independent scripts.

### Hook Directories

| Hook Directory | When it runs | Arguments |
|----------------|--------------|-----------|
| `theme-set.d/` | After a theme is set | Theme slug in `$1` |
| `post-boot.d/` | After the desktop starts | — |
| `post-update.d/` | After `omarchy update` | — |
| `pre-refresh-pacman.d/` | Before package sync during update | — |
| `font-set.d/` | After font is changed | Font name in `$1` |
| `battery-low.d/` | Battery low (depends on threshold) | Percentage in `$1` |

### Installing Hooks

```bash
omarchy hook install <name> <script>
```

Copies the script into `~/.config/omarchy/hooks/<name>.d/` and makes it executable.

Example hook script:

```bash
#!/bin/bash
THEME_NAME=$1
echo "Theme changed to: $THEME_NAME"
# Add custom actions here
```

### Theme-Set Hook Details

The main `theme-set` event runs all executable scripts in `~/.config/omarchy/hooks/theme-set.d/`. Child scripts receive exported color variables extracted from `colors.toml`:

- `$primary_foreground`, `$primary_background`
- `$cursor_color`, `$selection_foreground`, `$selection_background`
- `$normal_black` through `$normal_white` (color0-7)
- `$bright_black` through `$bright_white` (color8-15)
- `$rgb_primary_foreground`, `$rgb_primary_background` (decimal RGB)
- All other color variables in RGB format

To mark an app for restart notification from a hook:

```bash
require_restart "app-name"  # Adds to restart list
```

---

## Migration System

Migrations allow Omarchy to evolve the system configuration over time, similar to database migrations.

### How Migrations Work

1. **Migration scripts** are stored in `/usr/share/omarchy/migrations/*.sh`
2. Each script is named after the **unix timestamp** of the git commit that introduced it
3. When `omarchy migrate` runs, it:
   - Iterates through all migration scripts
   - Checks if a corresponding state file exists in `~/.local/state/omarchy/migrations/`
   - If not, runs the migration script
   - On success, records it (touches the state file)
   - On failure, asks to skip (records it under `skipped/`)

### Migration Script Format

Migrations have **no shebang line** and typically start with an echo:

```bash
echo "Disable fingerprint in hyprlock if fingerprint auth is not configured"

if omarchy-cmd-missing fprintd-list || ! fprintd-list "$USER" 2>/dev/null | grep -q "finger"; then
  sed -i 's/fingerprint:enabled = .*/fingerprint:enabled = false/' ~/.config/hypr/hyprlock.conf
fi
```

### Creating a Migration

Use `omarchy dev add migration [--no-edit]` (for Omarchy development):

1. Takes the unix timestamp of the last git commit
2. Creates a new script at `<source-tree>/migrations/<timestamp>.sh`
3. Opens it in an editor (unless `--no-edit`)
4. During `omarchy migrate`, this script will run on all systems

### Migration State Tracking

| Location | Purpose |
|----------|---------|
| `~/.local/state/omarchy/migrations/` | Completed migrations (state files) |
| `~/.local/state/omarchy/migrations/skipped/` | Skipped migrations |

### Migration Count

As of this writing, there are **55 migration scripts** in the migrations directory.

---

## Package Management

Omarchy wraps `pacman` and `yay` (AUR helper) behind a consistent CLI.

### Official Repositories (pacman)

| Command | Purpose |
|---------|--------|
| `omarchy pkg add <pkgs...>` | Install packages (skip if present) |
| `omarchy pkg present <pkgs...>` | Exit 0 if all installed |
| `omarchy pkg missing <pkgs...>` | Exit 0 if any missing |
| `omarchy pkg drop <pkgs...>` | Remove packages (ignore if absent) |
| `omarchy pkg install` | Fuzzy-find official packages to install (fzf) |
| `omarchy pkg remove` | Fuzzy-find installed packages to remove |

### AUR (yay)

| Command | Purpose |
|---------|--------|
| `omarchy pkg aur add <pkgs...>` | Install AUR packages |
| `omarchy pkg aur install` | Fuzzy-find AUR packages to install |
| `omarchy pkg aur accessible` | Exit 0 if the AUR is reachable |

### Package Channels

Omarchy has four channels that determine which pacman mirror is used:

| Channel | Mirror |
|---------|--------|
| `stable` | `stable-mirror.omarchy.org` |
| `rc` | `rc-mirror.omarchy.org` |
| `edge` | `edge-mirror.omarchy.org` |
| `dev` | `dev-mirror.omarchy.org` |

Switch channels with:

```bash
omarchy channel set [stable|rc|edge|dev]
```

This updates `/etc/pacman.conf` and the mirrorlist, then updates packages.

---

## Hardware Support

Omarchy includes extensive hardware support. Detection is done by `omarchy-hw-*` scripts (exit codes) and applied via `omarchy setup hardware` and the `install/hardware/` scripts.

### Intel Systems

| Script | Purpose |
|--------|---------|
| `install/hardware/intel/*` | Video acceleration (VA-API), thermald, lpmd |
| `omarchy-hw-intel-ptl` | Intel Panther Lake GPU |
| `omarchy-hw-intel-sof` | Intel SOF audio |
| `omarchy-hw-intel` | Generic Intel CPU |

### NVIDIA

| Script | Purpose |
|--------|---------|
| `install/hardware/nvidia.sh` | NVIDIA driver + Vulkan config |
| `omarchy-hw-nvidia` / `nvidia-gsp` / `nvidia-without-gsp` | Driver detection |
| `default/hypr/nvidia.lua` | NVIDIA-specific Hyprland env |

### ASUS Laptops

| Script | Purpose |
|--------|---------|
| `install/hardware/asus-rog.sh` | Install asusctl + `omarchy install gaming` support |
| `omarchy-hw-asus-rog` | ROG detection |
| `install/hardware/asus/*` | ExpertBook B9406 / Zenbook UX5406AA fixes |
| Keyboard RGB via asusctl (`keyboard.rgb` theme file) | |

### Framework Laptops

| Script | Purpose |
|--------|---------|
| `install/hardware/framework16.sh` | Install `qmk_hid` |
| `omarchy-hw-framework16` | Framework 16 detection |
| Keyboard RGB via QMK (`keyboard.rgb` theme file) | |

### Apple MacBooks (T2)

| Script | Purpose |
|--------|---------|
| `install/hardware/apple/*` | SPI keyboard, suspend/NVMe, T2 fixes |
| `omarchy-brightness-display apple` | Apple Studio/XDR brightness |

### Microsoft Surface

| Script | Purpose |
|--------|---------|
| `install/hardware/surface.sh` | Surface kernel + firmware |
| `install/hardware/fix-surface-keyboard.sh` | Surface keyboard |
| `omarchy-hw-surface` | Surface detection |

### Dell XPS

| Script | Purpose |
|--------|---------|
| `install/hardware/dell-xps-touchpad-haptics.sh` | Haptic touchpad daemon |
| `omarchy-hw-dell-xps-oled` | OLED panel detection |
| `omarchy-hw-dell-xps-haptic-touchpad` | Haptic touchpad detection |

### Other Hardware

| Script | Purpose |
|--------|---------|
| `install/hardware/bluetooth.sh` | Bluetooth configuration |
| `install/hardware/fix-fkeys.sh` | Function key behavior |
| `install/hardware/fix-synaptic-touchpad.sh` | Synaptic touchpad |
| `install/hardware/fix-tuxedo-backlight.sh` | Tuxedo keyboard backlight |
| `install/hardware/fix-yt6801-ethernet-adapter.sh` | Realtek Ethernet |
| `install/hardware/fix-bcm43xx.sh` | Broadcom WiFi |
| `install/hardware/vulkan.sh` | Vulkan configuration |
| `install/hardware/network.sh` | Network configuration |
| `install/hardware/speaker-tuning.sh` | Speaker tuning (audio tuning) |
| `omarchy-hw-hybrid-gpu` | Hybrid GPU detection (supergfxd) |

### Hardware Detection (`hw-*`)

See the [Bin Scripts Reference](#bin-scripts-reference) for the full `omarchy-hw-*` list.

---

## Summary

Omarchy is a comprehensive Linux distribution that provides:

1. **Complete desktop environment** — Hyprland (Lua-configured) + the Quickshell Omarchy Shell (bar, panels, notifications, OSD, launcher)
2. **Unified theming** — Single `colors.toml` drives colors across 20+ applications
3. **Template system** — `{{ variable }}` placeholders auto-fill with theme colors
4. **Toggle system** — Features enabled/disabled via flag files
5. **Migration system** — Smooth updates as Omarchy evolves
6. **Hook system** — Custom scripts at key points (theme-set, post-boot, post-update, battery-low)
7. **Hardware support** — Extensive laptop support (ASUS, Framework, Apple, Surface, Dell)
8. **Developer tools** — Multiple language runtimes, Neovim, Helix, Docker
9. **AI integration** — Voxtype dictation, coding agents (OpenCode, Codex, Gemini, Copilot, etc.)
10. **Web applications** — Preconfigured web apps with standalone windows

The entire system is managed through the `omarchy` CLI (300+ `omarchy-*` commands) that handle everything from theme switching to package management to hardware configuration.
