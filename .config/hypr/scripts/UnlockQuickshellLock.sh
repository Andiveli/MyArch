#!/usr/bin/env bash
# Emergency: session stuck on QS lock (blur only / no UI). Run from TTY after login.
set -e
pkill -x hyprlock 2>/dev/null || true
pkill -f 'qs -c samael' 2>/dev/null || pkill -x qs 2>/dev/null || true
sleep 1
# Restart QS the way your session usually does (adjust if you use a different launcher):
if command -v qs >/dev/null; then
  nohup qs -c samael >/tmp/qs-restart.log 2>&1 &
fi
echo "If Hyprland is up, QS should restart unlocked. Else: loginctl unlock-session"