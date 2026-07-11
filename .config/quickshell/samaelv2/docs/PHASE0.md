# samaelv2 — Phase 0

Run:

```sh
qs -c samaelv2
```

## JSON config (`config.json`)

- **`bar.enabled`**: show top bar (`false` = no panels, no widgets, no cava process, no wallust poll).
- **`bar.left` / `bar.middle` / `bar.right`**: widget id lists.
- Widget ids: `workspaces`, `ai`, `notifications`, `separator`, `clock`, `cava`, `media` (alias `mpris`). Only ids listed in a zone are loaded (lazy `Loader`).
- **`middle.surfaces`**: target size per surface name (first: `media`).
- **`style`**: `cornerRadius`, `sectionBottomMargin`.
- **`left.surfaces` / `middle.surfaces`**: pill morph sizes when open.
- **`style`**: chrome, section margins, **innerMarginLeftAll**, **innerMarginMiddleSides**, **innerMarginRightBeforeContent**.
- **Keybinds are NOT in JSON** — Hyprland + `qs ipc call samaelv2 …` only.
- **Focus**: overlay always on (middle visible at idle); input mask is middle rect when collapsed, full screen when media/notifications open. Reserve never takes keyboard focus.

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
