# Pill Animation Architecture

How the pill changes size, fades content, and synchronises the morph across
every surface — the single-container approach that samael is converging toward.

## Core Principle

**The pill IS the container.** A single `Item` (root of `Pill.qml`) changes
its `width` and `height` from a small rest state (160×38) up to full surface
sizes (e.g. 400×420 for wifi). Every child — rest content, hover icons,
surface loaders, OSD bars — lives inside this one Item. There is no separate
"dock" that contains a separate "surface stack". Expansion is the pill growing,
not a panel overlay.

```
shell.qml → PanelWindow → FocusScope → Pill (root Item)
                                              │
                    ┌─────────────────────────┼─────────────────────────┐
                    │                         │                         │
               rest (Item)               hover (Item)         ldMixer/ldCalendar/…
              rest content              workspaces +        surface loaders
              (clock, kanji)            clock + tray        (anchor fill: parent)
```

## Surface Input Chain (`shell.qml`)

### Open / Close

The shell root holds two properties:

```qml
// shell.qml
property string openMon: ""       // which monitor the surface is on
property string openSurface: ""   // which surface is open ("wifi", "calendar", …)
```

A keybind or IPC handler calls `toggleSurface(mon, surface)`:

```qml
function toggleSurface(mon, surface) {
    if (!mon || mon.length === 0)
        mon = Hyprland.focusedMonitor.name;
    if (root.openMon === mon && root.openSurface === surface) {
        root.close();              // toggle off
        return;
    }
    root.openMon = mon;
    root.openSurface = surface;    // ← triggers the whole morph cascade
}
```

### Per-Monitor Binding

Each monitor has its own `PanelWindow` (overlay). Inside it:

```qml
readonly property string surface: root.openMon === modelData.name ? root.openSurface : ""
```

This is the **single entry point** into the pill. Only the monitor matching
`openMon` receives a non-empty surface string. Every other monitor stays idle.

The `Pill` instance binds to it:

```qml
Pill {
    surface: overlay.surface    // ← direct binding from shell to pill
}
```

## Reactive Cascade (`Pill.qml`)

When `surface` changes from `""` to `"wifi"`, the following fires in a single
QML evaluation frame, each step a readonly property depending on the previous:

```
surface (string)
  ↓
surfaceOpen (bool) = surface.length > 0
  ↓
mode (string) = surfaceOpen && surfaces[surface] exists ? surface : "hover/rest/…"
  ↓
targetSize (size)  = surfaces[mode].size()  OR  modeSize[mode]()  OR  rest default
  ↓
targetW / targetH (real) = targetSize.width, targetSize.height
  ↓
width / height = targetW, targetH
  ⤷ Behavior on width { NumberAnimation { duration: Motion.morph; easing: morphCurve } }
  ⤷ Behavior on height { … }
```

### `mode` — the selector

```qml
readonly property string mode: dragActive ? "dragOver"
    : (surfaceOpen && surfaces[surface] !== undefined ? surface
    : (Flags.gameMode ? "game"
    : (quickChoosing ? "quickChoose"
    : (quickCounting ? "quickCount"
    : (osdActive && !held ? "osd"
    : (toastActive && !held ? "toast"
    : (expanded ? "hover" : "rest")))))))
```

`mode` selects between:

- **Surface modes** (when a named surface is open): `"wifi"`, `"calendar"`, …
- **Non-surface modes**: `"rest"`, `"hover"`, `"game"`, `"osd"`, `"toast"`,
  `"quickChoose"`, `"quickCount"`, `"dragOver"`

Each mode maps to a target size. Surface sizes come from `surfaces[mode]`;
non-surface sizes from `modeSize[mode]`.

### `surfaces` table

```qml
readonly property var surfaces: ({
    calendar:  { size: () => { … surfaceItem(ldCalendar); return Qt.size(w, h); },
                 ame:  () => surfaceItem(ldCalendar) },
    wifi:      …
    // one entry per surface
})
```

Each entry has:

- `size()` → thunk returning `Qt.size(width, height)`. It reads the surface's
  `implicitWidth`/`implicitHeight` so every relayout inside the surface
  retriggers `targetSize` and the Behavior animates the pill to the new size.
- `ame()` → resolves the surface item for the Ame (animated bead) to anchor on.

### Lazy Loading

Surfaces use latch-once loaders:

```qml
function surfaceItem(ld) {
    ld.active = true;     // activate on first read
    return ld.item;
}
```

Each surface Loader starts `active: false`. The first time `targetSize`
evaluates (because the surface opened), `surfaceItem(ld)` flips `active` and
the component loads **synchronously** — the size read is exact in the same
frame. After first activation, the Loader stays active forever; nothing ever
deactivates a loaded surface.

Three hot surfaces preload shortly after startup so their Pipewire trackers
are ready:

```qml
Timer {
    interval: 2500
    running: true
    onTriggered: {
        ldMixer.active = true;
        ldMedia.active = true;
        ldLink.active = true;
    }
}
```

