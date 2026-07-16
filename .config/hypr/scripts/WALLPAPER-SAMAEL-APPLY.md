# `samael-wallpaper.sh` (canonical, do not relocate)

**Path:** `~/.config/hypr/scripts/samael-wallpaper.sh`

Applies one image on the focused monitor (`swww`), updates illogical-impulse config, copies to `~/.config/hypr/wallpaper_effects/.wallpaper_current`, runs **`WallustSwww.sh`** (same directory), waits for wallust CSS at `~/.config/waybar/wallust/colors-waybar.css` (config tree kept; Waybar daemon not used), then `qs -c samaelv2 ipc call wallustColors reload`.

## Who calls it

| Consumer | File | How |
|----------|------|-----|
| **samaelv2** picker + apply | `~/.config/quickshell/samaelv2/singletons/WallsService.qml` | `applyScript` → `bash` + image path |
| **samaelv2** random wallpaper IPC | `~/.config/quickshell/samaelv2/shell.qml` | `wallpaperRandom()` bash one-liner |
| **Hypr** random (CLI) | `~/.config/hypr/scripts/WallpaperRandomSamael.sh` | `SAMAEL_APPLY=…` |
| **Hypr** select (CLI) | `~/.config/hypr/scripts/WallpaperSelectSamael.sh` | `SAMAEL_APPLY=…` |

## Dependencies (same tree)

- `~/.config/hypr/scripts/WallustSwww.sh`
- `hyprctl`, `jq`, `swww` (`awww`/`awww-daemon` in script), `notify-send`
- Optional: `qs -c samaelv2` for bar palette IPC

## Adding a new caller

```bash
bash "$HOME/.config/hypr/scripts/samael-wallpaper.sh" "/absolute/or/relative/image/path.jpg"
```