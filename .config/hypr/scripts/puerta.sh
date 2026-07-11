#!/usr/bin/env bash
set -eu

# Puerta: relay script that takes text from clipboard, sends to an agent, and plays TTS
# Configurable via environment variables:
# AGENT_CMD - command to call the agent (default: copilot)
# AGENT_ARGS - extra args for the agent command
# PIPER_MODEL - path to Piper model file

AGENT_CMD="${AGENT_CMD:-copilot}"
AGENT_ARGS="${AGENT_ARGS:-}"
PIPER_MODEL="${PIPER_MODEL:-$HOME/.local/share/piper/es_ES-glowingfish-medium.onnx}"

# Read clipboard (Wayland/X11 fallback)
if command -v wl-paste >/dev/null 2>&1; then
  PREGUNTA="$(wl-paste --no-newline || true)"
elif command -v xclip >/dev/null 2>&1; then
  PREGUNTA="$(xclip -selection clipboard -o || true)"
else
  echo "[puerta] No clipboard tool found (wl-paste/xclip)." >&2
  exit 2
fi

# Trim
PREGUNTA="$(printf '%s' "$PREGUNTA" | sed -e 's/^[[:space:]]*//;s/[[:space:]]*$//')"
[ -n "$PREGUNTA" ] || { echo "[puerta] Clipboard empty." >&2; exit 0; }

echo "[puerta] Pregunta: ${PREGUNTA}" >&2

RESP=""

# 1) Try agent command if present (user-configurable)
if command -v "$AGENT_CMD" >/dev/null 2>&1; then
  # If using the copilot CLI, call it explicitly and try to clean its output
  if [ "$AGENT_CMD" = "copilot" ]; then
    RESP="$(copilot chat --query "$PREGUNTA" 2>/dev/null || true)"
    # remove ANSI escapes and empty lines
    RESP="$(printf '%s' "$RESP" | sed 's/\x1b\[[0-9;]*m//g' | tr -d '\r' | awk 'NF{print}' | sed -n '1,1p')"
  else
    # Best-effort: try a few common CLI patterns
    if $AGENT_CMD --help 2>&1 | grep -qi "chat\|ask" >/dev/null 2>&1; then
      RESP="$($AGENT_CMD chat --query "$PREGUNTA" 2>/dev/null || true)"
    fi
    # fallback: pass as simple argument
    if [ -z "$RESP" ]; then
      RESP="$($AGENT_CMD $AGENT_ARGS "$PREGUNTA" 2>/dev/null || true)"
    fi
  fi
fi

# 2) Try HTTP local endpoint (ollama-like)
if [ -z "$RESP" ] && command -v curl >/dev/null 2>&1; then
  if curl -sS --fail http://localhost:11434/ >/dev/null 2>&1; then
    RESP="$(curl -sS -X POST 'http://localhost:11434/api/generate' -H 'Content-Type: application/json' -d "{\"model\":\"llama3\",\"prompt\":\"$PREGUNTA\",\"stream\":false}\"" | jq -r '.response' 2>/dev/null || true)"
  fi
fi

if [ -z "$RESP" ]; then
  echo "[puerta] No se obtuvo respuesta del agente. Configure AGENT_CMD o ejecute un agente local." >&2
  exit 3
fi

# Detect actionable commands in the agent response
CMD_TO_RUN=""
# If agent explicitly returns a RUN: command on a single line, use it
CMD_TO_RUN="$(printf '%s' "$RESP" | sed -n 's/^RUN:[[:space:]]*//Ip' | sed -n '1p' || true)"
# If nothing found, look for common verbs for Spotify
if [ -z "$CMD_TO_RUN" ]; then
  if printf '%s' "$RESP" | grep -qiE 'abrir spotify|open spotify|spotify:'; then
    CMD_TO_RUN='setsid spotify >/dev/null 2>&1 &'
  fi
fi

if [ -n "$CMD_TO_RUN" ]; then
  echo "[puerta] Ejecutando comando: $CMD_TO_RUN" >&2
  # run detached so it doesn't block; use sh -c to interpret the command string
  sh -c "$CMD_TO_RUN" >/dev/null 2>&1 &
fi

# 3) Play response via Piper, then fallbacks
if command -v piper >/dev/null 2>&1 && command -v pw-play >/dev/null 2>&1; then
  printf '%s' "$RESP" | piper --model "$PIPER_MODEL" --output_raw | pw-play --raw >/dev/null 2>&1 || true
  exit 0
fi

if command -v gtts-cli >/dev/null 2>&1 && command -v mpg123 >/dev/null 2>&1; then
  TMPMP3=$(mktemp --suffix=.mp3)
  printf '%s' "$RESP" | gtts-cli -l es - --nocheck -o "$TMPMP3" && mpg123 -q "$TMPMP3" || true
  rm -f "$TMPMP3"
  exit 0
fi

# Fallback: notify and echo
if command -v notify-send >/dev/null 2>&1; then
  notify-send "Puerta (respuesta)" "$RESP"
fi

echo "$RESP"
