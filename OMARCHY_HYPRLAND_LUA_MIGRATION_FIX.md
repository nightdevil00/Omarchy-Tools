# Omarchy Hyprland Lua Migration Fix

## Problem

Omarchy's migration script `1778321093.sh` converted Hyprland config from `.conf` to `.lua` files, but two things went wrong:

### 1. Missing default Lua modules

The user-facing `~/.config/hypr/hyprland.lua` uses `require()` to load Omarchy's default configs:

```lua
require("default.hypr.paths")
require("default.hypr.autostart")
require("default.hypr.bindings.media")
require("default.hypr.envs")
require("default.hypr.looknfeel")
require("default.hypr.input")
require("default.hypr.windows")
require("default.hypr.toggles")
-- etc.
```

These default Lua modules (`default/hypr/*.lua`) only exist on the `origin/omarchy-4` branch — they were **never merged into master** (v3.8.2). The migration ran but the files it depended on didn't exist, causing Hyprland to fail to load the config entirely (black screen, unable to boot to desktop).

### 2. User customizations lost

The migration backed up the old `.conf` files as `*.conf.bak.*` and copied stock default `.lua` templates. The user's custom settings (Polish keyboard layout, custom keybindings) were not ported to the `.lua` files.

### 3. Menu paths broken

The `omarchy-menu` script has hardcoded paths to `.conf` files for built-in config editing (Setup → Monitors, Setup → Config, Style → Hyprland, etc.). Since those files no longer exist (they were renamed to `.bak`), menu entries opened empty/phantom files.

---

## Fix Applied

### Fix 1: Created missing default Lua modules

Extracted 36 Lua files from commit `c7b6a7f8` on `origin/omarchy-4` and wrote them to `~/.config/default/hypr/`:

```
~/.config/default/hypr/
├── paths.lua
├── autostart.lua
├── envs.lua
├── looknfeel.lua
├── input.lua
├── windows.lua
├── toggles.lua
├── require_all.lua
├── apps.lua
├── bindings.lua
├── bindings/
│   ├── media.lua
│   ├── clipboard.lua
│   ├── tiling-v2.lua
│   └── utilities.lua
├── apps/
│   ├── 1password.lua, browser.lua, steam.lua, ... (19 files)
└── toggles/
    ├── flags.lua
    ├── window-no-gaps.lua
    └── single-window-aspect-ratio.lua
```

These live in `~/.config/` so Hyprland's Lua `package.path` finds them before the (non-existent) `$OMARCHY_PATH/default/hypr/` location.

### Fix 2: Restored user customizations

- **`~/.config/hypr/input.lua`** — Added `kb_layout = "pl"` (Polish layout)
- **`~/.config/hypr/bindings.lua`** — Restored user's custom keybindings from the most recent `.conf.bak` file:
  - `SUPER + F` → File manager (with `hl.unbind()` to override default fullscreen)
  - `SUPER + M` → Spotify with `--force-device-scale-factor=1`
  - `SUPER + O` → Obsidian (with `hl.unbind()` to override default pop-out)
  - `SUPER + N` → Editor
  - `SUPER + SHIFT + V` → VSCode
  - `SUPER + D` → Discord
  - `SUPER + A/C/E/Y/X` → web apps (no SHIFT modifier)

### Fix 3: Fixed menu config paths

Overrode three menu functions in `~/.config/omarchy/extensions/menu.sh` to point to `.lua` files:

| Menu Path | Old (broken) | New (fixed) |
|-----------|-------------|-------------|
| Style → Hyprland | `looknfeel.conf` | `looknfeel.lua` |
| Setup → Monitors | `monitors.conf` | `monitors.lua` |
| Setup → Keybindings | `bindings.conf` | `bindings.lua` |
| Setup → Input | `input.conf` | `input.lua` |
| Setup → Config → Hyprland | `hyprland.conf` | `hyprland.lua` |

---

## Files modified/created

| File | Action |
|------|--------|
| `~/.config/default/hypr/` (36 files) | Created — missing default Lua modules |
| `~/.config/hypr/input.lua` | Edited — added `kb_layout = "pl"` |
| `~/.config/hypr/bindings.lua` | Rewritten — restored user's custom keybinds |
| `~/.config/omarchy/extensions/menu.sh` | Rewritten — fixed menu `.conf` → `.lua` paths |

## What remains from the original migration

- Old `.conf` backups are at `~/.config/hypr/*.conf.bak.*`
- Other Omarchy services (hypridle, hyprlock, hyprsunset, xdph) still use `.conf` files — unaffected
- Theme override (`~/.config/omarchy/current/theme/hyprland.conf`) is still `.conf` — the Lua config checks for `hyprland.lua` first and skips gracefully if absent

## Potential future issues

- The extension menu overrides won't pick up new menu entries from upstream omarchy updates — compare with `diff` after major updates
- If omarchy-4 is ever merged to master with different default Lua files, the `~/.config/default/hypr/` copies will take precedence (usually fine, but worth reviewing)
