# Hyprland Animations Configuration for Omarchy

This document details how animations are configured on Omarchy Linux running Hyprland, and provides an idempotent configuration guide suitable for any user.

---

## Overview

Omarchy configures Hyprland using Lua. System defaults reside in `/usr/share/omarchy/default/hypr/`, while user customizations are loaded from `~/.config/hypr/`.

By default in Omarchy:
- Global animations may be set to disabled in the user's template `~/.config/hypr/looknfeel.lua`.
- Workspace transition animations are explicitly disabled in Omarchy's system defaults (`hl.animation({ leaf = "workspaces", enabled = false })`).

To enable smooth animations—including workspace sliding, window resizing/movement, focus fade transitions, and shell layer effects—custom rules must be placed in `~/.config/hypr/looknfeel.lua`.

---

## Configuration File

- **Target File**: `~/.config/hypr/looknfeel.lua`
- **Engine**: Hyprland Lua configuration API (`hl.config`, `hl.curve`, `hl.animation`)

---

## Idempotent Configuration

Add the following block to `~/.config/hypr/looknfeel.lua`. Ensure that any earlier `animations = { enabled = false }` declaration in that file is updated to `enabled = true`.

```lua
-- ============================================================================
-- Hyprland Animations Configuration
-- Reference: https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
-- ============================================================================

-- 1. Enable animations globally
hl.config({
  animations = {
    enabled = true,
  },
})

-- 2. Define Bézier curves
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("easeOutCubic", { type = "bezier", points = { { 0.33, 1 }, { 0.68, 1 } } })
hl.curve("easeOutBack", { type = "bezier", points = { { 0.34, 1.3 }, { 0.64, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

-- 3. Workspace switching animations
-- Styles available: "slide", "slidefade 20%", "slidevert", "slidefadevert 20%", "fade"
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slidefadevert 20%" })

-- 4. Window animations (open, close, moving, tiling resize)
hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.5, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "easeOutQuint" })

-- 5. Fade transitions (switching window focus, open/close fading)
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "quick" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 2, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2, bezier = "almostLinear" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 3, bezier = "almostLinear" })

-- 6. Layer animations (Omarchy shell bar, menus, notifications, launchers)
hl.animation({ leaf = "layers", enabled = true, speed = 4, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 3.5, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 2, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 2, bezier = "almostLinear" })

-- 7. Border color transitions
hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "easeOutQuint" })
```

---

## Installation & Verification Steps

Follow these steps on any user account or machine:

### 1. Back up existing configuration
```bash
cp ~/.config/hypr/looknfeel.lua ~/.config/hypr/looknfeel.lua.bak.$(date +%s)
```

### 2. Apply configuration
Ensure the block above is added to `~/.config/hypr/looknfeel.lua` and any earlier `animations = { enabled = false }` line is set to `true`.

### 3. Reload Hyprland
```bash
hyprctl reload
```

### 4. Check for configuration errors
```bash
hyprctl configerrors
```
*Expected result: Empty output (zero errors).*

### 5. Verify active animation tree
```bash
hyprctl animations
```
*Verify that `workspaces`, `windowsMove`, and other configured animation leaves show `enabled: 1`.*

---

## Customization Guide

### Workspace Animation Styles
- **Horizontal Slide (Default)**:
  ```lua
  hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "easeOutQuint", style = "slide" })
  ```
- **Slide + Fade**:
  ```lua
  hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "easeOutQuint", style = "slidefade 20%" })
  ```
- **Vertical Slide**:
  ```lua
  hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "easeOutQuint", style = "slidevert" })
  ```
- **Crossfade Only**:
  ```lua
  hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "almostLinear", style = "fade" })
  ```

### Adjusting Speeds
- In Hyprland, `speed` is the animation velocity/rate factor: higher values make animations finish faster, while lower values make animations slower and softer.
- Recommended range:
  - Snappy: `speed = 5` to `6`
  - Balanced: `speed = 4`
  - Gentle: `speed = 3`
