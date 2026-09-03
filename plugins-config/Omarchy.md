# Omarchy — Complete System Reference

> Generated 2026-09-03 from a live Omarchy system (`omarchy version 4.0.0.r2014.gf99d33a-1`,
> `/usr/share/omarchy/version` = `4.0.0.alpha`, channel `edge`).
> Omarchy is an Arch Linux–based distribution with Hyprland (Wayland) and a
> Quickshell-powered desktop shell. All facts below were verified by reading
> the system itself; paths are exact.

---

## 1. What Omarchy Is

| Layer | Choice |
|---|---|
| Base OS | Arch Linux (`/etc/os-release`: `ID=omarchy`, omarchy mirror `pkgs.omarchy.org`) |
| Kernel | `linux-omarchy-bore 7.2.3-1` (running `7.2.3-1-omarchy-bore`); stock `linux` also installed |
| Bootloader | Limine 12.7.0 (UEFI, no GRUB/systemd-boot) |
| Init / session | systemd + `uwsm` (Hyprland session) |
| Compositor | Hyprland 0.56.2 (Wayland) |
| Desktop shell / bar | Custom Quickshell app ("Omarchy shell", single long-running instance) |
| Login manager | SDDM |
| Filesystem | btrfs on LUKS (`root=/dev/mapper/root`, `rootflags=subvol=@`), snapper snapshots |
| Terminals | Alacritty, Foot, Kitty, Ghostty (all configured, theme-synced) |
| Prompt | Starship · Multiplexer: tmux · Launcher: Quickshell `omarchy.menu` |
| Package mgmt | pacman + `yay` (AUR) + `mise` (dev tools / AI agents) |

---

## 2. Filesystem Map — Where Things Live

| Path | Owner | Purpose |
|---|---|---|
| `/usr/share/omarchy/` | `omarchy` package — **READ-ONLY, never edit** | All stock code: `bin/`, `config/`, `default/`, `shell/`, `themes/`, `migrations/`, `install/`, `applications/`, `etc-overrides/` |
| `~/.config/` | you | Safe user config (hypr, omarchy, terminals, fastfetch, …) |
| `~/.config/omarchy/themes/<name>/` | you | Custom themes (create new dirs, never touch stock) |
| `~/.config/omarchy/plugins/` | you | Cloned / third-party shell plugins (hot-reload) |
| `~/.config/omarchy/hooks/` | you | Automation hooks (`<event>.d/` dirs) |
| `~/.local/state/omarchy/` | generated | Runtime state: `current/theme/` (rendered theme files), `current/theme.name`, `migrations/` markers, `agents/usage/` |
| `~/.local/bin/` | you | Personal scripts (on `PATH`) |
| `/etc/omarchy.conf` | system | `export OMARCHY_PATH="/usr/share/omarchy"` |
| `/boot/limine.conf` | system | Limine config (entries auto-generated) |

`$OMARCHY_PATH` defaults to `/usr/share/omarchy` (dev-link mode repoints it).
Rule of thumb: read `/usr/share/omarchy` freely, change only `~/.config`.

---

## 3. The `omarchy` CLI Dispatcher

One dispatcher, ~441 binaries, ~452 routes:

- Every command is a standalone script `omarchy-<group>-<action>` in `/usr/share/omarchy/bin/` (on `PATH`).
- The `omarchy` dispatcher (`/usr/share/omarchy/bin/omarchy`) scans those files, reads metadata headers from the first 80 lines (`# omarchy:group=`, `# omarchy:name=`, `# omarchy:summary=`, `# omarchy:args=`, `# omarchy:aliases=`, `# omarchy:requires-sudo=`, `# omarchy:hidden=`), and longest-prefix matches `omarchy <group> <action>` → binary, e.g. `omarchy theme set x` → `omarchy-theme-set`.
- Discovery: `omarchy commands` (documented), `omarchy commands --all` (+hidden), `omarchy commands --json`, `omarchy <group> --help`, `omarchy <group> <action> --help`.

Biggest command groups (by binary count): `install` (35), `theme` (32), `remove`/`hw` (27), `hyprland` (24), `launch` (23), `update` (21), `restart` (16), `menu` (14), `toggle` (13), `refresh` (12), `system`/`dev` (11), `plugin`/`pkg`/`audio` (9), `capture` (8), `agent` (7). Full group list: `agent, ascii, audio, bar, battery, bluetooth, branch, branding, brightness, capture, channel, clipboard, cmd, config, crash, debug, default, dev, disk, display, dns, drive, file, finalize, font, games, hibernation, hook, hw, hyprland, install, installed, launch, menu, migrate, mise, monitor, network, notification, osd, pkg, plugin, plymouth, power, powerprofiles, refresh, reinstall, reminder, remove, restart, screensaver, setup, shell, snapshot, sudo, system, tailscale, theme, toggle, transcode, tui, update, version, voxtype, weather, webapp, wifi, windows`.

Handy everyday commands:

```bash
omarchy update                  # full system update (snapshots first)
omarchy version                 # distro version
omarchy debug --no-sudo --print # diagnostics (always use these flags non-interactively)
omarchy theme set <name>        # switch theme
omarchy refresh shell|hyprland  # reset config to defaults (backs up first)
omarchy refresh config <path>   # reset one file, e.g. hypr/hyprland.lua
omarchy restart shell|terminal  # restart shell / reload terminals
omarchy toggle nightlight       # toggle features
omarchy reminder 15 "Pickup Jack"
omarchy capture screenshot      # screenshots / recordings
omarchy system lock|shutdown|reboot
```

