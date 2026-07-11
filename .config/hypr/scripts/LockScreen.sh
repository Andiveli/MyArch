#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##

# Samael / Quickshell session lock (LockScreen → SamaelLock)
bash "$HOME/.config/hypr/UserScripts/WeatherWrap.sh" >/dev/null 2>&1

# IPC is reliable; hypr global is fallback if QS registered the shortcut with Hyprland
if ! qs -c samael ipc call lock lock 2>/dev/null; then
  hyprctl dispatch global samael:lock
fi

