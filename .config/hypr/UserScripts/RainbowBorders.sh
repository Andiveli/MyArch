#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Rainbow borders for active window.
# We set a fixed multi-color gradient once, then manually animate the angle
# in a loop because the built-in borderangle animation (hl.animation) does not
# actually drive the gradient in this Lua config setup (angle stays frozen).

# Kill any previous rainbow driver to avoid duplicates (safer pattern)
for pid in $(pgrep -f "RainbowBorders.sh" 2>/dev/null | grep -v $$); do
    kill "$pid" 2>/dev/null || true
done
sleep 0.15

# Generate 8 random colors once (the "palette" for this run)
COLORS=()
for _ in {1..8}; do
	COLORS+=("\"0xff$(openssl rand -hex 3)\"")
done
color_list=$(IFS=,; printf '%s' "${COLORS[*]}")

# Helper: apply the same colors at a given angle
apply_angle() {
    local ang=$1
    hyprctl eval "hl.config({ general = { col = { active_border = { colors = { ${color_list} }, angle = ${ang} } } } })" >/dev/null 2>&1
}

# Initial set
apply_angle 270

# Also try to declare the animation (harmless if it does nothing)
hyprctl eval 'hl.animation({ leaf = "borderangle", enabled = true, speed = 100, bezier = "linear", style = "loop" })' >/dev/null 2>&1 || true

# Manual animation loop: increment angle so the gradient visibly rotates around the border.
# +1 degree every 40ms → ~25°/s (full cycle ~14s). Más relajado.
angle=270
while true; do
    angle=$(( (angle + 1) % 360 ))
    apply_angle $angle
    sleep 0.04
done & disown
