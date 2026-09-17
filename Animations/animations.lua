
-- ============================================================================
-- Hyprland Animations Configuration
-- Niri-inspired animations
--
-- Hyprland 0.55+ Lua configuration
--
-- Reference:
-- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
--
-- Niri source:
--
-- workspace-switch:
--   spring damping-ratio=0.8 stiffness=523 epsilon=0.0001
--
-- window-open:
--   duration-ms 800
--   curve "ease-out-expo"
--   custom shader: fall from top + rotation
--
-- window-close:
--   duration-ms 800
--   curve "linear"
--   custom shader: fall to bottom + rotation
--
-- Hyprland can reproduce the spring, timing, easing and directional
-- movement natively. Niri's custom GLSL rotation cannot be reproduced
-- by the native Hyprland animation styles.
-- ============================================================================


-- ============================================================================
-- 1. Global animations
-- ============================================================================

hl.config({
  animations = {
    enabled = true,
  },
})


-- ============================================================================
-- 2. Curves
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Niri workspace spring
-- ---------------------------------------------------------------------------
--
-- Niri:
--   damping-ratio = 0.8
--   stiffness     = 523
--
-- Hyprland spring:
--   mass       = 1
--   stiffness  = 523
--   dampening  = 36.58
--
-- damping coefficient:
--
--   c = 2 * damping_ratio * sqrt(stiffness * mass)
--     = 2 * 0.8 * sqrt(523 * 1)
--     ~= 36.58
--
-- epsilon=0.0001 has no direct equivalent in Hyprland's Lua
-- animation API, so it cannot be copied directly.

hl.curve("niriSpring", {
  type = "spring",
  mass = 1,
  stiffness = 523,
  dampening = 36.58,
})


-- ---------------------------------------------------------------------------
-- Niri ease-out-expo
-- ---------------------------------------------------------------------------
--
-- Standard cubic-bezier approximation:
-- cubic-bezier(0.16, 1, 0.30, 1)
--
-- This gives the fast initial movement and long final deceleration
-- characteristic of ease-out-expo.

hl.curve("niriExpo", {
  type = "bezier",
  points = {
    { 0.16, 1.0 },
    { 0.30, 1.0 },
  },
})


-- ---------------------------------------------------------------------------
-- Other useful curves
-- ---------------------------------------------------------------------------

hl.curve("easeOutQuint", {
  type = "bezier",
  points = {
    { 0.23, 1.0 },
    { 0.32, 1.0 },
  },
})

hl.curve("easeInOutCubic", {
  type = "bezier",
  points = {
    { 0.65, 0.05 },
    { 0.36, 1.0 },
  },
})

hl.curve("easeOutCubic", {
  type = "bezier",
  points = {
    { 0.33, 1.0 },
    { 0.68, 1.0 },
  },
})

hl.curve("easeOutBack", {
  type = "bezier",
  points = {
    { 0.34, 1.3 },
    { 0.64, 1.0 },
  },
})

hl.curve("linear", {
  type = "bezier",
  points = {
    { 0.0, 0.0 },
    { 1.0, 1.0 },
  },
})

hl.curve("almostLinear", {
  type = "bezier",
  points = {
    { 0.5, 0.5 },
    { 0.75, 1.0 },
  },
})

hl.curve("quick", {
  type = "bezier",
  points = {
    { 0.15, 0.0 },
    { 0.10, 1.0 },
  },
})


-- ============================================================================
-- 3. Workspace animations
-- ============================================================================

-- Niri workspace-switch:
--
--   spring
--   stiffness = 523
--   damping ratio = 0.8
--
-- Hyprland supports spring curves directly.

hl.animation({
  leaf = "workspaces",
  enabled = true,
  speed = 8,
  spring = "niriSpring",
  style = "slide",
})


-- Special workspaces

hl.animation({
  leaf = "specialWorkspace",
  enabled = true,
  speed = 8,
  spring = "niriSpring",
  style = "slidefadevert 20%",
})


-- ============================================================================
-- 4. Window animations
-- ============================================================================

-- General window animation.
--
-- The actual opening/closing animations below override this for
-- windowsIn/windowsOut.

hl.animation({
  leaf = "windows",
  enabled = true,
  speed = 8,
  bezier = "niriExpo",
})


-- ---------------------------------------------------------------------------
-- Window opening
-- ---------------------------------------------------------------------------
--
-- Niri:
--
--   duration-ms 800
--   curve "ease-out-expo"
--   fall from top
--
-- Hyprland:
--
--   speed = 8     -> 800 ms
--   niriExpo      -> ease-out-expo approximation
--   slide top     -> forced entry from the top
--
-- Hyprland's wiki explicitly supports forced slide directions for
-- windows: top, bottom, left and right.

hl.animation({
  leaf = "windowsIn",
  enabled = true,
  speed = 8,
  bezier = "niriExpo",
  style = "slide top",
})


-- ---------------------------------------------------------------------------
-- Window closing
-- ---------------------------------------------------------------------------
--
-- Niri:
--
--   duration-ms 800
--   curve "linear"
--   fall to bottom
--
-- Hyprland:
--
--   speed = 8
--   linear
--   slide bottom

hl.animation({
  leaf = "windowsOut",
  enabled = true,
  speed = 8,
  bezier = "linear",
  style = "slide bottom",
})


-- ---------------------------------------------------------------------------
-- Window movement / resize
-- ---------------------------------------------------------------------------

hl.animation({
  leaf = "windowsMove",
  enabled = true,
  speed = 8,
  bezier = "niriExpo",
})


-- ============================================================================
-- 5. Fade animations
-- ============================================================================
--
-- Niri's custom open/close shader does not explicitly implement a separate
-- opacity fade. Keep the fade subtle so it doesn't change the character
-- of the slide animation excessively.

hl.animation({
  leaf = "fade",
  enabled = true,
  speed = 3,
  bezier = "quick",
})

hl.animation({
  leaf = "fadeIn",
  enabled = true,
  speed = 8,
  bezier = "niriExpo",
})

hl.animation({
  leaf = "fadeOut",
  enabled = true,
  speed = 8,
  bezier = "linear",
})

hl.animation({
  leaf = "fadeSwitch",
  enabled = true,
  speed = 3,
  bezier = "almostLinear",
})


-- ============================================================================
-- 6. Layer animations
-- ============================================================================

hl.animation({
  leaf = "layers",
  enabled = true,
  speed = 4,
  bezier = "easeOutQuint",
})

hl.animation({
  leaf = "layersIn",
  enabled = true,
  speed = 3.5,
  bezier = "easeOutQuint",
  style = "fade",
})

hl.animation({
  leaf = "layersOut",
  enabled = true,
  speed = 2,
  bezier = "linear",
  style = "fade",
})

hl.animation({
  leaf = "fadeLayersIn",
  enabled = true,
  speed = 2,
  bezier = "almostLinear",
})

hl.animation({
  leaf = "fadeLayersOut",
  enabled = true,
  speed = 2,
  bezier = "almostLinear",
})


-- ============================================================================
-- 7. Border animation
-- ============================================================================

hl.animation({
  leaf = "border",
  enabled = true,
  speed = 5,
  bezier = "easeOutQuint",
})
