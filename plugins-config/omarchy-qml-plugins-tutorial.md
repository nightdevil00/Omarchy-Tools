# Omarchy QML Plugins — Tutorial & Reference

> For humans learning the system and for AI agents writing plugins.
> Every claim below was verified against the live source in
> `/usr/share/omarchy/shell/` on 2026-09-03. When in doubt, read the
> source paths quoted inline — they are the ground truth.

**How to use this doc:** humans read top to bottom and build the
"Hello Bar" example in §8. Agents: obey the machine-rules in §13
(paths, required manifest fields, ID rules, IPC string quirk) and
validate with the checklist in §14 before touching anything else.

---

## 1. The big picture (60 seconds)

- `omarchy-shell` is **one long-running Quickshell process** (one per
  Hyprland session, launched as `quickshell -p $OMARCHY_PATH/shell`).
- The bar, menus, lock screen, notifications, OSD — everything — runs
  **inside** that process as a **plugin**. Nothing cold-starts per click;
  summoning a panel is an IPC call into an already-running process.
- A plugin is **a folder of QML (+JS/JSON/assets) plus a `manifest.json`**.
  Stock plugins live in `/usr/share/omarchy/shell/plugins/` (read-only).
  Yours live in `~/.config/omarchy/plugins/<plugin-id>/`.
- The shell discovers plugins at startup (`services/PluginRegistry.qml`),
  reads enabled state and per-instance settings from
  `~/.config/omarchy/shell.json`, and hot-reloads your code when you save
  a file under `~/.config/omarchy/plugins/`.
- ⚠️ Plugins are **unsandboxed code** in the shell process. Only install
  code you have read.

## 2. Plugin anatomy

```
~/.config/omarchy/plugins/my.hello/
├── manifest.json      # REQUIRED: identity, kinds, entry points
├── Widget.qml         # your QML (name is free; manifest points at it)
└── Model.js (opt)     # plain JS helpers, imported as `import "Model.js" as Model`
```

Nothing else is required. No build step, no install hook — the installer
never executes plugin code; it only clones files and flips IPC switches.

## 3. `manifest.json` — field reference

Required fields (the registry warns and skips you without them):

| Field | Type | Example |
|---|---|---|
| `schemaVersion` | int, must be `1` | `1` |
| `id` | reverse-dns string, **namespaces you** | `"my.hello"` |
| `name` | human name | `"Hello"` |
| `version` | string | `"1.0.0"` |
| `kinds` | non-empty array (see §4) | `["bar-widget"]` |
| `entryPoints` | object: kind-key → relative `.qml` path | `{"barWidget": "Widget.qml"}` |

Optional fields seen in the wild: `author`, `description`,
`keepLoaded: true` (§4), `barWidget: {...}` metadata block,
`omarchy: {"clonedFrom": "omarchy.clock"}` (added by `plugin clone`).

**`entryPoints` keys are per-kind and must match exactly** (verified in
stock manifests — `services/PluginRegistry.qml:93` looks up
`entryPoints[kind]`):

| Plugin `kinds` entry | `entryPoints` key | Stock example |
|---|---|---|
| `"bar"` | `"bar"` | `omarchy.bar` → `Bar.qml` |
| `"bar-widget"` | `"barWidget"` | `omarchy.clock` → `BarWidget.qml` |
| `"panel"` | `"panel"` | `omarchy.osd` → `Osd.qml` |
| `"overlay"` | `"overlay"` | `omarchy.clipboard` → `Clipboard.qml` |
| `"menu"` | `"menu"` | `omarchy.menu` → `Menu.qml` |
| `"service"` | `"service"` | `omarchy.lock` → `Service.qml` |

Paths must stay inside the plugin dir (the registry rejects unsafe
traversal). A plugin may declare **several kinds** with one entry point
each (`omarchy.menu` declares `menu` + `barWidget`; `omarchy.media`
declares `service` + `bar-widget`).

**`barWidget` metadata block** (for `kinds: ["bar-widget"]`):

```json
"barWidget": {
  "displayName": "Hello",
  "description": "Says hello in the bar",
  "category": "Fun",
  "allowMultiple": false,
  "defaultSection": "right",
  "defaults": { "greeting": "hello" },
  "schema": [{ "key": "greeting", "type": "string", "label": "Greeting" }]
}
```

`defaultSection` (`left|center|right`, else center) decides where
`omarchy plugin enable` drops you. `allowMultiple: true` lets users add
several independent instances with different settings (e.g. two clocks,
two timezones).

