# Screen record (samaelv2)

No `caelestia` CLI. Backend: `scripts/record-ctl.py` + **`gpu-screen-recorder`** (install from AUR/repos).

## Config (`config.json` → `record`)

**Settings → Videos** (middle pill Settings, **j/k** to *Videos*, **s** save): save folder + default mic/system audio flags.

- `saveDir` — output folder (default `~/Videos`)
- `includeSystemAudio` / `includeMic` — passed to recorder `-a` flags
- `mode` — `monitor` | `region` | `window`
- `monitor` — Hypr output name when mode is monitor
- `windowAddress` — Hypr client address when mode is window

## UI

- **Left pill** — icon in `bar.left` (`record` widget) opens `RecordSurface`
- **Super+Ctrl+R** — Hypr → `quickshell:samaelRecordMenuToggle` (open/close left record surface)
- Inside surface: **vim** `j/k` move focus, `l`/`Enter` activate, `Esc` back/close
- **Pause** — only while recording (gpu-screen-recorder USR2)
- **Region** (icon next to pause) — **not** while recording: closes the pill, runs **slurp** to draw a rectangle, then records that area (`slurp` package required)

## Hypr (required)

Replace old `regionRecord` bind with:

```lua
hl.bind("SUPER + CTRL + R", hl.dsp.global("quickshell:samaelRecordMenuToggle"), { description = "Screen record (samaelv2 left)" })
```

## Keys (surface focused, keyboard-first)

`h` / `l` — controls row: move · mic/system row: capture volume ±5% · `j` / `k` — change row · `Space` — mute on/off on mic or system row · `Enter` — activate · `Esc` — exit config then close