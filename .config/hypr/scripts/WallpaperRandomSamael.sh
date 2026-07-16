#!/usr/bin/env bash
set -euo pipefail
export LANG=en_US.UTF-8

wallDIR="$HOME/Pictures/wallpapers"
SAMAEL_APPLY="$HOME/.config/hypr/scripts/samael-wallpaper.sh"

mapfile -t PICS < <(find -L "$wallDIR" -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.bmp" \) )

[[ ${#PICS[@]} -eq 0 ]] && exit 0
"$SAMAEL_APPLY" "${PICS[$RANDOM % ${#PICS[@]}]}"