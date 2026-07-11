#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Samael refresh: wallust colors + Quickshell (samael). Waybar/swaync not used.

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

SCRIPTSDIR=$HOME/.config/hypr/scripts
UserScripts=$HOME/.config/hypr/UserScripts
QS_CONFIG=samael

file_exists() {
  [ -e "$1" ]
}

# Stop legacy bar/notification daemons and transient UI
_ps=(waybar rofi swaync ags)
for _prs in "${_ps[@]}"; do
  if pidof "${_prs}" >/dev/null; then
    pkill "${_prs}" 2>/dev/null || true
  fi
done

wallpaper_current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
waybar_colors="$HOME/.config/waybar/wallust/colors-waybar.css"
old_mtime=$(stat -c %Y "$waybar_colors" 2>/dev/null || echo 0)

if [ -f "$wallpaper_current" ]; then
  "${SCRIPTSDIR}/WallustSwww.sh" "$wallpaper_current"
else
  "${SCRIPTSDIR}/WallustSwww.sh"
fi

for i in {1..60}; do
  if [ -s "$waybar_colors" ]; then
    cur_mtime=$(stat -c %Y "$waybar_colors" 2>/dev/null || echo 0)
    if [ "$cur_mtime" -gt "$old_mtime" ]; then
      break
    fi
  fi
  sleep 0.1
done

sleep 0.5

if command -v qs >/dev/null; then
  qs -c "$QS_CONFIG" ipc call wallustColors reload 2>/dev/null || true
fi

pkill -x qs 2>/dev/null || true
sleep 0.2
qs -c "$QS_CONFIG" &

sleep 1
if file_exists "${UserScripts}/RainbowBorders.sh"; then
  ${UserScripts}/RainbowBorders.sh &
fi

exit 0