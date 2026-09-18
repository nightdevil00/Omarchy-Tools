# Custom Fonts in Omarchy

How to set custom fonts everywhere in Omarchy (terminals, the Omarchy shell
bar, GTK/UI apps, browsers). Written after switching the whole system to the
Apple SF Pro / SF Mono / New York typefaces.

## Layout

| Where | What to change | Example value |
|-------|----------------|---------------|
| Terminal + shell bar + monospace UI | `omarchy font set` + fontconfig alias | `SF Mono` |
| GTK apps / browser standard font | fontconfig `sans-serif` alias + gsettings | `SF Pro` |
| Documents / reader serif | fontconfig `serif` alias + gsettings | `New York` |

Fontconfig is the source of truth. The Omarchy bar (`~/.config/omarchy/` +
`/usr/share/omarchy/shell/Commons/Style.qml`) renders with the `monospace`
alias, so whatever the alias resolves to shows up in the bar, Qt apps, and
anything else that asks for `monospace`.

## 1. Install the fonts

The AUR `apple-fonts` package (SF Pro, SF Compact, SF Mono, New York) must be
built against Apple's current DMGs. Until the maintainers update the stale
checksums/layout, run the fixed local copy:

```bash
yay -S apple-fonts            # may fail on checksum/prepare()
# fix /home/mihai/.cache/yay/apple-fonts/PKGBUILD as needed:
#   - update sha256sums for SF-Pro / SF-Compact to match the downloaded DMGs
#   - patch prepare() for the new APFS distribution-pkg format (no License.rtf)
sha256sum SF-Pro-7.0.6.dmg SF-Compact-7.0.6.dmg
cd /home/mihai/.cache/yay/apple-fonts && makepkg -f      # then: sudo pacman -U *.pkg.tar.zst
```

Verify the families are registered:

```bash
fc-list : family | grep -iE 'sf pro|sf mono|new york' | sort -u
```

## 2. Monospace everywhere (canonical way)

```bash
omarchy font list        # available monospace fonts
omarchy font current     # current monospace font
omarchy font set "SF Mono"
```

`omarchy font set` does all of this in one step:

- rewrites `~/.config/alacritty/alacritty.toml`, `~/.config/ghostty/config`,
  `~/.config/foot/foot.ini`, `~/.config/kitty/kitty.conf`
- writes the `monospace` → chosen family alias into
  `~/.config/fontconfig/fonts.conf`
- restarts the Omarchy shell (`omarchy-restart-shell`)
- fires the `font-set` hook (`omarchy hook install font-set <script>`)

Note: `omarchy font set` *overwrites* `fonts.conf` with only the `monospace`
alias, so run it **before** adding the extra aliases below.

## 3. Default fonts for everything else

`~/.config/fontconfig/fonts.conf` — alias the generic families so browsers and
GTK apps pick custom fonts without per-app config:

```xml
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <match target="pattern">
    <test name="family" qual="any"><string>monospace</string></test>
    <edit name="family" mode="prepend_first" binding="strong"><string>SF Mono</string></edit>
  </match>
  <match target="pattern">
    <test name="family" qual="any"><string>sans-serif</string></test>
    <edit name="family" mode="prepend_first" binding="strong"><string>SF Pro</string></edit>
  </match>
  <match target="pattern">
    <test name="family" qual="any"><string>serif</string></test>
    <edit name="family" mode="prepend_first" binding="strong"><string>New York</string></edit>
  </match>
</fontconfig>
```

Verify resolution:

```bash
fc-match "monospace"   # -> "SF Mono" "Regular"
fc-match "sans-serif"  # -> "SF Pro"  "Regular"
fc-match "serif"       # -> "New York" "Regular"
```

## 4. GTK / interface fonts

```bash
gsettings set org.gnome.desktop.interface font-name 'SF Pro Text 11'
gsettings set org.gnome.desktop.interface document-font-name 'New York 12'
gsettings set org.gnome.desktop.interface monospace-font-name 'SF Mono 10'
```

Persist for GTK3/GTK4 apps that read `settings.ini`:

```bash
mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0
```

`~/.config/gtk-3.0/settings.ini` and `~/.config/gtk-4.0/settings.ini`:

```ini
[Settings]
gtk-font-name=SF Pro Text 11
gtk-monospace-font-name=SF Mono 10
```

## 5. Keep icon glyphs (Nerd Fonts) in the terminal

SF Mono has no Nerd Font glyphs, so prompts like starship or lazygit will show
tofu blocks. Add the Nerd Font as a fallback **after** the primary family:

- `~/.config/foot/foot.ini`:

  ```ini
  font=SF Mono:size=9, JetBrainsMono Nerd Font:size=9
  ```

- `~/.config/ghostty/config`:

  ```ini
  font-family = SF Mono, JetBrainsMono Nerd Font
  ```

Alacritty resolves missing glyphs through fontconfig automatically, so a
single family is fine there.

## 6. Notifications

Omarchy does **not** use mako. Notifications are rendered by the Omarchy
shell (Quickshell) itself via `omarchy notification send` /
`omarchy-notification-send`, and they draw in the shell's `monospace` font
(`Style.qml`'s `fontFamily`). So notifications pick up whatever the
`monospace` alias resolves to (SF Mono here) with no extra config — just
restart the shell (`omarchy-restart-shell`) to re-resolve.

## 7. Apply / restart

```bash
omarchy restart terminal    # reload running terminals
omarchy-restart-shell       # re-resolve fonts in the bar
fc-cache -f                 # rebuild font cache
```

- Hyprland itself uses no fonts; `hyprlock` and other themed tools fall back
  to fontconfig's `monospace`, so they follow automatically.
- Restart browser windows for new fonts. Fonts chosen inside a browser's own
  settings (Chrome `chrome://settings/fonts`, etc.) override the system
  defaults.
- Running GTK apps pick up gsettings/`settings.ini` changes on restart.

## 8. Reverting

```bash
omarchy font set "JetBrainsMono Nerd Font"   # back to the stock monospace
rm -f ~/.config/fontconfig/fonts.conf        # drop the extra aliases
gsettings reset org.gnome.desktop.interface font-name
```

For a full shell reset: `omarchy refresh shell` (backs up first).