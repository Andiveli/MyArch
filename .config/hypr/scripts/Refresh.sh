#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Samael refresh: wallust palette + restart Quickshell (samaelv2). Waybar is not used.

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

SCRIPTSDIR=$HOME/.config/hypr/scripts
QS_CONFIG=samaelv2

# Stop legacy bar/notification daemons and transient UI
_ps=(rofi swaync ags)
for _prs in "${_ps[@]}"; do
  if pidof "${_prs}" >/dev/null; then
    pkill "${_prs}" 2>/dev/null || true
  fi
done

wallpaper_current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
# wallust writes here by convention (~/.config/waybar kept for templates/CSS only)
wallust_css="$HOME/.config/waybar/wallust/colors-waybar.css"
old_mtime=$(stat -c %Y "$wallust_css" 2>/dev/null || echo 0)

if [ -f "$wallpaper_current" ]; then
  "${SCRIPTSDIR}/WallustSwww.sh" "$wallpaper_current"
else
  "${SCRIPTSDIR}/WallustSwww.sh"
fi

# Wait briefly for wallust CSS touch (max ~1.5s)
for i in {1..15}; do
  if [ -s "$wallust_css" ]; then
    cur_mtime=$(stat -c %Y "$wallust_css" 2>/dev/null || echo 0)
    if [ "$cur_mtime" -gt "$old_mtime" ]; then
      break
    fi
  fi
  sleep 0.1
done

if command -v qs >/dev/null; then
  qs -c "$QS_CONFIG" ipc call wallustColors reload 2>/dev/null || true
fi

pkill -x qs 2>/dev/null || true
sleep 0.15
qs -c "$QS_CONFIG" &

exit 0
