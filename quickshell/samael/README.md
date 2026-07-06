# samael Quickshell config (`qs -c samael`)

Production shell for this dotfiles setup. Parent overview: [`../README.md`](../README.md).

## What you get

| Layer | Source | In session |
| ------- | -------- | ------------ |
| Bar, super menu, drops (media + performance), Wallust | ii-derived `modules/samael/` | On |
| Lock, idle, drawers (chrome off) | Vendored Caelestia `modules/` | On |
| App launcher (**notlight**) | `modules/launcher/` (not Caelestia) | On |
| `Caelestia.Config` / wavy UI | `vendor/caelestia-shell` + CMake plugin → `~/.local` | Required |

**Keybinds (Hypr):** Super (release) → **notlight** · Ctrl+Alt+L → lock · Super+Shift+O → performance drop · globals `samael:*` and `quickshell:samael*` (see below).

## Vendor

[caelestia-shell](https://github.com/caelestia-dots/shell) lives under `vendor/caelestia-shell/`.
Commit pin: `vendor/VENDOR_SHA`. Symlinks at config root: `assets`, `components`, `utils` → vendor.

**Build artifacts** (`vendor/caelestia-shell/build/`) are gitignored — compile on each machine.

## Caelestia QML plugin (CMake)

The vendored tree ships `Caelestia.Config`, `Caelestia.Blobs`, and related QML modules under `vendor/caelestia-shell/plugin/`.

### Arch build dependencies

Runtime (plugin + vendored QML):

- `qt6-base`, `qt6-declarative` (≥ 6.9 for vendored CMake)
- `libqalculate`, `libpipewire-0.3`, `aubio`, `libcava` (or `cava`)
- `lm-sensors` (optional; CMake may warn if missing)

Build:

- `cmake`, `ninja`, `gcc`, `pkg-config`

### Build and install

```sh
cd ~/.config/quickshell/samael/vendor/caelestia-shell/plugin
cmake -B ../build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$HOME/.local"
cmake --build ../build
cmake --install ../build
```

Installed QML plugins are typically under:

`$HOME/.local/lib/qt6/qml/Caelestia/` (or `$HOME/.local/lib/qml/Caelestia/` depending on Qt layout).

Quickshell resolves `import Caelestia.Config` from the user QML import path after install.

### Config JSON

`Caelestia.Config` reads **`~/.config/caelestia/shell.json`** (not under `samael/`). For slice 1, copy or merge defaults from `samael/config/shell.json` into that path before running a full Caelestia shell entry.

Samael-specific defaults in-repo: `config/shell.json` — background on, Caelestia bar/**drawer launcher**/dashboard/session/sidebar off, lock on, `smartScheme: false` (Wallust colours via `qs.services` `Colours`). App search uses **notlight** (`NotlightLauncher` in `shell.qml`), not `vendor/.../modules/launcher`.

### Dry import check (slice 2+)

Once `shell.qml` exists:

```sh
qs -c samael -n  # or quickshell dry-run if supported
```

Slice 1 verifies plugin configure/build and QML bridge tests locally.

### IPC (`qs -c samael ipc call …`)

No `caelestia-cli` — use Quickshell IPC directly.

**Lock** (`target: lock`)

- `lock` — lock session
- `unlock` — unlock (when applicable)
- `isLocked` — returns lock state
- Hypr / hypridle example: `qs -c samael ipc call lock lock`

**Notlight launcher** (`target: spotlight` — see `modules/launcher/README.md`)

- `toggle` / `show` / `hide` — show or hide the panel
- `themeMacos` / `themeWin95` — built-in themes; or `/theme macos` in the search bar
- Data: `~/.config/quickshell/spotlight-data/`

```sh
qs -c samael ipc call spotlight toggle
```

Hypr: Super alone → `samael:launcher` (release) runs the same IPC. Caelestia drawer launcher is **disabled** (`launcher.enabled: false`, stub in `modules/drawers/Panels.qml`).

**Drawers IPC** (`target: drawers`) — other Caelestia panels only; `toggle launcher` also routes to notlight via `Shortcuts.qml`, not `ShellState.launcher`.

### Hyprland global shortcuts

Lock/launcher `CustomShortcut` entries register as **`samael:<name>`** (`components/misc/CustomShortcut.qml`, `appid: "samael"`). That is separate from IPC (`qs -c samael ipc call lock lock` / `drawers toggle launcher`) but hits the same handlers when `qs -c samael` is running.

Hypr example (`~/.config/hypr/hyprland/keybinds.lua`):

- **Launcher (notlight):** `SUPER` alone → `hl.dsp.global("samael:launcher")` with `release = true`.
- **Lock:** `CTRL + ALT + L` → `hl.dsp.global("samael:lock")` (not `LockScreen.sh`).

Samael bar features use **`quickshell:samael…`** globals (different registration path in `SamaelBar.qml`).

### Lock fetch card

- UI: `modules/lock/Fetch.qml` (title `caelestiafetch.sh`, OS/WM/USER/UP/BATT + colour swatches).
- Optional terminal script: `scripts/caelestiafetch.sh` (defaults to `~/.config/fastfetch/config-pokemon.jsonc`; override with `SAMAEL_FETCH_CONFIG`).

## Self-contained paths (no `quickshell/ii`)

- Wallpaper apply: `scripts/wallpaper/samael-wallpaper.sh` (swww + Wallust + `qs -c samael ipc call wallustColors reload`).
- Hypr autostart/idle should use **`qs -c samael`** and lock via **`samael:lock`** or `ipc call lock lock`.
- Background widgets live under `modules/ii/background/` inside this config (not the sibling `quickshell/ii` tree).

## Wallust colour bridge

- `modules/samael/WallustColors.qml` — wallust CSS reader
- `modules/bridge/SamaelLockColors.qml` — M3 surface roles
- `services/Colours.qml` — `qs.services` singleton replacing vendored matugen `Colours`

## Tests

```sh
cd ~/.config/quickshell/samael/tests
qmltestrunner -input . -o /tmp/samael-qmltest.txt,txt
qmllint ../services/Colours.qml ../modules/bridge/*.qml ../modules/samael/WallustColors.qml
```
