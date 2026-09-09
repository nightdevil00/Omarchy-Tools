# Lenovo ThinkBook 15p — NBFC-Linux Fan Control Setup

Date: 2026-09-09
Machine: Lenovo ThinkBook 15p (DMI product: `20V3`, board: `LNVNB161216`)

## Goal

Get `nbfc-qt` (and the `nbfc` service) working to control the laptop fan on Linux with NBFC-Linux.

## Environment

- OS: omarchy (Arch-based), kernel `7.2.4-1-omarchy-bore`
- Packages installed: `nbfc-linux 0.4.1-1`, `nbfc-qt 0.5.1`
- No exact default config ships with the package (`/etc/nbfc/nbfc.json` is not created by the package)

## Steps performed

### 1. Diagnosis of failure

- `nbfc status` → `ERROR: connect(): No such file or directory: /run/nbfc_service.socket`
  → service not running.
- `systemctl status nbfc` → no such unit; the real unit is `nbfc_service.service`
  (`/usr/lib/systemd/system/nbfc_service.service`).
- `systemctl start nbfc_service` failed:
  - First failure: `/etc/nbfc/nbfc.json: No such file or directory`
  - After creating an (initially empty) file: `/var/lib/nbfc/configs/: Is a directory`
    (because `SelectedConfigId` was empty).

### 2. Machine model detection

- `cat /sys/class/dmi/id/product_family` → `ThinkBook 15p`
- DMI ids: vendor `LENOVO`, product `20V3`, board name `LNVNB161216`
- No `ThinkBook` config exists in `/usr/share/nbfc/configs/`.

### 3. Tried to auto-select a config

- `sudo nbfc config --set auto` → `ERROR: No config found to apply automatically`
- `sudo nbfc rate-config -a` → only configs scoring below 9.00 (none compatible).
- `sudo nbfc update` → no new configs available.

→ No pre-made configuration exists for the ThinkBook 15p. A placeholder config was used
so the service would start: `Lenovo ThinkPad T14 Gen2`.

### 4. EC backend

- `ec_sys` module loads (`sudo modprobe ec_sys`) but its debugfs interface failed:
  - `ec_probe` and `nbfc_service` → `/sys/kernel/debug/ec/ec0/io: Invalid argument`
- `acpi_ec` module not available for kernel `7.2.4-1-omarchy-bore`.
- `/dev/port` exists and works.
- Solution: set `"EmbeddedControllerType": "dev_port"` in `/etc/nbfc/nbfc.json`.

### 5. Config file created

`/etc/nbfc/nbfc.json`:

```json
{
  "SelectedConfigId": "Lenovo ThinkPad T14 Gen2",
  "EmbeddedControllerType": "dev_port"
}
```

Also created empty dirs: `/etc/nbfc` and `/var/lib/nbfc`.

### 6. Service start

- `sudo systemctl reset-failed nbfc_service` (after repeated restart-limit trips)
- `sudo systemctl start nbfc_service` → OK
- `nbfc status` now shows:

```
Read-only                : false
Selected Config Name     : Lenovo ThinkPad T14 Gen2
Fan Display Name         : System Fan
Temperature              : 62.21
Auto Control Enabled     : true
Critical Mode Enabled    : false
Current Fan Speed        : 14.29
Target Fan Speed         : 20.20
Fan Speed Steps          : 7
```

### 7. Launching the GUI

- `sudo -E nbfc-qt` — `sudo` must preserve the display environment
  (`WAYLAND_DISPLAY`, `XDG_RUNTIME_DIR`), otherwise Qt fails with:
  `qt.qpa.xcb: could not connect to display`. `-E` fixes this.

## Useful commands

- `nbfc status` — show fan/temperature status
- `nbfc config --list` — list available model configs
- `nbfc config --set "MODEL"` — set model config
- `nbfc rate-config -a -m 0` — rate all configs (lower the 9.00 threshold with `-m`)
- `nbfc s-`... (see `nbfc --help`) — set fan speed, restart, etc.
- `sudo nbfc update` — download latest configs
- `sudo systemctl enable nbfc_service` — enable on boot (may still be needed)
- `sudo ec_probe dump` / `sudo ec_probe monitor` — inspect EC registers

## Observations from EC probing

EC registers observed changing during `ec_probe monitor`:
- `0x56` — ~0x41–0x42 (65–66 °C, temperature)
- `0xB0` — ~0x41–0x42 (temperature)
- `0xB6` — ~0x41–0x43 (temperature)
- `0xC6` — 0x04–0x05 (fan/PWM-ish)

