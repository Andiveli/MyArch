#!/usr/bin/env bash
# Samael lock sidebar label script (moved out of quickshell/caelestia).
# Terminal use: same info vibe as the lock fetch card.
set -euo pipefail
CONFIG="${SAMAEL_FETCH_CONFIG:-$HOME/.config/fastfetch/config-pokemon.jsonc}"
if [[ -f "$CONFIG" ]]; then
	exec fastfetch -c "$CONFIG" "$@"
fi
exec fastfetch "$@"
