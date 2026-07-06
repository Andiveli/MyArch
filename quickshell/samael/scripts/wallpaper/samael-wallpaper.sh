#!/usr/bin/env bash
# Samael: apply wallpaper without killing qs / waybar / swaync (JaKooLit Refresh.sh path).
set -euo pipefail

imgpath="${1:-}"
if [[ -z "$imgpath" || ! -f "$imgpath" ]]; then
	notify-send -a "Wallpaper" "Invalid image path"
	exit 1
fi

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

HOME="${HOME:-/home/samael}"
HYPR_SCRIPTS="$HOME/.config/hypr/scripts"
WALLPAPER_CURRENT="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
II_CONFIG="$HOME/.config/illogical-impulse/config.json"

FPS=60
TYPE="any"
DURATION=2
BEZIER=".43,1.19,1,.4"
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

focused_monitor="$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')"
if [[ -z "$focused_monitor" ]]; then
	notify-send -a "Wallpaper" "No focused monitor"
	exit 1
fi

pkill mpvpaper 2>/dev/null || true
pkill swaybg 2>/dev/null || true
pkill hyprpaper 2>/dev/null || true

if ! pgrep -x awww-daemon >/dev/null 2>&1; then
	awww-daemon --format xrgb &
	sleep 0.3
fi

awww img -o "$focused_monitor" "$imgpath" $SWWW_PARAMS

if [[ -f "$II_CONFIG" ]] && command -v jq >/dev/null; then
	jq --arg path "$imgpath" '.background.wallpaperPath = $path' "$II_CONFIG" >"$II_CONFIG.tmp" && mv "$II_CONFIG.tmp" "$II_CONFIG"
fi

mkdir -p "$(dirname "$WALLPAPER_CURRENT")"
cp -f "$imgpath" "$WALLPAPER_CURRENT" 2>/dev/null || true

waybar_colors="$HOME/.config/waybar/wallust/colors-waybar.css"
old_mtime=$(stat -c %Y "$waybar_colors" 2>/dev/null || echo 0)

"$HYPR_SCRIPTS/WallustSwww.sh" "$imgpath"

for _ in $(seq 1 40); do
	if [[ -s "$waybar_colors" ]]; then
		cur=$(stat -c %Y "$waybar_colors" 2>/dev/null || echo 0)
		if [[ "$cur" -gt "$old_mtime" ]]; then
			break
		fi
	fi
	sleep 0.1
done

if command -v qs >/dev/null; then
	qs -c samael ipc call wallustColors reload 2>/dev/null || true
fi
