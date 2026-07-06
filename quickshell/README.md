# Quickshell configs

Personal [Quickshell](https://quickshell.org/) layouts under `~/.config/quickshell`.

## Production: `samael`

**Run:** `qs -c samael`

Hybrid shell: **ii-derived Samael bar** (super menu, sidebar, media & performance drops, Wallust) + **Caelestia** vendored under `samael/vendor/` (lock, launcher/drawers, performance cards). Legacy trees `quickshell/ii` and `quickshell/caelestia` were removed from this repo.

| Doc | Path |
| ----- | ------ |
| Full setup, build, IPC, keybinds | [`samael/README.md`](samael/README.md) |
| In-repo Caelestia defaults | [`samael/config/shell.json`](samael/config/shell.json) |
| Vendor commit pin | [`samael/vendor/VENDOR_SHA`](samael/vendor/VENDOR_SHA) |

### Quick start (this machine)

```sh
# 1) Caelestia plugin (once per machine / after vendor bump)
cd ~/.config/quickshell/samael/vendor/caelestia-shell/plugin
cmake -B ../build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$HOME/.local"
cmake --build ../build && cmake --install ../build

# 2) Runtime JSON (Caelestia.Config reads this path)
mkdir -p ~/.config/caelestia
# merge or copy from samael/config/shell.json

# 3) Session
qs -c samael &
```

Hypr autostart should launch **`qs -c samael`** (see `hypr/hyprland/execs.lua` in dotfiles). Lock: `Ctrl+Alt+L` → `samael:lock`. Launcher: **Super** → `samael:launcher`.

### Other paths

| Path | Role |
|------|------|
| `openspec/` | Spec-driven change notes for the samael fork. |
| `samael/modules/ii/` | Background/widgets copied inside samael (not a separate `qs -c ii` config). |

## Portability

Copy **`quickshell/samael/`** (including **`vendor/caelestia-shell/`**, excluding **`vendor/caelestia-shell/build/`**) to another host. Rebuild the Caelestia CMake plugin locally; install system deps (Qt 6.9+, PipeWire, cava, etc.); set `~/.config/caelestia/shell.json` and Hypr/Wallust/fastfetch as on the source machine.
