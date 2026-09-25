-- Personal window rules, loaded after Omarchy's defaults.

-- Omarchy tags every window and applies a slight transparency
-- (default/hypr/windows.lua: opacity 0.985 active / 0.96 inactive).
-- Force every window fully opaque.

o.window(".*", { opacity = "1 1" })
