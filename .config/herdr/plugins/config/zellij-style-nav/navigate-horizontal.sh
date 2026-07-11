#!/usr/bin/env bash
# Pane focus left/right; at layout edge, previous/next tab in the active workspace.
set -euo pipefail

dir="${1:?usage: navigate-horizontal.sh left|right}"
herdr="${HERDR_BIN_PATH:-herdr}"

command -v jq >/dev/null 2>&1 || {
  echo "zellij-style-nav: jq required" >&2
  exit 1
}

case "$dir" in
  left)  focus_dir="left" ;;
  right) focus_dir="right" ;;
  *) echo "zellij-style-nav: unknown direction: $dir" >&2; exit 2 ;;
esac

current_json="$("$herdr" pane current --current 2>/dev/null)" || exit 0
current_pane="$(jq -r '.result.pane.pane_id // empty' <<<"$current_json")"
workspace_id="$(jq -r '.result.pane.workspace_id // empty' <<<"$current_json")"
active_tab="$(jq -r '.result.pane.tab_id // empty' <<<"$current_json")"

[[ -n "$current_pane" && -n "$workspace_id" && -n "$active_tab" ]] || exit 0

neighbor_json="$("$herdr" pane neighbor --direction "$focus_dir" --current 2>/dev/null)" || true
neighbor_pane="$(jq -r '.result.neighbor.pane_id // empty' <<<"$neighbor_json")"

if [[ -n "$neighbor_pane" && "$neighbor_pane" != "$current_pane" ]]; then
  exec "$herdr" pane focus --direction "$focus_dir" --current
fi

tabs_json="$("$herdr" tab list --workspace "$workspace_id" 2>/dev/null)" || exit 0
mapfile -t tab_ids < <(jq -r '.result.tabs[].tab_id' <<<"$tabs_json")
n="${#tab_ids[@]}"
(( n > 0 )) || exit 0

idx=-1
for i in "${!tab_ids[@]}"; do
  if [[ "${tab_ids[$i]}" == "$active_tab" ]]; then
    idx=$i
    break
  fi
done
(( idx >= 0 )) || exit 0

if [[ "$dir" == left ]]; then
  new_idx=$(( (idx - 1 + n) % n ))
else
  new_idx=$(( (idx + 1) % n ))
fi

[[ "${tab_ids[$new_idx]}" != "$active_tab" ]] || exit 0
exec "$herdr" tab focus "${tab_ids[$new_idx]}"
