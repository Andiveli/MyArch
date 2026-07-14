#!/usr/bin/env bash
# Recover Hyprland stuck on dead session lock (after killing qs, etc.)
# Run from TTY or SSH — then switch back to your graphical TTY (Ctrl+Alt+F1/F2).

set -euo pipefail

echo "==> Allow lock client restore (Hyprland Lua config)"
hyprctl eval 'hl.config({ misc = { allow_session_lock_restore = true } })' 2>/dev/null || true

echo "==> Force unlock via samaelv2 IPC (if qs is running)"
qs -c samaelv2 ipc call lock unlock 2>/dev/null && echo "IPC unlock sent." || echo "qs not running or IPC failed."

echo "==> Restart samaelv2"
pkill -f 'qs -c samaelv2' 2>/dev/null || true
sleep 0.5
nohup qs -c samaelv2 >/tmp/qs-samaelv2.log 2>&1 &
disown 2>/dev/null || true
echo "qs -c samaelv2 started (log: /tmp/qs-samaelv2.log)"

echo "==> Restart hypridle"
systemctl --user restart hypridle 2>/dev/null || true

echo "Done. Switch to Hypr TTY (e.g. Ctrl+Alt+F1). If still stuck: log out/in."