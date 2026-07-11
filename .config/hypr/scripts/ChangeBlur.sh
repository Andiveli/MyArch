#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for changing blurs on the fly

notif="$HOME/.config/swaync/images"

GENERAL_LUA="$HOME/.config/hypr/hyprland/general.lua"
STATE=$(hyprctl -j getoption decoration:blur:enabled | jq ".bool")

if [ "${STATE}" == "true" ]; then
	# only modify enabled within the blur block
	sed -i '/^\s*blur = {/,/^\s*},$/s/enabled = true/enabled = false/' "$GENERAL_LUA"
	notify-send -e -u low -i "$notif/note.png" " Blur Off"
else
	sed -i '/^\s*blur = {/,/^\s*},$/{
		s/enabled = false/enabled = true/
		s/size = [0-9][0-9]*/size = 5/
		s/passes = [0-9][0-9]*/passes = 2/
	}' "$GENERAL_LUA"
	notify-send -e -u low -i "$notif/ja.png" " Blur On"
fi

hyprctl reload
