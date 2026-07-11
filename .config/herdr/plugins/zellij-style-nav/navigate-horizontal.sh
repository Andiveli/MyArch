#!/usr/bin/env bash
# Zellij-style: pane left/right; at edge, previous/next tab.
# Tab hop uses a warm cache to avoid tab list on every keypress (plugin_action + CLI is slower than native keys).
set -euo pipefail

dir="${1:?usage: navigate-horizontal.sh left|right}"
herdr="${HERDR_BIN_PATH:-herdr}"

command -v jq >/dev/null 2>&1 || {
	echo "zellij-style-nav: jq required" >&2
	exit 1
}

case "$dir" in
left) focus_dir="left" ;;
right) focus_dir="right" ;;
*)
	echo "zellij-style-nav: unknown direction: $dir" >&2
	exit 2
	;;
esac

cache_dir="${XDG_RUNTIME_DIR:-/tmp}/herdr-zellij-style-nav"
mkdir -p "$cache_dir" 2>/dev/null || cache_dir="/tmp"

refresh_tab_cache() {
	local ws="$1"
	local out
	out="$("$herdr" tab list --workspace "$ws" 2>/dev/null)" || return 1
	printf '%s' "$out" >"${cache_dir}/tabs-${ws}.json"
}

read_next_tab_id() {
	local ws="$1" active="$2" direction="$3"
	local cache="${cache_dir}/tabs-${ws}.json"
	local tabs_json

	if [[ -f "$cache" ]]; then
		tabs_json="$(<"$cache")"
		if ! jq -e --arg t "$active" '.result.tabs[] | select(.tab_id == $t)' <<<"$tabs_json" >/dev/null 2>&1; then
			refresh_tab_cache "$ws" || return 1
			tabs_json="$(<"$cache")"
		fi
	else
		refresh_tab_cache "$ws" || return 1
		tabs_json="$(<"$cache")"
	fi

	jq -r --arg active "$active" --arg dir "$direction" '
    .result.tabs | map(.tab_id) as $ids |
    ($ids | index($active)) as $i |
    if $i == null then empty
    elif ($ids | length) < 2 then empty
    elif $dir == "left" then $ids[ (($i - 1 + ($ids | length)) % ($ids | length)) ]
    else $ids[ (($i + 1) % ($ids | length)) ]
    end
  ' <<<"$tabs_json"
}

focus_json="$("$herdr" pane focus --direction "$focus_dir" --current 2>/dev/null)" || exit 0

if jq -e '.result.focus.changed == true' <<<"$focus_json" >/dev/null 2>&1; then
	ws="$(jq -r '.result.focus.layout.workspace_id // empty' <<<"$focus_json")"
	[[ -n "$ws" ]] && refresh_tab_cache "$ws" >/dev/null 2>&1 &
	exit 0
fi

workspace_id="$(jq -r '.result.focus.layout.workspace_id // empty' <<<"$focus_json")"
active_tab="$(jq -r '.result.focus.layout.tab_id // empty' <<<"$focus_json")"
[[ -n "$workspace_id" && -n "$active_tab" ]] || exit 0

next_tab="$(read_next_tab_id "$workspace_id" "$active_tab" "$dir")"
[[ -n "$next_tab" && "$next_tab" != "$active_tab" ]] || exit 0

exec "$herdr" tab focus "$next_tab"
