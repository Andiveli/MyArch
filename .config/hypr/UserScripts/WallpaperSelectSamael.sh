#!/usr/bin/env bash
# Samael: JaKooLit-style rofi wallpaper grid — apply without Refresh.sh (no qs/waybar kill).
set -euo pipefail

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

wallDIR="$HOME/Pictures/wallpapers"
rofi_theme="$HOME/.config/rofi/config-wallpaper.rasi"
SAMAEL_APPLY="$HOME/.config/hypr/scripts/samael-wallpaper.sh"
iDIR="$HOME/.config/swaync/images"

focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')
if [[ -z "$focused_monitor" ]]; then
  notify-send -a "Wallpaper" "Could not detect focused monitor"
  exit 1
fi

scale_factor=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .scale')
monitor_height=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .height')
icon_size=$(echo "scale=1; ($monitor_height * 3) / ($scale_factor * 150)" | bc)
adjusted_icon_size=$(echo "$icon_size" | awk '{if ($1 < 15) $1 = 20; if ($1 > 25) $1 = 25; print $1}')
rofi_override="element-icon{size:${adjusted_icon_size}%;}"

if ! command -v bc &>/dev/null; then
  notify-send -a "Wallpaper" "Install package: bc"
  exit 1
fi

mapfile -d '' PICS < <(find -L "${wallDIR}" -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o \
  -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.webp" \) -print0)

if [[ ${#PICS[@]} -eq 0 ]]; then
  notify-send -a "Wallpaper" "No images in ${wallDIR}"
  exit 1
fi

RANDOM_PIC="${PICS[$((RANDOM % ${#PICS[@]}))]}"
RANDOM_PIC_NAME=". random"

menu() {
  IFS=$'\n' sorted_options=($(sort <<<"${PICS[*]}"))
  printf "%s\x00icon\x1f%s\n" "$RANDOM_PIC_NAME" "$RANDOM_PIC"
  for pic_path in "${sorted_options[@]}"; do
    pic_name=$(basename "$pic_path")
    if [[ "$pic_name" =~ \.gif$ ]]; then
      cache_gif_image="$HOME/.cache/gif_preview/${pic_name}.png"
      if [[ ! -f "$cache_gif_image" ]]; then
        mkdir -p "$HOME/.cache/gif_preview"
        magick "$pic_path[0]" -resize 1920x1080 "$cache_gif_image"
      fi
      printf "%s\x00icon\x1f%s\n" "$pic_name" "$cache_gif_image"
    else
      printf "%s\x00icon\x1f%s\n" "$pic_name" "$pic_path"
    fi
  done
}

choice=$(menu | rofi -i -dmenu -config "$rofi_theme" -theme-str "$rofi_override")
choice=$(echo "$choice" | xargs)
RANDOM_PIC_NAME=$(echo "$RANDOM_PIC_NAME" | xargs)

[[ -z "$choice" ]] && exit 0

if [[ "$choice" == "$RANDOM_PIC_NAME" ]]; then
  "$SAMAEL_APPLY" "$RANDOM_PIC"
  exit 0
fi

choice_basename=$(basename "$choice" | sed 's/\(.*\)\.[^.]*$/\1/')
selected_file=$(find "$wallDIR" -iname "$choice_basename.*" -print -quit)

if [[ -z "$selected_file" || ! -f "$selected_file" ]]; then
  notify-send -a "Wallpaper" "File not found: $choice"
  exit 1
fi

"$SAMAEL_APPLY" "$selected_file"