These were NOT decoded; a real config for the ThinkBook 15p still needs to be created
(see https://nbfc-linux.github.io/creating-config/).

## Verification (2026-09-09) — DOES THE FAN CONTROL ACTUALLY WORK?

**No. Fan control does NOT work on this model.** NBFC can monitor the fan, but cannot change its
speed. Details:

### How it was tested

1. Applied a test config copied from `Lenovo Yoga 510` (ReadRegister=6, WriteRegister=176)
   because register `6` (0x06) is the DSDT field `FANS` (fan tachometer in units of 100 RPM).
2. `nbfc set -s 100` → wrote `90` to register `0xB0` (0x5A). FANS (reg 6) stayed at `0x21`
   (= 3300 RPM) — **fan did not speed up**.
3. `nbfc set -s 0` → wrote `0` to `0xB0`. FANS stayed at 33 — **fan did not slow down**.
4. Under heavy CPU load, `FANS` rose only from `0x1B` (27) to `0x21` (33) (2700→3300 RPM),
   following what the EC firmware wanted — not what NBFC wrote.
5. `ec_probe watch` confirmed: while NBFC wrote 33/66/90 to `0xB0`, the physical fan speed
   (FANS) never changed. `0xB0` later reverted to `0x43` (67) on its own — it is a
   temperature/string area, not a fan PWM register.
6. `sudo nbfc rate-config -a` found no compatible configs for this machine.

### Why (DSDT/ACPI evidence)

- The ThinkBook 15p EC exposes **no direct fan PWM register**.
- Fan speed read: `\_SB.PCI0.LPCB.EC0.FANS` (offset 0x06), 8-bit, ×100 RPM (matches the
  kernel `yogafan` driver's "8-bit EC architecture").
- Fan control is done **inside the EC firmware**, and the OS can only switch *thermal profiles*
  via WMI: `\_SB.PCI0.LPCB.EC0.NCMD (0x59, 0x76…0x7B)` and the `WMAA` method
  (`Arg1==0x2C` sets `FCMO`), i.e. the Fn+Q / Lenovo Vantage mode switch.
- No `GFSD`/`SFSD`/fan-set ACPI methods exist in the DSDT.

### Practical options for this laptop

- **NBFC service should stay STOPPED** so the EC firmware controls the fan normally:
  `sudo systemctl disable --now nbfc_service`
- Fan speed monitoring IS possible via FANS (reg 6): `sudo ec_probe read 6`
  (value × 100 = RPM). The kernel `yogafan` driver exposes `fan1_input` on supported
  Lenovo models.
- Fan *speed* changes (modes) are handled by `ideapad_laptop`/Fn+Q, not NBFC.
- A custom NBFC config for real fan control would require reverse-engineering Lenovo's
  proprietary fan-control in the EC firmware (not feasible from Linux).

## Fn+Q thermal modes (the realistic "fan control") — 2026-09-09

### Mechanism

- Fn+Q is NOT fan control; it switches **thermal profiles** handled by the EC firmware.
  Each profile = a fan curve + CPU power limits.
  - Quiet / `low-power` — fan curve down, power-limited
  - Balanced / `intelligent cooling` — default
  - Performance — aggressive fan + high power
- The OS only tells the EC which profile to use via Lenovo's **DYTC** (Dynamic Thermal Control).

### Why it was not active

Kernel boot log:
```
ideapad_acpi VPC2004:00: DYTC_VERSION 4 support may not work. Pass ideapad_laptop.allow_v4_dytc=Y on the kernel commandline to enable
ideapad_acpi VPC2004:00: DYTC interface is not available
```
The kernel refuses to enable DYTC v4 on unconfirmed models unless opted in with
`ideapad_laptop.allow_v4_dytc=Y`.

### Danger learned

`sudo modprobe -r ideapad_laptop` **kills WiFi and Bluetooth** (rfkill) on this laptop —
must NOT be used to reload the module. Enable via kernel commandline + reboot instead.

### Applied change

- Added `ideapad_laptop.allow_v4_dytc=Y` to the cmdline of the two main kernel entries
  in `/efi/limine.conf` (limine bootloader; UKI setup). Snapshot entries untouched.
- Backup: `/efi/limine.conf.bak-dytc`
- Requires one reboot to take effect.

### After reboot, check

```
cat /sys/firmware/acpi/platform_profile_choices      # e.g. low-power balanced performance
echo performance | sudo tee /sys/firmware/acpi/platform_profile
echo balanced    | sudo tee /sys/firmware/acpi/platform_profile
```
Fn+Q should then cycle the profiles through the driver.

### Other knobs present on this system (mostly unsupported)

- `/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/fan_mode` — returns `133` (unsupported);
  documented values would be 0=super silent, 1=standard, 2=dust cleaning, 4=efficient thermal.
- `/sys/devices/platform/INT3400:00/odvp0` — `1` (quiet) / `0` (performance) status flag.
- `conservation_mode` deprecated in this kernel (use `charge_types`).
- NOTE: Omarchy's `omarchy-refresh-limine` may regenerate boot entries on kernel updates,
  potentially dropping the added cmdline param — re-check after updates.

## Open items / caveats

1. **Fan control unsupported on this model** — see Verification above. Do not rely on NBFC
   to change fan speed on the ThinkBook 15p.
2. **`ec_sys` broken on this kernel** — `dev_port` works but writes to `/dev/port`; `acpi_ec`
   would be preferable (DKMS module) and is compatible with Secure Boot/lockdown kernels.
   NBFC needs `dev_port`/`acpi_ec` only if you use it for monitoring.
3. **Service intentionally disabled** — `systemctl disable --now nbfc_service` was run so the
   EC owns the fan. Re-enable only if you accept that speed writes will be ignored.
4. **GUI launch (for monitoring only)** — `sudo -E nbfc-qt` with the service running;
   `sudo` must preserve the display environment (`WAYLAND_DISPLAY`, `XDG_RUNTIME_DIR`),
   otherwise Qt fails with `qt.qpa.xcb: could not connect to display`.
## autoprofile daemon (auto-switch DYTC profile by temp/load)

/usr/local/sbin/autoprofile.sh + systemd unit `autoprofile.service` (enabled).
Poll /sys/firmware/acpi/platform_profile every 5s vs coretemp Package + loadavg.

Transitions (load = % of all cores, nproc-normalized):
- balanced -> performance: temp>80C OR load>85%
- performance -> balanced: load<40% OR temp<55C
- balanced -> low-power:   temp<50C AND load<25%
- low-power -> balanced:   temp>60C OR  load>50%

Files: /usr/local/sbin/autoprofile.sh, /etc/systemd/system/autoprofile.service
Control: systemctl {start,stop,restart,status} autoprofile
Tune thresholds at top of script, then `sudo systemctl restart autoprofile`.
