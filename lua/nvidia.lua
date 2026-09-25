-- Hybrid Intel + NVIDIA laptops: keep the iGPU's media and GL stack.
--
-- Omarchy's default/hypr/nvidia.lua forces NVIDIA's VA-API and GLX drivers
-- session-wide as soon as an NVIDIA GPU is detected. On a hybrid laptop the
-- display is wired to the iGPU, so those two variables make Chromium-based
-- browsers render video black (audio still playing) and flicker.
--
-- Upstream fixed this by gating them on whether NVIDIA actually drives the
-- display (sysfs boot_vga) in omarchy-hw-nvidia-display; that detector is not in
-- this omarchy install yet, so reproduce the check here.
--
-- hl.env cannot unset a variable, so point them at the display GPU instead.
-- NVD_BACKEND is left alone: upstream keeps it unconditional as harmless.

local function read_file(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end

  local value = file:read("*a")
  file:close()

  return value and value:gsub("%s+$", "")
end

-- True when NVIDIA owns the display, or when we cannot tell and should keep
-- Omarchy's default behavior.
local function nvidia_drives_display()
  local root = os.getenv("OMARCHY_PCI_DEVICES_PATH") or "/sys/bus/pci/devices"

  local listing = io.popen("ls -1 " .. o.shell_quote(root) .. " 2>/dev/null")
  if not listing then
    return true
  end

  local devices = {}
  for name in listing:lines() do
    table.insert(devices, name)
  end
  listing:close()

  local nvidia_owns_boot_vga = false
  local other_owns_boot_vga = false

  for _, name in ipairs(devices) do
    local device = root .. "/" .. name

    -- 0x03xxxx is a VGA-compatible controller.
    local class = read_file(device .. "/class")
    if class and class:match("^0x03") then
      local owns_display = read_file(device .. "/boot_vga") == "1"
      if read_file(device .. "/vendor") == "0x10de" then
        nvidia_owns_boot_vga = nvidia_owns_boot_vga or owns_display
      else
        other_owns_boot_vga = other_owns_boot_vga or owns_display
      end
    end
  end

  if not nvidia_owns_boot_vga and not other_owns_boot_vga then
    return true
  end

  return not (other_owns_boot_vga and not nvidia_owns_boot_vga)
end

if o.cmd_present("omarchy-hw-nvidia") and not nvidia_drives_display() then
  hl.env("LIBVA_DRIVER_NAME", "iHD")
  hl.env("__GLX_VENDOR_LIBRARY_NAME", "mesa")
end
