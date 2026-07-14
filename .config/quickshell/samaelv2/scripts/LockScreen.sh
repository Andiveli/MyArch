#!/usr/bin/env bash
# samaelv2 session lock — used by Hypr CTRL+ALT+L, hypridle, etc.
set -euo pipefail
CFG=samaelv2
# 1) IPC (works when qs -c samaelv2 is running)
if qs -c "$CFG" ipc call lock lock 2>/dev/null; then
  exit 0
fi
# 2) Quickshell global shortcut (same as shell.qml samaelv2Lock)
hyprctl dispatch global "quickshell:samaelv2Lock" 2>/dev/null || true