## Morph Animation

### Behavior Always Active

```qml
Behavior on width { NumberAnimation {
    duration: pill.hoverHop ? Motion.glide : Motion.morph
    easing.type: Motion.easeMorph
    easing.bezierCurve: Motion.morphCurve
}}
Behavior on height { … }
```

**Crucially, the Behavior has no `enabled` gate.** It is always active.
This avoids the QML evaluation-order race where a gated Behavior becomes
enabled after the binding has already changed the property, causing a snap
instead of an animation.

`hoverHop` shortens the duration when the morph is between rest↔hover (a few
dozen pixels) so the settle tail doesn't read sluggish. Every real surface
morph keeps the full `Motion.morph` (420ms).

### `morphCloseness` — Synchronised Opacity

```qml
readonly property real morphCloseness: {
    const d = Math.max(Math.abs(width - targetW), Math.abs(height - targetH));
    return 1 - Math.min(1, d / (110 * s));
}
```

As the pill approaches its target size (because the Behavior is animating
width/height), `morphCloseness` rises from 0 to 1. Content opacities derive
from this single value, so *everything fades in/out together*:

- **Rest content** fades **out** as the pill expands:

  ```qml
  opacidade: expanded ? 0 : Math.pow(morphCloseness, 1.5)
  ```

- **Surface content** fades **in** as the pill reaches the target:

  ```qml
  // PillSurface
  opacity: open ? (settled ? 1 : Math.pow(morphCloseness, 1.3)) : 0
  ```

- **Hover content** fades with its own exponent:

  ```qml
  opacity: mode === "hover" ? Math.pow(morphCloseness, 1.2) : 0
  ```

The `settled` latch in `PillSurface` prevents flicker from collapsibles
that change `implicitHeight` after the surface is already open:

```qml
property bool settled: false
onOpenChanged: if (!open) settled = false
onMorphClosenessChanged: if (open && morphCloseness > 0.92) settled = true
```

Once `morphCloseness > 0.92` (the morph has basically finished), the surface
locks to full opacity and relayouts inside it no longer dim the content.

## Content Layout Inside the Pill

All content children stack in z-order within the single pill Item.

```
Pill (width: targetW, height: targetH)    ← this grows/shrinks
├── rest (Item)                           ← clock, kanji — fades out when expanded
├── hover (Item)                          ← workspaces, tray — fades in when hovered
├── osd (Item)                            ← brightness/volume bar — fades in for OSD
├── toastRoot (Item)                      ← notification toast
├── ldMixer (Loader, anchors.fill:parent)
├── ldCalendar (Loader, anchors.fill:parent)
├── ldLauncher (Loader, anchors.fill:parent)
│   …  (25 loaders total)
└── …                                     ← game, dragOver, quickChoose/Count
```

No surface ever "covers" another. They all have `anchors.fill: parent` so
they grow with the pill. Their visibility is gated by `active/open` and their
opacity by `morphCloseness`. Only one surface is `open === true` at a time,
so only one surface content is interactive.

```
idle (rest):                  expanded (wifi):
┌──────────────────────┐      ┌──────────────────────────────────┐
│  時  12:30           │      │                                  │
│  clock kanji  hhmm   │  →  │     [ wifi surface content ]     │
│                      │      │    (fading in via morphCloseness)│
└──────────────────────┘      └──────────────────────────────────┘
  160×38                         400×420
  rest content visible           rest content faded out (opacity: 0)
                                 surface fading in (opacity: morphCloseness^1.3)
```

## Keyboard Routing

The `FocusScope` in the shell's overlay PanelWindow catches all keys when
a surface is open. Each surface implements its own navigation functions
(`mixerStep`, `powerMove`, `wallpaperMove`, etc.) and the key handlers
dispatch by checking which surface is open:

```qml
Keys.onLeftPressed: (e) => {
    if (pill.mixerOpen) { pill.mixerFocusMove(-1); e.accepted = true; }
    else if (pill.wallpaperOpen) { pill.wallpaperMove(-1); e.accepted = true; }
    else if (pill.powerOpen) { pill.powerMove(-1); e.accepted = true; }
}
```

Escape closes: first tries `pill.linkBack()` and `pill.keybindsBack()`
(which return true if they consumed the key), then calls `root.close()`.

## Summary — Why This Works

| Mechanism | Detail |
| ----------- | -------- |
| Single container | The pill Item width/height IS the morph target; no overlay/stack wrappers |
| Direct binding | `surface: overlay.surface` — one binding from shell to pill, no singleton indirection |
| Always-active Behavior | No `enabled` gate, so the animation always intercepts property changes |
| `morphCloseness` sync | Content opacities share one distance metric, so fade-in/out matches the morph |
| Lazy load | `surfaceItem(ld)` activates on first read, no eager loading, no unloading |
| Preload hot surfaces | Timer flips mixer/media/link loaders after startup so Pipewire is ready |
| Per-monitor isolation | `openMon` matching means only the target monitor's pill receives the surface string |
