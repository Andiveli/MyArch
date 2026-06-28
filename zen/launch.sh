#!/usr/bin/env bash
#
# Self-contained Zen launcher (everything lives in this dir).
# - Forces the tuned flags (EGL, Wayland, canvas accel, etc.)
# - Applies the Hyprland rules needed for smooth frame pacing (no blur + immediate)
#   so you don't have to touch your main hypr config for Zen-specific tweaks.
#
# Wired into:
# - ~/.config/hypr/hyprland/variables.lua (browser var)
# - ~/.config/hypr/hyprland/keybinds.lua (SUPER+Z)
# ~/.local/bin/zen-browser wrapper also forwards here.

set -euo pipefail

ZEN_BIN="/opt/zen-browser-bin/zen-bin"
FLAGS_FILE="$(dirname "$0")/flags.conf"

if [[ ! -x "$ZEN_BIN" ]]; then
	echo "zen-bin not found at $ZEN_BIN" >&2
	exec zen-browser "$@"
fi

# Apply Zen-specific compositor rules at launch (self-contained)
if command -v hyprctl >/dev/null 2>&1; then
	# no_blur removes expensive compositor passes that can cause stuttering
	hyprctl keyword "windowrulev2 no_blur,class:^(zen|zen-alpha|zen-browser)$" >/dev/null 2>&1 || true
	# immediate + compositor NO forzado = frame pacing directo sin latencia de Hyprland.
	# Antes rompía scroll porque el WebRender Compositor forzado + immediate conflictuaban.
	# Ahora que el compositor está desactivado, immediate va fino.
	hyprctl keyword "windowrulev2 immediate,class:^(zen|zen-alpha|zen-browser)$" >/dev/null 2>&1 || true
fi

# Read flags
FLAGS=$(grep -v '^\s*#' "$FLAGS_FILE" 2>/dev/null | grep -v '^\s*$' | tr '\n' ' ' || true)

# Wayland + perf env
export MOZ_ENABLE_WAYLAND=1
export GDK_BACKEND=wayland

exec "$ZEN_BIN" $FLAGS "$@"
