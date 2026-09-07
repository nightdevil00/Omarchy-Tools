# Disable Autologin on Omarchy

Omarchy enables SDDM autologin by writing an `[Autologin]` section into the
drop-in config file `/etc/sddm.conf.d/99-omarchy-login.conf`. To disable
autologin we remove that section; SDDM then shows the greeter and asks for
credentials on every boot.

> Note: `autologin.sh` in this folder comments out a line in
> `/etc/pam.d/sddm-autologin`, which is the classic way to disable PAM-based
> autologin. On current Omarchy releases autologin is driven by the
> `[Autologin]` section in `/etc/sddm.conf.d/99-omarchy-login.conf` instead, so
> that file is the one you need to change. See below.

## Files

| File | Role |
|------|------|
| `/etc/sddm.conf.d/99-omarchy-login.conf` | SDDM drop-in that owns the omarchy theme, remembered-user settings and the `[Autologin]` section |
| `/usr/share/omarchy/default/sddm/omarchy/theme.conf` | Packaged default (read-only; contains no autologin by default) |

## What changed

Before (autologin enabled):

```ini
[Theme]
Current=omarchy

[Users]
RememberLastUser=true
RememberLastSession=true

[Autologin]
Session=hyprland
User=mihai
```

After (autologin disabled) — the `[Autologin]` section is removed:

```ini
[Theme]
Current=omarchy

[Users]
RememberLastUser=true
RememberLastSession=true
```

The `[Autologin]` block is what tells SDDM to log `User` straight into
`Session` without prompting. Deleting it makes SDDM show the greeter and wait
for a manual password.

## Steps to recreate on another Omarchy system

### 1. Review the current config

```bash
cat /etc/sddm.conf.d/99-omarchy-login.conf
```

### 2. Back up before editing

```bash
sudo cp /etc/sddm.conf.d/99-omarchy-login.conf \
        /etc/sddm.conf.d/99-omarchy-login.conf.bak
```

### 3. Remove the `[Autologin]` section

Edit the file as root and delete the `[Autologin]` block. With `sed`:

```bash
sudo sed -i '/^\[Autologin\]/,/^$/d' /etc/sddm.conf.d/99-omarchy-login.conf
```

### 4. Verify

```bash
cat /etc/sddm.conf.d/99-omarchy-login.conf   # no [Autologin] section
```

Autologin takes effect on the next boot — reboot and you should land on the
greeter rather than the desktop.

## Re-enable autologin

To enable autologin again, restore the `[Autologin]` section:

```ini
[Autologin]
Session=hyprland
User=mihai
```

Replace `mihai` with the username that should be logged in automatically.