## 4. The six kinds & their lifecycles

| Kind | Renders | Loaded… |
|---|---|---|
| `bar-widget` | a slot in the bar | mounted while its `shell.json` layout entry exists |
| `bar` | a **whole bar**, replaces `omarchy.bar` | exactly one active (`bar.id`); missing/invalid falls back to built-in |
| `panel` | floating window (OSD…) | **on demand** via `summon` |
| `overlay` | fullscreen layer (clipboard, emoji, image picker…) | **on demand** via `summon` |
| `menu` | summoned menu surface | **on demand** via `summon` |
| `service` | headless singleton, no UI | **at startup** (first-party always; third-party when enabled) |

`keepLoaded: true` keeps the instance mounted across summons and across
plugin hot-reloads (used by the image picker and the lock screen — you
must not destroy a session lock mid-reload). Cost: code changes to a
`keepLoaded` plugin need a shell restart, not just a save.

## 5. What the host injects into your QML

Extend `BarWidget` (`import qs.Ui`) for bar widgets — it codifies the
three injected properties (`Ui/BarWidget.qml:15-17`):

```qml
import QtQuick
import qs.Commons   // Style, Color, Util singletons
import qs.Ui        // BarWidget, WidgetButton, Panel, … (§6)

BarWidget {
  id: root
  moduleName: "my.hello"   // your manifest id; the host overwrites per-instance

  // settings = THIS instance's shell.json layout entry, e.g.
  // { "id": "my.hello", "greeting": "hi" }.
  // setting(name, fallback) reads one key safely:
  readonly property string greet: setting("greeting", "hello")

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.greet
    onPressed: function(b) { if (root.bar) root.bar.run("notify-send Hi") }
  }
}
```

| Injected | Type | Meaning |
|---|---|---|
| `bar` | host Bar object | theme + actions (table below); `null` until mounted — always guard (`bar ? …`) |
| `moduleName` | string | your plugin id (registry + IPC routing) |
| `settings` | object | your `shell.json` entry, inline — **no separate settings file exists** |

The `bar` object gives you (from `plugins/bar/README.md`):

- `bar.foreground`, `bar.background`, `bar.urgent` — **live theme colors**, use them instead of hardcoding
- `bar.fontFamily`, `bar.barSize` (26 horiz / 28 vert), `bar.position`, `bar.vertical`
- `bar.run(command)` — fire-and-forget bash (`Util.shellQuote` your args)
- `bar.showTooltip(target, text)` / `bar.hideTooltip(target)`
- `bar.requestPopout(owner)` / `bar.releasePopout(owner)` — one-popup-at-a-time; honor it

Rules that follow: work in **all four** bar positions (text widgets need a
compact icon-only form when `vertical`), size via `implicitWidth/Height`,
and prefer `WidgetButton` over raw `MouseArea` (theme states + tooltips
for free).

## 6. The UI kit (don't reinvent these)

`import qs.Commons` → `Style` (spacing/type/bar-size tokens, theme-driven),
`Color` (palette roles), `Util` (incl. `shellQuote`, `isPlainObject`).
`import qs.Ui` → `BarWidget`, `WidgetButton`, `BarIconButton`,
`BarIndicator`, `Panel`, `PanelController`, `PanelSlider`, `PanelSectionHeader`,
`PanelSeparator`, `PanelActionButton`, `PanelHero`, `PanelToolTip`,
`PopupCard`, `ConfirmDialog`, `Button`, `ButtonGroup`, `Toggle`,
`ToggleSwitch`, `Dropdown`, `SearchableDropdown`, `MultiSelect`,
`TextField`, `NumberField`, `KeyboardPanel`, `OpticalGlyph`,
`BorderOverlay`, `BorderSurface`, `CursorSurface`, `PointerMoveGate`,
`ScreenMoveRemap`, `SpeedTestOverlay`. Browse them in
`/usr/share/omarchy/shell/Ui/` before building custom controls.

Panels with popups must implement the `open/close/opened` contract on the
widget root so `summon/hide/toggle` routing and popout-switching work
(copy the pattern from `plugins/panels/clock/BarWidget.qml:60-90`).

## 7. Settings flow (shell.json is the database)

```json
{ "id": "my.hello", "greeting": "hi" }
```

- That entry **is** your settings object. No `config:` sub-object, no
  merge layers, no second file.
