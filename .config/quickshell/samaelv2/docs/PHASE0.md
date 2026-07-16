# samaelv2 — Phase 0

Run:

```sh
qs -c samaelv2
```

## Immutable constraints (Engram)

Product non-negotiables and the idle-performance checklist are stored in **Engram** (project `samaelv2`). Check there before changing architecture, polls, or bar/cava behavior.

| Ref | Topic key | What |
|-----|-----------|------|
| **#1331** | `architecture/quickshell-immutable-constraints` | Performance/idle near-zero, keyboard-first, Apple-like motion, pill reference; JSON for visibility/modules, **not** keybinds |
| **#1362** | `architecture/performance-idle-checklist` | Operational rules (e.g. **cava subprocess only while MPRIS `Playing`**; heavy loaders only when surfaces open) |
| **#1332** | `architecture/top-bar-ui` | Three-zone bar (left workspaces, right cava\|mpris, middle pill) |

Retrieve: Engram `mem_get_observation` on those ids, or search `inmutables` / `1331` in project `samaelv2`.

## JSON config (`config.json`)

- **`bar.enabled`**: show top bar (`false` = no panels, no widgets, no cava process, no wallust poll).
- **`bar.left` / `bar.middle` / `bar.right`**: widget id lists.
- Widget ids: `workspaces`, `launcher`, `ai`, `notifications`, `separator`, `clock`, `cava`, `media` (alias `mpris`). Only ids listed in a zone are loaded (lazy `Loader`).
- **`launcher`**: middle surface app search (`.desktop` scan). Super release → Hypr `quickshell:samaelLauncherToggle`; `qs -c samaelv2 ipc call samaelv2 openLauncher`. Config: `launcher.pinned`, `middle.surfaces.launcher` size (drives morph).
- **`cava`**: while widget is in JSON, **`cava` process stays on** (PipeWire — all system audio, not only MPRIS). See Engram #1344 P2. **Idle CPU:** this subprocess is usually the gap vs “0% qs” unixporn posts — remove `cava` from `bar.right` if you want near-idle CPU (widget gone too).
- **`clock`**: updates every **30s** (not 1 Hz) when in bar.
- **`middle.surfaces`**: target size per surface name (first: `media`). **`settings`**: config editor (Caelestia-style nav, Wallust, vim). Open: `SUPER+CTRL+S` → `samaelSettingsMenuToggle`, or `qs -c samaelv2 ipc call samaelv2 openSettings`. (`SUPER+SHIFT+S` = screenshot in Hypr `keybinds.lua`.) Save with **s** writes `config.json` (ShellConfig hot-reloads).
- **`style`**: `cornerRadius`, `sectionBottomMargin`.
- **`left.surfaces` / `middle.surfaces`**: pill morph sizes when open.
- **`style`**: chrome, section margins, **innerMarginLeftAll**, **innerMarginMiddleSides**, **innerMarginRightBeforeContent**.
- **Keybinds are NOT in JSON** — Hyprland + `qs ipc call samaelv2 …` only.
- **Focus**: overlay always on (middle visible at idle); input mask is middle rect when collapsed, full screen when media/notifications open. Reserve never takes keyboard focus.

## OSD volume / brightness (idle CPU)

- No 24/7 `wpctl` / sysfs loops — poll only during a short burst when OSD shows or when IPC is called.
- Optional after `Volume.sh` / `Brightness.sh` (keeps bar OSD in sync with keybinds):
  ```sh
  qs -c samaelv2 ipc call samaelv2 osdVolume
  qs -c samaelv2 ipc call samaelv2 osdBrightness
  ```

## IPC (keyboard hooks via Hyprland `exec`)

```sh
# No-arg entry points (recommended from terminal / Hypr)
qs -c samaelv2 ipc call samaelv2 openMedia
qs -c samaelv2 ipc call samaelv2 openNotifications
qs -c samaelv2 ipc call samaelv2 hide

# Or pass monitor name to media()
qs -c samaelv2 ipc call samaelv2 media ""
```

Example Hyprland bind:

```conf
bind = SUPER, M, exec, qs -c samaelv2 ipc call samaelv2 openMedia
bind = ESCAPE, , exec, qs -c samaelv2 ipc call samaelv2 hide
```

## Architecture

- Three zones; **middle** is one `MiddlePill` on overlay (rest + media + notifications + wallpaper morph). Reserve: left + right only. Notifications / Wi‑Fi surfaces open from **middle**; Hypr `SUPER+SHIFT+N` → `samaelNotificationsMenuToggle`, `SUPER+SHIFT+W` → `samaelWifiMenuToggle`.
- Colors: `../qml_color.json` (Wallust hook TBD).
- Next: MPRIS, real cava, notifications/performance/wifi/bt surfaces, vim navigation inside surfaces.
