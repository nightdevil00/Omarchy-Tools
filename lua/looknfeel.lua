-- Change the default Omarchy look'n'feel.

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
 hl.config({
   general = {
--     -- No gaps between windows or borders.
    gaps_in = 0,
     gaps_out = 0,
    border_size = 0,
--
--     -- Change to niri-like side-scrolling layout.
--     layout = "scrolling",
   },
 })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
 hl.config({
  decoration = {
--     -- No rounded window corners (1.0.0+ / 0.37+).
    rounding = 0,
--
--     -- Disable window transparency.
    active_opacity = 1,
    inactive_opacity = 1,
--
--     -- Dim unfocused windows (0.0 = no dim, 1.0 = fully dimmed).
    dim_inactive = true,
     dim_strength = 0.15,
  },
 })

-- Neutralize the opacity Omarchy applies to every window via the
-- "default-opacity" tag (active 0.985 / inactive 0.96).
o.window(".*", { opacity = "1 override 1 override" })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
 hl.config({
   animations = {
--     -- Disable all animations.
     enabled = false,
  },
 })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
-- hl.config({
--   layout = {
--     -- Avoid overly wide single-window layouts on wide screens.
--     single_window_aspect_ratio = { 1, 1 },
--   },
-- })

-- Disable window transparency (frame_alpha = 0 means no alpha/transparency)


-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
-- hl.config({
--   scrolling = {
--     -- See only one column per screen instead of two.
--     column_width = 0.97,
--   },
-- })