- New keys appear when the user edits `shell.json` or runs
  `omarchy bar set my.hello greeting hi`; read them with `setting()`.
- To **persist** a change your widget makes (e.g. clock cycling formats),
  write the entry back via the host:
  `bar.shell.updateEntryInline(moduleName, entry)` — the canonical
  round-trip lands back through the bar as the same value, so apply
  locally first for instant feedback (see `clock/BarWidget.qml:cycleFormat`).

## 8. Tutorial: "Hello Bar" in 5 minutes

**1. Scaffold** (replace `my` with your name/handle):

```bash
mkdir -p ~/.config/omarchy/plugins/my.hello
```

`~/.config/omarchy/plugins/my.hello/manifest.json`:

```json
{
  "schemaVersion": 1,
  "id": "my.hello",
  "name": "Hello",
  "version": "1.0.0",
  "author": "you",
  "description": "Says hello in the bar",
  "kinds": ["bar-widget"],
  "entryPoints": { "barWidget": "Widget.qml" },
  "barWidget": {
    "displayName": "Hello",
    "category": "Fun",
    "allowMultiple": false,
    "defaultSection": "right",
    "defaults": { "greeting": "hello" },
    "schema": [{ "key": "greeting", "type": "string", "label": "Greeting" }]
  }
}
```

`~/.config/omarchy/plugins/my.hello/Widget.qml`:

```qml
import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "my.hello"
  readonly property string greet: setting("greeting", "hello")

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.greet
    tooltipText: "Left-click changes the greeting"
    onPressed: function(b) {
      if (b === Qt.LeftButton && root.bar)
        root.bar.shell.updateEntryInline(root.moduleName, { id: root.moduleName, greeting: root.greet === "hello" ? "hi there" : "hello" })
    }
  }
}
```

**2. Load it:**

```bash
omarchy-shell shell rescanPlugins   # discover + hot-reload
omarchy plugin enable my.hello      # lands in defaultSection (right)
```

**3. Configure it** — either edit `~/.config/omarchy/shell.json`
(`{"id": "my.hello", "greeting": "hola"}`) or:

```bash
omarchy bar set my.hello greeting hola
omarchy bar move my.hello left   # reposition
```

**4. Iterate:** just save the file — code reloads automatically. Forcing:
`omarchy-shell shell rescanPlugins`. Watching errors: run
`omarchy restart shell` from a terminal and read its stdout/stderr
(QML warnings land there).

**5. Ship it:** `manifest.json` at repo root + `omarchy plugin add <git-url>`.

## 9. Service plugins (headless)

A service is an `Item` with **no visuals** that runs at startup:

```qml
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
  id: root
  property var shell: null        // host handle, injected like `bar`
  property string omarchyPath: "" // likewise

  Timer {
    interval: 60000; running: true; repeat: true
    onTriggered: Quickshell.execDetached(["my-poller"])
  }
}
```

```json
{ "schemaVersion": 1, "id": "my.poller", "name": "Poller",
  "version": "1.0.0", "kinds": ["service"],
  "entryPoints": { "service": "Service.qml" } }
```

Enable by listing in `shell.json`: `"plugins": [{"id": "my.poller"}]`
(third-party enabled ⇔ present). Real example to crib:
`~/.config/omarchy/plugins/mihai.lock/{manifest.json,Service.qml}`
— env via `Quickshell.env("HOME")`, PAM via `Quickshell.Services.Pam`,
lock surfaces via `Quickshell.Wayland.WlSessionLock`.

Summonable UI (panel/overlay/menu) follows the same shape, plus an
`IpcHandler { target: "my.id" }` exposing `open/close/toggle`-style
functions, driven from anywhere with:

```bash
omarchy-shell shell summon my.id '{"key":"value"}'
omarchy-shell shell toggle my.id '{}'
omarchy-shell shell hide my.id
omarchy-shell shell call my.id refresh
```

Reference summon flows: clipboard/emoji overlays, `image-picker`
(file-based selection round-trip via `selectionFile`/`doneFile`).

## 10. Multi-monitor correctness

The bar mounts **one widget instance per monitor**, but an IPC target
routes to one handler. Never act on just `root` from IPC — relay with
`broadcast()` (defined on `BarWidget`, `Ui/BarWidget.qml:29`): the owning
instance forwards the call to its peers on every screen. The clock's
`IpcHandler` shows the pattern:

```qml
IpcHandler {
  target: "my.hello"
  function refresh(): void { root.broadcast("refresh") }
  function toggle(): void { root.togglePanel() }
}
```

## 11. Clone a builtin instead of forking it

```bash
omarchy plugin clone omarchy.clock   # → ~/.config/omarchy/plugins/<you>.clock/
```

You get the full source with `omarchy.clonedFrom` stamped in the
manifest; the shell reroutes the old id's IPC/shortcuts to your clone
and preserves bar position + settings. Delete the clone to revert.
This is the right way to tweak Clock/Audio/Network/… — never edit
`/usr/share/omarchy/shell/`.

## 12. Iteration & debugging loop

1. Save file → auto-reload (or `omarchy-shell shell rescanPlugins`).
2. `omarchy-shell shell listPlugins` — is your id discovered? (If not:
   manifest JSON invalid, id mismatch with dir name, or bad entry path.)
3. `omarchy restart shell` from a terminal — read QML errors/`console.warn`.
4. `omarchy-shell shell ping` → `ok` (is the shell even alive?).
5. `keepLoaded` services need a full shell restart to pick up code changes.

## 13. Machine rules (agents: hard constraints)

1. Plugin dir MUST be `~/.config/omarchy/plugins/<manifest-id>/` — id and
   directory name must match.
2. Manifest MUST contain `schemaVersion: 1, id, name, version, kinds
   (non-empty array), entryPoints (object)` or the registry skips it
   (`services/PluginRegistry.qml:52`).
3. `kinds` ∈ `bar, bar-widget, panel, overlay, menu, service` only.
   `entryPoints` keys ∈ `bar, barWidget, panel, overlay, menu, service`
   and must be relative paths inside the plugin dir.
4. IDs: third-party reverse-dns (`acme.weather`); personal clones
   `<username>.<name>` — never `omarchy.*` (reserved for first-party).
5. IPC `setPluginEnabled` takes a **string**: only literal `"true"`
   enables; `"True"/"1"/"yes"` DISABLE. Never hand-build this call —
   use `omarchy plugin enable|disable`.
6. Settings are inline on the `shell.json` entry; never invent a second
   settings file or a `config:` sub-object.
7. Guard every use of injected `bar`/`shell` (`bar ? … : fallback`) —
   they are null before mounting.
8. One popup at a time: use `bar.requestPopout/releasePopout`.
9. IPC-exposed functions must be safe on **every monitor instance** —
   use `broadcast()` (§10).
10. Never run plugin code at install time; never `sudo` from installer
    paths; `--yes` is the non-interactive path for scripts/agents.
11. Never edit `/usr/share/omarchy/` (package-owned, overwritten on
    update). Read it; clone from it.

## 14. Common mistakes

| Symptom | Cause → fix |
|---|---|
| Plugin missing from `listPlugins` | bad JSON / missing required field / dir name ≠ id → validate manifest, rescan |
| Widget renders empty | `implicitWidth/Height` unset, or `bar` used unguarded before mount |
| Settings ignored | wrong key name, or expecting a `config:` sub-object (doesn't exist) |
| Change needs restart although saved | `keepLoaded: true` plugin — restart shell |
| Toggle works on one monitor only | acted on single instance instead of `broadcast()` |
| Popup under another popup | skipped the popout coordinator |
| Hardcoded colors clash with themes | use `bar.foreground/background/urgent`, `Color` roles, `Style` tokens |
| Vertical bar looks broken | no icon-only fallback for `bar.vertical` |

## 15. Where to read next (exact paths)

- Manifest schema + IPC table + shell.json rules: `/usr/share/omarchy/shell/README.md`
- Stock plugin catalogue + menu/image-picker/lock/polkit notes: `/usr/share/omarchy/shell/plugins/README.md`
- Bar engine contract + widget catalogue + custom `command`/`qml` modules: `/usr/share/omarchy/shell/plugins/bar/README.md`
- Registry validation (ground truth): `/usr/share/omarchy/shell/services/PluginRegistry.qml`
- Widget base (`setting()`, `broadcast()`): `/usr/share/omarchy/shell/Ui/BarWidget.qml`
- Best full examples: `shell/plugins/panels/clock/` (widget+panel+IPC+persistence), `shell/plugins/menu/` (multi-kind), `~/.config/omarchy/plugins/mihai.lock/` (service), `~/.config/omarchy/plugins/costafot.clippy/` (third-party)
- Dev gallery of UI kit: `omarchy dev ui preview`