---

## 4. Packages

Package lists live in `/usr/share/omarchy/install/` (`config/ hardware/ helpers/ login/ omarchy-base.packages omarchy-other.packages post-install/ provisioning/ user/`).

- **`omarchy-base.packages`** (~150 entries, "core package list pacstrapped by the ISO"): Hyprland stack (`hyprland`, `hyprland-guiutils`, `hyprpicker`, `hyprsunset`, `xdg-desktop-portal-hyprland`), `quickshell`, `uwsm`, `sddm`, audio (`wireplumber`, `pipewire` via other list, `pamixer`), network (`networkmanager`, `avahi`, `nss-mdns`), desktop apps (`chromium`, `nautilus`, `evince`, `mpv` + `mpv-mpris`, `obs-studio`, `obsidian`, `kdenlive`, `libreoffice-fresh`, `pinta`, `xournalpp`), dev tools (`git`, `nvim` + `omarchy-nvim`, `mise-bin`, `yay`, `fzf`, `ripgrep`, `fd`, `bat`, `eza`, `zoxide`, `lazygit`, `lazydocker`, `tmux`, `starship`, `tldr`), theming/fonts (`ttf-jetbrains-mono-nerd-basic`, `noto-fonts{,-cjk,-emoji}`, `yaru-icon-theme`, `gnome-themes-extra`), utilities (`fastfetch`, `btop`, `gum`, `grim`, `slurp`, `wl-clipboard`, `wtype`, `qrencode`, `zbar`, `tesseract`, `yt-dlp`, `ffmpegthumbnailer`, `gpu-screen-recorder`, `docker{,-buildx,-compose}`, `ufw` + `ufw-docker`, `tzupdate`, `plocate`, `udiskie`, `sushi`, printing (`cups*`, `system-config-printer`), virtualization (`qemu-user-static-binfmt`), and Omarchy's own `omacalc/omacut/omawrite/herdr/tensaku/tobi-try/usage/cliamp/asdcontrol`.
- **`omarchy-other.packages`** (~77 entries, hardware/variant/ISO-builder): `base`, `base-devel`, `linux`, `linux-firmware*`, `linux-headers`, `limine` + `limine-mkinitcpio-hook` + `limine-snapper-sync`, `snapper`, `btrfs-progs`, `broadcom-wl`, drivers (`nvidia*-dkms`, `intel-*`, `vulkan-*`, apple/tuxedo/dell/lenovo quirks), `pipewire*`, `qt6-wayland`, `zram-generator`, `thermald`, `yay-debug`.
- Omarchy's own packages (this machine): `omarchy-dev 4.0.0.r2014.gf99d33a-1` (provides `omarchy`), `omarchy-settings-dev`, `omarchy-keyring 20251027-1`, `omarchy-nvim 2026.8.13-1`, `linux-omarchy-bore 7.2.3-1` (+headers). `omarchy-dev` depends on: `omarchy-keyring omarchy-settings-dev limine limine-mkinitcpio-hook limine-snapper-sync snapper hyprland quickshell uwsm sddm xdg-desktop-portal-hyprland wireplumber pipewire gnome-keyring gum jq git perl fakeroot pacman-contrib ttf-jetbrains-mono-nerd-basic`.
- AUR via `yay` (`omarchy-update-aur-pkgs`: `yay -Sua --noconfirm`); dev CLIs via `mise` (`/usr/share/omarchy/install/user/mise.sh`, `omarchy-update-mise`).

---

## 5. Boot: Limine + LUKS + btrfs + Snapper

- **Bootloader is Limine only** (12.7.0, UEFI `.../EFI/limine/limine_x64.efi`, Secure Boot disabled). No GRUB, no systemd-boot, no `/boot/loader/entries`.
- `/boot/limine.conf`: `default_entry: 2`, `BOOT_ORDER="*, *fallback, Snapshots"`, `ENABLE_UKI=no`. Entries are **auto-generated** by `limine-entry-tool` + `limine-snapper-sync`: one per kernel (`//linux` stock Arch, `//linux-omarchy-bore`) plus a nested `//Snapshots` tree booting read-only snapper snapshots (`rootflags=subvol=/@/.snapshots/N/snapshot`).
- Disk: ESP `/boot` (2 GB vfat) + LUKS `nvme0n1p2` → `/dev/mapper/root`, btrfs subvol `@`. Kernel cmdline: `cryptdevice=…:root root=/dev/mapper/root … rootfstype=btrfs quiet splash … vt.global_cursor_default=0`.
- Snapper: `root` config installed by `/usr/share/omarchy/install/config/snapper.sh`; `snapper-cleanup.timer` + `limine-snapper-sync.service` enabled, timeline snapshots disabled. Every `omarchy update` creates a pre-update snapshot (`omarchy-snapshot create`).

---

## 6. Updates, Channels, Migrations

- **Update flow** (`omarchy-update`, requires sudo, single-instance, logs to `/tmp/omarchy-update.log`): prune → **snapshot** → `omarchy-update-dev` → keyring → `pacman -Syu` (with `--overwrite '/usr/share/omarchy/*'` + conflict handler) → **`omarchy-migrate`** → `post-update` hooks → AUR (`yay`) → mise → orphan cleanup → log analysis → optional restart prompt.
- **Channels**: `dev` (dev-link mode) · `edge` / `stable` / `rc` from pacman mirror (`[omarchy] Server = https://pkgs.omarchy.org/<channel>/$arch`). This machine: **edge**. Helpers: `omarchy-channel-current`, `omarchy-version-channel`, `omarchy-version`.
- **Migrations** (`/usr/share/omarchy/migrations/*.sh`, 103 epoch-named scripts): `omarchy-migrate` runs each missing script once (`bash -euo pipefail`), tracking state in `~/.local/state/omarchy/migrations/<name>`; `--pending` lists what's due. Small ones just install a package (e.g. `mpv-mpris`, `qrencode`); larger ones do config surgery (pacman repo repoints, sshd hardening with `sshd -t` validation).

---

## 7. Config Layering (Defaults → User)

Three layers, in precedence order:

1. **`/usr/share/omarchy/default/`** — stock fragments sourced/included by user configs (bash rc chain, hypr `*.lua` modules, terminal defaults, systemd units, udev, sddm/plymouth/snapper templates, `default/hypr/toggles/flags.lua`, …).
2. **`/usr/share/omarchy/config/`** — pristine *user* templates copied to `~/.config` on install/refresh (alacritty, foot, ghostty, kitty, hypr, omarchy/shell.json, omarchy-menu, hooks, btop, starship.toml, tmux, wireplumber, …).
3. **`~/.config/`** — the live user config. Edit freely.

- **Reset**: `omarchy refresh config <rel-path>` backs up to `<file>.bak.<epoch>` and restores the shipped default; `omarchy refresh shell|hyprland` do the same for whole subsystems and restart them.
- **Shell env chain**: `/etc/profile.d/omarchy.sh` → `default/bash/env-bootstrap` (sets `OMARCHY_PATH`, appends mise shims + `~/.local/bin` to `PATH`) → `~/.bashrc` → `$OMARCHY_PATH/default/bash/rc` → `envs` → `shell` (history/completion) → `aliases` → `functions` → `init` (mise, starship, zoxide, fzf). Interactive guard `[[ $- != *i* ]] && return` sits above the rc source.
- `/usr/share/omarchy/etc-overrides/` holds files overlaid onto `/etc` (os-release branding, nsswitch, faillock, cups, plymouth).

---

## 8. Hyprland

- User entry `~/.config/hypr/hyprland.lua` bootstraps stock (`dofile(.../default/hypr/bootstrap.lua)`, `require("default.hypr.omarchy")`); user overrides live in small files:

| File | Purpose |
|---|---|
| `bindings.lua` | Personal keybinds (`o.bind(...)`; `omarchy menu keybindings --print` to inspect) |
| `input.lua` | Keyboard/input (`kb_options`, numlock, per-window touchpad scroll) |
| `looknfeel.lua` | Gaps/borders/layout (all-commented examples by default) |
| `monitors.lua` | Monitor layout, e.g. `HDMI-A-1 1920x1080@60 0x0 s1` |
| `autostart.lua` | Extra autostarts (`o.launch_on_start(...)`) |
| `hyprsunset.conf` | Night-light time profiles |
| `xdph.conf` | Portal config |
| `border-fx.lua` | **Generated** shiny-border adapter — do not edit |

- Hyprland auto-reloads on save; validate with `hyprctl reload` + `hyprctl configerrors`. Manage via `omarchy hyprland …` (24 cmds), `omarchy toggle …`, `omarchy restart …`.

---

## 9. Omarchy Shell (Bar, Plugins, Menu)

The desktop shell is **one long-running Quickshell instance** (`/usr/share/omarchy/shell/`: `shell.qml` entry, `Commons/`, `Ui/` widgets/panels, `services/`, `plugins/`). Bar, menus, overlays, lock, OSD all run *inside* it as plugins — no per-call cold starts; IPC via `quickshell ipc` / `omarchy-shell shell …`. Restart: `omarchy restart shell`. User config `~/.config/omarchy/shell.json` **hot-reloads on save**.

### 9.1 `shell.json`

```json
{
  "version": 1,
  "idle": { "screensaver": 150, "lock": 300 },
  "bar": {
    "position": "top", "transparent": false, "centerAnchor": "omarchy.clock",
    "layout": {
      "left":   ["omarchy.menu", "omarchy.workspaces", "omarchy.active-window"],
      "center": ["omarchy.indicators", "omarchy.clock", "omarchy.keyboard-layout",
                 "omarchy.weather", "io.github.ejuro.blow-off-some-steam", "omarchy.media",
                 "co.klair.wallarchy", "costafot.clippy", "slcode777.omagotchi",
                 "pick.screenshot", "omarchy.system-update"],
      "right":  ["omarchy.tray", "omarchy.agents", "akshar.radio-atlas", "omarchy.bluetooth",
                 "omarchy.network", "omarchy.audio", "omarchy.monitor", "omarchy.power"]
    }
  },
  "plugins": [{"id":"bottelet.invaders"},{"id":"mihai.lock"},{"id":"io.github.0x1ocean.omatrix"}],
  "disabledPlugins": ["omarchy.lock"],
  "cloneSourceRestores": ["mihai.lock"]
}
```

`idle.*` are seconds of idleness (screensaver 150 s, lock 300 s). Stock 1st-party widgets are on unless listed in `disabledPlugins`; third-party widgets are on iff placed in the layout.

### 9.2 Plugins

- Lifecycle CLI: `omarchy plugin add|clone|enable|disable|list|remove|update|validate`.
- Sources: stock (`/usr/share/omarchy/shell/plugins/`, kinds: `bar-widget, panel, overlay, menu, service, bar`) · user (`~/.config/omarchy/plugins/`, 9 here: radio-atlas, wallarchy, clippy, omatrix, blow-off-some-steam, taskbar, mihai.lock, screenshot, omagotchi).
- **Clone-to-customize** (`omarchy plugin clone omarchy.clock`): copies the plugin dir, rewrites `manifest.json` (`id: <user>.<name>`, `.omarchy.clonedFrom`), re-enables at the same bar position; the shell routes old IPC ids to the clone; deleting the clone reverts to stock. Edits hot-reload (~150 ms).
- Manifest: `{schemaVersion, id, name, kinds[], keepLoaded, entryPoints, omarchy:{clonedFrom, clonePaths}}`. Only one `bar` plugin active (fallback `omarchy.bar`).

### 9.3 Menu / Launcher

- Schema + user overrides: `~/.config/omarchy/extensions/omarchy-menu.jsonc` (empty by default — commented schema only).
- Defaults: `/usr/share/omarchy/default/omarchy/omarchy-menu.jsonc` (~371 lines): root groups `apps, learn, trigger, style, setup, install, remove, update, about, system`, with deep subtrees (`system.{screensaver,lock,suspend,hibernate,logout,reboot,shutdown}`, `trigger.{emoji,reminder,capture.*,share.*,toggle.*,hardware.*}`, `learn.{keybindings,omarchy,hyprland,arch,neovim,bash,tmux,community}`).
- Rendered by the `omarchy.menu` shell plugin, summoned in ~30 ms (`omarchy-shell shell summon omarchy.menu`); both files watched for changes.

---

## 10. Themes

- Stock (22): `catppuccin, catppuccin-latte, ethereal, everforest, flexoki-light, gruvbox, hackerman, kanagawa, last-horizon, lumon, lupine, matte-black, miasma, nord, osaka-jade, retro-82, ristretto, rose-pine, solitude, tokyo-night, vantablack, white` (`/usr/share/omarchy/themes/<name>/`: `colors.toml, backgrounds/, neovim.lua, vscode.json, icons.theme, keyboard.rgb, shell.lock.toml, preview*.png, unlock.png`).
- User (4 here): `cortado-darkly, macchiato-core, omarchy-kitt-theme, omatrix` (same layout + `README.md`, per-theme extras like `omatrix.toml`).
- **Switching** (`omarchy theme set <name>`, ~350-line script): normalize name → `flock` → stage stock + overlay user files (repo-installed themes filtered to a deny-list; `colors.toml` derived from alacritty if needed) → render templates → atomically swap `~/.local/state/omarchy/current/theme/` (24 generated files: `alacritty.toml, kitty.conf, ghostty.conf, foot.ini, hyprland.lua, btop.theme, vscode*.json, neovim.lua, helix.toml, obsidian.css, shell.toml, …`) → hot-apply to shell (crossfade) → restart terminals/apps → `theme-set` hooks.
- Customize by **overlaying**: copy a file (e.g. `colors.toml`) into `~/.config/omarchy/themes/<name>/` and re-apply; never edit stock.
- Terminal configs just import the generated theme (`general.import = ["~/.local/state/omarchy/current/theme/alacritty.toml"]`, etc.); apply with `omarchy restart terminal`.

---

## 11. Hooks (Event Automation)

- Runner: `omarchy hook <name> [args]` executes `~/.config/omarchy/hooks/<name>` then every executable in `<name>.d/` (skips `*.sample`; failures reported but don't stop the chain). Installer: `omarchy hook install <type> <file>` (copies + `chmod 755`).
- Hook points present: `battery-low.d/`, `font-set.d/`, `post-boot.d/`, `post-update.d/`, `pre-refresh-pacman.d/`, `theme-set.d/`. Active here: `post-update.d/{install-voxtype, setup-agent, setup-fingerprint}.hook`; rest ship as `.sample` examples (theme-change notifications, low-battery sound, …).
- System-fires-hooks examples: update flow fires `post-update`; theme switch fires `theme-set`.

---

## 12. AI Agents Integration

- Launcher: `omarchy agent [--inline] [--pick] [<prompt…>]` cds to `~/Work` (if in `$HOME`) and opens the default agent in a terminal (per-agent flags handled internally). `omarchy agent prompt …` passes a prompt through.
- Default agent stored in `~/.config/omarchy/defaults/agent` (here: `opencode`); set via `omarchy-default-agent <name>` (also `mise use -g`s the tool). Supported: `pi, omp, opencode, ori, claude, codex, grok, agy, hermes, copilot, crush`.
- Crash diagnosis: `omarchy agent crash <pid>` + `omarchy-crash-watch.service` AI-diagnose segfaults from coredumps.
- Usage tracking: `omarchy-agent-usage-{claude,codex,fireworks}` collectors → `~/.local/state/omarchy/agents/usage/` → `omarchy.agents` bar widget.
- Agent skills ship in `/usr/share/omarchy/default/agents/skills/{omarchy,diagnose-crash}` (the omarchy skill governs all `~/.config` edits).

---

## 13. Terminals, Shell Prompt, Fetch

- All four terminals share `JetBrainsMono Nerd Font size 9`, 14 px padding, theme-imported colors (see §10). Default daily driver here: **Alacritty** (`decorations=None`, `osc52=CopyPaste`); Kitty allows remote control; Ghostty uses CSI-u bindings.
- Prompt: Starship (`~/.config/starship.toml`: directory + git + cyan `❯/✗`). History/completion/zoxide/fzf wired in the bash rc chain (§7).
- `fastfetch` (`~/.config/fastfetch/config.jsonc`): logo = `~/.config/omarchy/branding/about.txt` (the Omarchy block mark); green hardware / blue software / magenta age-uptime-update modules; `omarchy-version*` helpers feed OS/branch/channel rows. `~/.config/omarchy/branding/{about.txt,screensaver.txt}` are user-editable (`omarchy branding about|screensaver …`).

---

## 14. Backgrounds, Screensaver, Lock, Power

- Backgrounds: `~/.config/omarchy/backgrounds/` (+`.source.json` provenance); Wallarchy fetcher prefs in `~/.config/omarchy/wallarchy.json` (Wallhaven query/sorting/purity).
- Idle pipeline: `shell.json:idle` → screensaver (150 s) → lock (300 s). Lock path: `omarchy system lock` → `omarchy-shell lock lock` + keyboard-layout reset + 1Password lock. Related: `omarchy-{launch-,}screensaver`, `toggle-screensaver/idle`, `system-{sleep-lock,sleep-monitor,lid-close,hyprland-session-locked}`, `apply-lock`.
- Power: `power-profiles-daemon`, `powerprofiles` cmds, `omarchy power …`, battery helpers (`omarchy-battery-*`, `battery-low` hook), brightness (`brightnessctl`/`ddcutil`/`omarchy-brightness-*`), night light (`hyprsunset`, `toggle nightlight`).

---

## 15. Sessions, SDDM, Plymouth

- Login: SDDM → `uwsm` Hyprland session (`/usr/share/omarchy/default/{sddm,uwsm,wayland-sessions,environment.d}` + `uwsm/env.d/10-omarchy` for `PATH`/`OMARCHY_PATH`).
- Boot splash: Plymouth (`plymouth` pkg, `default/plymouth`, `omarchy-plymouth-*` cmds, `etc-overrides/*plymouth*`).
- Env bootstrap for non-interactive/SSH shells: `default/bash/env-bootstrap` (also sourced from `/etc/profile.d/omarchy.sh`).

---

## 16. Troubleshooting & Recovery

```bash
omarchy debug --no-sudo --print   # diagnostics bundle
omarchy refresh config <path>     # restore one config (auto-backup *.bak.<epoch>)
omarchy refresh shell|hyprland    # restore subsystem + restart it
omarchy reinstall                 # nuclear config reinstall
omarchy snapshot ...              # snapper snapshots (pre-update auto-created)
hyprctl reload; hyprctl configerrors
```

Boot a pre-update system from the Limine `Snapshots` submenu if an update misbehaves. Never edit `/usr/share/omarchy/` — it is overwritten on every update.

---

## Appendix A — Stock `/usr/share/omarchy` Tree

```
bin/            441 omarchy-* command scripts (the CLI)
config/         pristine user templates (→ ~/.config)
default/        stock fragments (bash, hypr, terminals, systemd, sddm, …)
shell/          Quickshell desktop shell (shell.qml, Commons/, Ui/, services/, plugins/)
themes/         22 stock themes
migrations/     103 one-shot update scripts
install/        package lists + provisioning scripts
applications/   .desktop entries
etc-overrides/  files overlaid onto /etc
icon.png icon.txt logo.svg logo.txt
version         4.0.0.alpha
```

## Appendix B — User `~/.config` Tree (Omarchy-relevant)

```
hypr/           hyprland.lua bindings.lua input.lua looknfeel.lua monitors.lua
                autostart.lua border-fx.lua(generated) hyprsunset.conf xdph.conf
omarchy/        shell.json wallarchy.json
                backgrounds/ branding/ defaults/ extensions/ hooks/
                plugins/ themed/ themes/
alacritty/ foot/ kitty/ ghostty/   terminal configs (theme-imported)
fastfetch/ btop/ starship.toml lazygit/ tmux/ ...
```

## Appendix C — `~/.local/state/omarchy` (Generated Runtime State)

```
current/theme.name        active theme name
current/theme/            24 rendered per-app theme files (alacritty.toml … vscode-theme.json)
migrations/               per-migration ran-markers
agents/usage/             AI agent usage JSON for the bar widget
toggles/hypr/flags.lua    Hyprland toggle flags (reset by refresh)
```

---

## 17. First Boot & Provisioning

- `omarchy provision owner` — first-boot user creation on deferred-provisioning installs (systemd: `omarchy-provision-owner.service`, form: `install/provisioning/setup-form.sh`).
- `omarchy provision user` — finalizes user setup (things `/etc/skel` can't do at runtime).
- `omarchy provision first run` — first-login setup; runs `install/user/first-run/`: `welcome.sh`, `wifi.sh`, `audio-tuning.sh`, `gnome-theme.sh`, `gtk-primary-paste.sh`, `enable-user-units.sh`, plus hook copies (`install-voxtype`, `setup-agent`, `setup-fingerprint`).
- `install/user/`: `all.sh`, `chromium.sh`, `git.sh`, `mise.sh` (+`mise-work.sh`), `theme.sh`, `xcompose.sh`, `default-keyring.sh`, per-vendor `hardware/` fixes (asus audio/mic, dell text scaling, nouveau cursor, framework).
- `install/login/all.sh` → `sddm.sh` (login manager setup); `install/post-install/`: `localdb.sh`, `pacman.sh`, `udev.sh`.
- `install/config/` scripts (run at install): `all.sh`, `browser-policy.sh`, `docker.sh`, `enable-services.sh`, `firewall.sh` (ufw), `locate.sh` (plocate), `lockscreen-pam.sh`, `snapper.sh`, `ssh-keepalive.sh`, `ssh-command-path.sh`, `theme-system.sh`, `increase-lockout-limit.sh`, `fix-powerprofilesctl-shebang.sh`.
- Factory reset: `omarchy system factory reset` (+ finish service `omarchy-system-factory-reset-finish.service`) returns the machine to fresh-install state.

## 18. Setup Wizards & Security

`omarchy setup …` (interactive):

| Command | Effect |
|---|---|
| `setup direct boot` | Adds/removes an EFI boot entry booting the Omarchy UKI directly |
| `setup security fido2` | FIDO2 auth for sudo + polkit |
| `setup security fingerprint` | Fingerprint auth for sudo + polkit + lock screen |
| `setup security sshd [--key=…] [--gh-keys user]` | OpenSSH server + firewall port + authorized key |
| `setup security sudoless docker` | Adds user to `docker` group (root-equivalent!) |

Each has a mirror `omarchy remove security …` undo command. Sudo helpers: `omarchy sudo keepalive`, `omarchy sudo passwordless [MINUTES]`, `omarchy sudo docker` (probe).

## 19. Software Catalog (`install` / `remove`)

- **Browsers**: `install|remove browser <chromium|chrome|brave|brave-origin|edge|firefox|zen>` (+ chromium extras: google-account OAuth, copy-url / ytdlp native hosts).
- **Dev envs**: `install dev-env <ruby|node|bun|deno|go|laravel|symfony|php|python|elixir|phoenix|rust|java|zig|ocaml|dotnet|clojure|scala>` (+ `remove dev env …`).
- **Gaming**: `steam, heroic, lutris, battlenet, retroarch, minecraft, geforce-now, xbox-cloud, xbox-controllers, gpu-lib32` (full install *and* remove flows; retroarch builds `~/Games` ROM dir; `games retro cores|install` manages libretro cores).
- **Services**: `1password, dropbox (+bar plugin), nordvpn, signal, spotify, sunshine (+Moonlight ports), tailscale (+admin-console webapp), once`.
- **Editors**: `emacs (omarchy-emacs AUR), helix, vscode, zed` — all wired into the current Omarchy theme.
- **Terminals**: `install terminal <alacritty|foot|ghostty|kitty>` (sets default for Super+Return etc.).
- **AI apps**: `install ai chatgpt|hermes`, `remove ai <chatgpt|grok-bot|hermes|lm-studio|ollama|t3-code>` (removes models/data too), `install hermes cli`.
- **Docker DBs**: `install docker dbs` (supported databases in containers with dev options).
- **Fonts**: `install font <display> <package> <family>` → also `omarchy font set|list|current`, `font-set` hooks.
- **Preinstalls**: `install|remove preinstalls` (restore/drop the ISO's web apps, TUIs, packages).
- **Package TUIs**: `omarchy pkg install|remove` (fuzzy pickers over Arch+OPR/AUR), `pkg add|drop|present|missing`, `pkg aur add|install|accessible`; `mise install <pkg>` for mise-backed wrappers.

## 20. Launchers, Web Apps, TUIs

- `omarchy launch terminal [cmd]` (in cwd), `terminal tmux` (Work session), `terminal herdr`, `floating terminal with presentation`, `tui …` (default-terminal styled), `or-focus …` (launch-or-focus window by pattern), `browser [url]`, `editor [--inline] <path>`, `config editor <path>`, `nautilus [cwd]`, `about` (fastfetch TUI), `screensaver`, `webapp <url>`, `1password|signal|spotify` (or install if missing), `discord community`, `battlenet`.
- `omarchy webapp install [name url icon …]` / `remove [name|all]` (+ `webapp handler hey|zoom` protocol handlers); `omarchy tui install|remove` (same for terminal apps).
- `omarchy menu …` controls the launcher (§9.3); helpers: `menu keybindings`, `menu herdr keybindings`, `menu emoji|clipboard|input|images|file`.

## 21. Hardware Support

- Detection catalog (`omarchy hw …`): `laptop, nvidia|nvidia-gsp|without-gsp, hybrid-gpu, intel|intel-ptl|intel-sof, vulkan, webcam, touchpad|touchscreen (names), display (backlight node), external-monitors, surface, framework16, asus-rog, asus expertbook/zenbook, dell xps13-sidecar-amps|xps-haptic-touchpad|xps-oled, match <pattern>, recover-internal-monitor`.
- Fix scripts (`install/hardware/`): nvidia, vulkan, network, bluetooth, wireless-regdom, speaker-tuning, fkeys, synaptics, apple (T2/SPI/nvme/brcmfmac), asus (PTL display/backlight/touchpads, Z13), framework (QMK), intel (wifi7-EHT, IPU7 camera, LP-MD, SOF, thermald, video-accel, PTL kernel), lenovo yoga bass, dell XPS amps/haptics, surface keyboard, tuxedo backlight, yt6801 ethernet, broadcom, macbook SPI.
- `omarchy apply hardware` applies the detected set; `omarchy audio tuning <on|off|…>` manages laptop speaker profiles (`omarchy-speaker-tuning.service`); hybrid-GPU laptops toggle via `omarchy toggle hybrid gpu` (supergfxd drop-in shipped).
- User units shipped: `bt-agent, omarchy-fcitx5, omarchy-migrate-notify, omarchy-recover-internal-monitor, omarchy-sleep-lock, omarchy-tailscale-receive, omarchy-crash-watch, app.slice.d`.

## 22. Network & Connectivity

- `omarchy network status|speedtest|qr|password|band` (shell feeds + sharing), `omarchy dns [Cloudflare|Google|DHCP|Custom]`, `omarchy tailscale send|receive` (Taildrop), bluetooth power/device (`restart bluetooth`, `bt-agent.service`), `restart wifi|trackpad|audio`, SSH via setup wizard (§18).

## 23. Audio, Brightness, Capture, Media

- Audio: full input/output node controls, `output volume <raise|lower|mute-toggle|±N>` + OSD, `output switch`, `source switch`, `sink availability`, `audio tuning`, mic-mute LED support; `restart audio` recovers stuck USB devices; `default/audio`, wireplumber templates in `config/`.
- Brightness: focused/DDC/Apple-XDR display + keyboard backlight (+ mic-mute LED), all OSD-driven.
- Capture: `screenshot [smart|region|windows|fullscreen]`, `screenrecording [--fullscreen] [--with-desktop-audio] [--with-microphone-audio] [--with-webcam] [--stop-recording]`, `capture text` (OCR), `capture qr`, `capture webcam resize`.
- Media helpers: `transcode [input format resolution]` (+ `transcode ascii` image→braille/block art), `drive select|info|password`, `disk speedtest`, `clipboard paste text|file|open`, `file select`.
- Fun: `omarchy ascii [text]` (Omarchy-font ASCII art), `branding about-animation` (shared animation helpers — the same mechanism behind animated About logos), `screensaver` (random TTE terminal effects).

## 24. Desktop Utilities & Shell Services

- `omarchy notification send|dismiss|battery|time|weather`, `omarchy osd -i -m -p -d` (volume/brightness overlays), `omarchy reminder <min> [msg]|show|clear`, `weather status|icon|location`, `system stats [--bar-widget]`, `system wake`, `power present`, `powerprofiles init|list|set` (AC/battery-aware), `hibernation setup|remove|available`, `battery present|status|low`, `font current|list|set`, `display text size`, `monitor state`, `bar use|reset|defaults|position|transparent|put|move|set`, `bar text color`, `shell [-q] <target> <method>` (raw shell IPC), `plymouth list|set|preview|switcher|reset|current`, `branding about|screensaver <image|text|reset>`, `cmd missing|present|terminal-cwd`, `crash watch|mute`, `debug`, `menu toggle|summon|close|refresh|ping`.
- Toggles (`omarchy toggle <flag> [on|off]`): `bar, crash-capture, hybrid-gpu, idle, nightlight, notification-silencing, screensaver, suspend, touchpad, touchscreen` (flag files; `toggle enabled` probes; hypr flags in `toggles/hypr/flags.lua` via `hyprland toggle`).
- Restarts (`omarchy restart …`): `app, audio, bluetooth, btop, helix, herdr, hyprctl, hyprsunset, opencode, shell, terminal, tmux, trackpad, wifi, xcompose`.
- Hyprland extras: window gaps/transparency/tiled-fullscreen/pop/width/aspect toggles, workspace dwindle/scrolling toggle, monitor internal/external/clamshell/mirror/scaling/watch, session-lock probe, `hyprland focus app`, `window close all`, reload guard.

## 25. Windows VM & Gaming Launchers

- `omarchy windows key` (OEM firmware key), `windows vm <install|remove|launch|stop|status>`; game launchers under `launch`/`games`/`install gaming` (§19–20).

## 26. Update Subsystems Detail

`omarchy update` (§6) decomposes into: `update available|confirm|analyze-logs`, `update dev|keyring|system-pkgs|aur-pkgs|mise|orphan-pkgs|firmware (fwupd)`, `update-pkg-prune`, `update-when-conflicted`, `update-lock`, `update-stay-awake`, `snapshot create|restore`, `migrate`, `hook post-update`, restart prompt. Version probes: `version`, `version channel`, `version pkgs`, `version-branch`.

## 27. Contributor Workflow (dev-link)

`omarchy dev link <checkout>` repoints the system at local source after reboot (`dev status`, `dev unlink` to restore); `dev add migration`, `dev pkg test`, `dev theme preview`, `dev ui preview` (shell widget gallery), `dev benchmark cli|theme-switcher`, `dev font`, `dev install ydoo`. `/etc/omarchy.conf` is the repoint switch.

## 28. Recovery Matrix

| Situation | Fix |
|---|---|
| Bad config edit | `omarchy refresh config <path>` (auto-backup) |
| Broken bar/shell | `omarchy refresh shell` / `restart shell` |
| Broken Hyprland | `omarchy refresh hyprland`, `hyprctl configerrors` |
| Bad update | Boot Limine → `Snapshots` entry; `omarchy snapshot restore` |
| Broken packages | `omarchy reinstall pkgs` (stable channel) |
| Wrecked `$HOME` configs | `omarchy reinstall configs` (**destructive**) |
| Sell/give away machine | `omarchy system factory reset` |

## Appendix D — Complete Command Reference

Every route from `omarchy commands --all` (452 lines), condensed. For full syntax run
`omarchy <group> <action> --help`.

```
agent crash|prompt|usage|usage-update — AI agent launch, prompts, crash diagnosis, usage stats
apply hardware|lock|system — apply hardware quirks, lock-screen auth, installed-target setup
ascii — render text in the Omarchy logo font
audio input|output|sink|source|tuning — PipeWire node/volume/mute/speaker-tuning controls
bar use|reset|defaults|position|transparent|put|move|set + text color — bar layout control
battery present|status|low — battery probes + low-battery notifier/hooks
bluetooth power|device — radio + device pairing
branding about|about-animation|screensaver — About/screensaver art + animation helpers
brightness display|keyboard — display/DDC/Apple/keyboard backlight + mic-mute LED
capture screenshot|screenrecording|text|qr|webcam — screenshots, recordings, OCR, QR
channel current|set — release channel (stable|rc|edge|dev)
clipboard open|paste — clipboard history + paste helpers
cmd missing|present|terminal-cwd — dependency probes, active terminal cwd
config — shipped-config queries/paths
crash watch|mute — crash capture + AI diagnosis
debug — diagnostics bundle
default agent|browser|editor|terminal — system defaults + launchers
dev link|unlink|status|add-migration|pkg-test|theme-preview|ui-preview|benchmark|font|install-ydoo
disk speedtest — disk benchmarks
display text size — global text scaling
dns — DNS provider (Cloudflare|Google|DHCP|Custom)
drive select|info|password — drive picking + encryption passwords
file select — desktop file chooser
finalize — install finalization (hidden)
font current|list|set — monospace font management
games retro — RetroArch core listing/game launchers
hibernation setup|remove|available — swap + resume hibernation
hook [name] + install — event hooks (§11)
hw asus|dell|framework|intel|nvidia|surface|laptop|display|touchpad|… — hardware detection (§21)
hyprland monitor|window|workspace|toggle|focus|session|reload-guard — compositor controls (§24)
install ai|app|browser|chromium|dev-env|docker|editor|font|gaming|hermes|preinstalls|service|terminal — software catalog (§19)
installed — optional-service checks
launch terminal|tui|browser|editor|webapp|nautilus|about|screensaver|… — app launchers (§20)
menu toggle|summon|close|refresh + clipboard|emoji|file|images|input|keybindings — launcher control (§9.3)
migrate — pending/one-shot migrations (§6)
mise install — mise-backed tool wrappers
monitor state — panel state for the shell
network status|speedtest|qr|password|band — network helpers
notification send|dismiss|battery|time|weather — desktop notifications
osd — on-screen display overlays
pkg add|drop|present|missing|install|remove + aur — package helpers
plymouth list|set|preview|switcher|reset|current — boot splash theming
power present — AC detection
powerprofiles init|list|set — AC/battery power profiles
provision owner|user|first-run — first-boot provisioning (§17)
refresh config|shell|hyprland|… — config reset with backup (§7)
reinstall (+configs|pkgs) — package reinstall / config nuke
reminder — minute-based desktop reminders
remove ai|browser|dev-env|gaming|preinstalls|security|service — software removal (§19)
restart app|audio|bluetooth|btop|helix|herdr|hyprctl|hyprsunset|opencode|shell|terminal|tmux|trackpad|wifi|xcompose
screensaver — TTE-effect terminal screensaver
setup direct-boot|security — EFI entry, FIDO2, fingerprint, sshd, sudoless docker (§18)
shell — raw IPC to the running shell
snapshot create|restore — snapper snapshots
sudo keepalive|passwordless|docker — privilege helpers
system lock|logout|reboot|shutdown|stats|wake|factory-reset — session + power
tailscale send|receive — Taildrop file transfer
theme list|set|current|install|remove|update|refresh|switcher|dir|extras + bg next|set|current|cache|install|bg-switcher
toggle bar|crash-capture|hybrid-gpu|idle|nightlight|notification-silencing|screensaver|suspend|touchpad|touchscreen
transcode (+ascii) — media + image-to-ASCII transcoding
tui install|remove — terminal-app launchers
update (+available|confirm|dev|keyring|system|aur|mise|orphan|firmware|analyze-logs) — full update pipeline (§6/§26)
version (+channel|pkgs) — version probes
voxtype install|remove|config|model|status — dictation service
weather status|icon|location — weather for the bar
webapp install|remove + handler — web-app launchers
windows key|vm — OEM key + Windows VM
wifi — (via NetworkManager applets/menus; radio via restart wifi)
```

Regenerate/verify this list anytime with: `omarchy commands --all` (452 lines).

