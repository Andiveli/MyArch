# Lyrics (samaelv2)

All UI and wiring live under `samaelv2/`. The **sync engine** is the system Qt plugin from the AUR package `caelestia-shell` (`Caelestia.Services.Lyrics`). No Caelestia dotfiles or vendor tree in this repo.

## Install (Arch)

```sh
yay -S caelestia-shell
```

Plugin path: `/usr/lib/qt6/qml/Caelestia/Services/libcaelestia-servicesplugin.so`

## Configure (`config.json`)

```json
"lyrics": {
  "dir": "~/Music/Lyrics",
  "backend": "Auto",
  "panelWidth": 220
}
```

- **dir**: folder for `Artist - Title.lrc` (empty = Caelestia default `~/Music/Lyrics`)
- **backend**: `Auto` | `Local` | `LRCLIB` | `NetEase`
- **panelWidth**: lyrics column width when open

`LyricsBridge` pushes `dir` / `backend` into `GlobalConfig` at runtime so you do not need Caelestia’s JSON config.

## Keys (media surface)

- **y** or **Shift+L** — toggle lyrics column
- **j** / **k** — scroll lyric lines when column open; otherwise seek ±10s
- **l** / **h** — next / previous track

## Files

| File | Role |
| ------ | ------ |
| `singletons/LyricsBridge.qml` | MPRIS → `Lyrics.setTrack`, config paths |
| `surfaces/MediaLyricsPanel.qml` | List + sync (Wallust) |
| `surfaces/MediaLyricsStub.qml` | Message if plugin missing |

If `MediaLyricsPanel` fails to load, the stub is shown automatically.
