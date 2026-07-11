# `samael-wallpaper.sh` (canonical, do not relocate)

**Path:** `~/.config/hypr/scripts/samael-wallpaper.sh`

Applies one image on the focused monitor (`swww`), updates illogical-impulse config, copies to `~/.config/hypr/wallpaper_effects/.wallpaper_current`, runs **`WallustSwww.sh`** (same directory), waits for `colors-waybar.css`, then tries `qs -c samael ipc call wallustColors reload`.

Treat this script as **frozen**: callers must point here; do not duplicate or move without updating every entry below.

## Who calls it

| Consumer | File | How |
|----------|------|-----|
| **samaelv2** picker + apply | `~/.config/quickshell/samaelv2/singletons/WallsService.qml` | `applyScript` → `bash` + image path |
| **samaelv2** random wallpaper IPC | `~/.config/quickshell/samaelv2/shell.qml` | `wallpaperRandom()` bash one-liner |
| **Hypr** random (UserScripts) | `~/.config/hypr/UserScripts/WallpaperRandomSamael.sh` | `SAMAEL_APPLY=…` |
| **Hypr** select (UserScripts) | `~/.config/hypr/UserScripts/WallpaperSelectSamael.sh` | `SAMAEL_APPLY=…` |
| **samael** picker content | `~/.config/quickshell/samael/modules/samael/SamaelWallpaperPickerContent.qml` | `applyScript` |
| **samael** random shortcut string | `~/.config/quickshell/samael/modules/samael/SamaelWallpaperPicker.qml` | embedded bash |
| **samael** supermenu theme | `~/.config/quickshell/samael/modules/samael/widgets/supermenu/SuperMenuThemeBody.qml` | embedded bash |

## Dependencies (same tree)

- `~/.config/hypr/scripts/WallustSwww.sh`
- `hyprctl`, `jq`, `swww` (`awww`/`awww-daemon` in script), `notify-send`
- Optional: `qs -c samael` for bar palette IPC (samaelv2 may reload Wallust via its own `WallustColors` watcher)

## Removed location (do not use)

`~/.config/quickshell/samael/scripts/wallpaper/samael-wallpaper.sh` — retired; keep `quickshell/.../scripts/` for other tooling only.

## Adding a new caller

Use exactly:

```bash
bash "$HOME/.config/hypr/scripts/samael-wallpaper.sh" "/absolute/or/relative/image/path.jpg"
```

Do not fork the script; extend behavior here only if all consumers need the same change.