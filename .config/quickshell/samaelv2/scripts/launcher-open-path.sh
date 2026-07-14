#!/usr/bin/env bash
# Open paths with sensible apps (code editor, image viewer, file manager), not browser defaults.
set -euo pipefail

p="${1:-}"
if [[ -z "$p" ]]; then
  exit 1
fi
if [[ "$p" == ~* ]]; then
  p="${HOME}${p:1}"
fi
if [[ ! -e "$p" ]]; then
  exit 2
fi

# --- helpers ---
try_exec() {
  local bin="$1"
  shift
  if command -v "$bin" >/dev/null 2>&1; then
    exec "$bin" "$@"
  fi
}

mime="$(file -b --mime-type "$p" 2>/dev/null || true)"
base="$(basename "$p")"
ext="${base##*.}"
ext_lc="$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')"

CODE_EXTS=(
  qml js ts jsx tsx py sh bash zsh fish rs go java kt c cc cpp h hpp cs php rb lua
  vue svelte css scss html htm xml yaml yml toml ini conf md mdx sql prisma dockerfile
  env gitignore desktop service
)

is_code_ext() {
  local e="$1"
  local x
  for x in "${CODE_EXTS[@]}"; do
    [[ "$e" == "$x" ]] && return 0
  done
  return 1
}

open_in_terminal() {
  local editor="$1"
  local target="$2"
  try_exec kitty "$editor" "$target"
  try_exec alacritty -e "$editor" "$target"
  try_exec foot "$editor" "$target"
  try_exec wezterm start -- "$editor" "$target"
  try_exec ghostty -e "$editor" "$target"
  try_exec konsole -e "$editor" "$target"
  try_exec gnome-terminal -- "$editor" "$target"
  return 1
}

open_code() {
  local target="$1"
  local ed="${EDITOR:-vim}"
  # Respect EDITOR when it is vim/nvim (your shell default).
  if [[ "$ed" == *vim* ]] && command -v "${ed%% *}" >/dev/null 2>&1; then
    open_in_terminal "$ed" "$target" && exit 0
  fi
  if command -v vim >/dev/null 2>&1; then
    open_in_terminal vim "$target" && exit 0
  fi
  if command -v nvim >/dev/null 2>&1; then
    open_in_terminal nvim "$target" && exit 0
  fi
  return 1
}

open_image() {
  local target="$1"
  try_exec loupe "$target"
  try_exec eog "$target"
  try_exec feh "$target"
  try_exec imv "$target"
  try_exec gwenview "$target"
  try_exec sxiv "$target"
  return 1
}

open_dir() {
  local target="$1"
  try_exec thunar "$target"
  try_exec nautilus "$target"
  try_exec dolphin "$target"
  try_exec pcmanfm-qt "$target"
  try_exec nemo "$target"
  try_exec ranger "$target"
  return 1
}

browser_default_for_mime() {
  local m="$1"
  local def
  def="$(xdg-mime query default "$m" 2>/dev/null || true)"
  [[ "$def" =~ [Ee]dge|[Cc]hrome|[Ff]irefox|[Zz]en|[Bb]rave|[Oo]pera|[Vv]ivaldi ]] && return 0
  return 1
}

# --- routing ---
if [[ -d "$p" ]]; then
  open_dir "$p" || exit 3
fi

if [[ "$mime" == image/* ]] || [[ "$ext_lc" =~ ^(png|jpe?g|gif|webp|bmp|svg|avif|ico|tiff?)$ ]]; then
  if open_image "$p"; then
    exit 0
  fi
  echo "launcher-open-path: no image viewer (install loupe, eog, or feh)" >&2
  exit 4
fi

if is_code_ext "$ext_lc" || [[ "$mime" == application/json ]] || [[ "$mime" == text/x-* ]]; then
  open_code "$p" && exit 0
fi

if [[ "$mime" == text/plain ]] && [[ "$base" == *.* ]]; then
  open_code "$p" && exit 0
fi

# Last resort: xdg-open (skip when MIME default is a browser for non-URL files)
if browser_default_for_mime "$mime"; then
  open_code "$p" && exit 0
  echo "launcher-open-path: default app is a browser; set a MIME handler or install vim/feh" >&2
  exit 5
fi

if command -v xdg-open >/dev/null 2>&1; then
  exec xdg-open "$p"
fi
if command -v gio >/dev/null 2>&1; then
  exec gio open "$p"
fi
if command -v handlr >/dev/null 2>&1; then
  exec handlr open "$p"
fi
exit 3