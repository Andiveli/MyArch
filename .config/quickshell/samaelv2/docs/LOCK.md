# Lock (samaelv2 native)

Wayland session lock (`WlSessionLock`). Enter user password (PAM) to unlock.

## Recover if stuck (red screen / “run hyprctl…”)

Hyprland **Lua config** — do **not** use `hyprctl keyword misc:…` (legacy parser error). Use:

```bash
hyprctl eval 'hl.config({ misc = { allow_session_lock_restore = true } })'
```

You already have this in `~/.config/hypr/hyprland/general.lua`; the on-screen hint is for restarting the lock **client** after it died.

**From TTY** (`Ctrl+Alt+F3`):

```bash
bash ~/.config/quickshell/samaelv2/scripts/unlock-stuck-session.sh
```

Or manual: `pkill -f 'qs -c samaelv2'` → `qs -c samaelv2 &` → `systemctl --user restart hypridle` → `Ctrl+Alt+F1` (your Hypr TTY).

If still locked with no client: **log out / log in** (session lock state lives in the compositor until then).

## Hypr + idle

- **Ctrl+Alt+L** → `samaelv2/scripts/LockScreen.sh` (see `hyprland/keybinds.lua`)
- **hypridle** `$lock_cmd` must point at the same script (not `qs -c samael`)

## config.json

```json
"lock": { "previewUi": false }
```

## PAM

`assets/pam.d/passwd` — default `pam_unix` only. If unlock always fails, check journal / try login on TTY with same password.

## IPC

- `qs -c samaelv2 ipc call lock lock`
- `qs -c samaelv2 ipc call lock unlock`
- Global: `quickshell:samaelv2Lock`