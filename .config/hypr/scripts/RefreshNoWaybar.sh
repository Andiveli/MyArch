#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Samael: wallust + Quickshell only (no waybar/swaync). Used by automatic wallpaper change.

SCRIPTSDIR=$HOME/.config/hypr/scripts
UserScripts=$HOME/.config/hypr/UserScripts
QS_CONFIG=ii

file_exists() {
  [ -e "$1" ]
}

if pidof rofi >/dev/null; then
  pkill rofi 2>/dev/null || true
fi

pkill -x waybar 2>/dev/null || true
pkill -x swaync 2>/dev/null || true

${SCRIPTSDIR}/WallustSwww.sh
sleep 0.3

pkill -x qs 2>/dev/null || true
sleep 0.2
qs -c "$QS_CONFIG" &

sleep 1
if file_exists "${UserScripts}/RainbowBorders.sh"; then
  ${UserScripts}/RainbowBorders.sh &
fi

exit 0