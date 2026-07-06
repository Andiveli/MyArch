# Notlight launcher (Samael)

Integrated from [pratik2005ko/notlight](https://github.com/pratik2005ko/notlight). See `UPSTREAM.txt` for pinned commit.

- **Toggle:** `qs -c samael ipc call spotlight toggle` (Hypr: Super release → `samael:launcher`)
- **Data:** `~/.config/quickshell/spotlight-data/` (secrets, aliases, captures, commands, theme)
- **YouTube binary:** `modules/launcher/bin/yt-search` — build with:

```bash
g++ -std=c++17 -O2 -s modules/launcher/yt-search.cpp -o modules/launcher/bin/yt-search -lcurl
```

Headers: vendored `modules/launcher/nlohmann/json.hpp` (or system `nlohmann-json`).

Caelestia drawer launcher is disabled (`config/shell.json` + stub in `modules/drawers/Panels.qml`).

Terminal invocations use **ghostty** (apps with `Terminal=true`, shell commands, `yazi` on directories).
