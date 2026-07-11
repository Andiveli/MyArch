pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Local wallpaper list (newest first) + current wallpaper path for picker focus.
 *
 * Performance:
 *   - Refresh is idempotent: only re-scans if entries is empty.
 *   - Thumbnails generated once via ImageMagick to ~/.cache/samaelv2/wallpapers/.
 *   - thumbsReady flag switches Image source from full path → thumb after batch.
 *   - Lightweight mtime check at open detects new files without full re-scan.
 */
Singleton {
    id: root

    property var entries: []
    readonly property int count: entries.length
    property string current: ""

    readonly property string thumbDir: Quickshell.env("HOME") + "/.cache/samaelv2/wallpapers"
    /** true once thumbnail batch has finished successfully this session. */
    property bool thumbsReady: false
    property int _lastDirMtime: 0

    readonly property string wpDir: ShellConfig.wallpaperDir
    readonly property string applyScript: Quickshell.env("HOME") + "/.config/hypr/scripts/samael-wallpaper.sh"
    readonly property string iiConfig: Quickshell.env("HOME") + "/.config/illogical-impulse/config.json"
    readonly property string wpCurrentFile: Quickshell.env("HOME") + "/.config/hypr/wallpaper_effects/.wallpaper_current"

    /** Idempotent — only re-scans when entries are empty. Call forceRefresh() for explicit re-scan. */
    function refresh() {
        if (root.entries.length > 0)
            return
        listProc.running = true
    }

    /** Quick mtime check — if dir changed since last load, force a full re-scan. */
    function checkForChanges() {
        if (root.entries.length === 0) {
            listProc.running = true
            return
        }
        mtimeCheckProc.running = true
    }

    /** Force re-scan directory + regenerate thumbs. */
    function forceRefresh() {
        root.thumbsReady = false
        root.entries = []
        listProc.running = true
    }

    function apply(path) {
        if (!path || !path.length)
            return
        root.current = path
        applyProc.command = ["bash", applyScript, path]
        applyProc.running = true
    }

    function filtered(query) {
        const q = (query || "").trim().toLowerCase()
        if (!q.length)
            return entries
        const out = []
        for (let i = 0; i < entries.length; i++) {
            const e = entries[i]
            if (e.name.toLowerCase().includes(q))
                out.push(e)
        }
        return out
    }

    function pathsEqual(a, b) {
        if (!a || !b)
            return false
        if (a === b)
            return true
        const na = a.substring(a.lastIndexOf("/") + 1)
        const nb = b.substring(b.lastIndexOf("/") + 1)
        return na.length > 0 && na === nb
    }

    /** Index of active wallpaper in a list (entries or filtered). */
    function indexInList(list) {
        if (!list || !list.length)
            return 0
        const cur = root.current
        for (let i = 0; i < list.length; i++) {
            if (pathsEqual(list[i].path, cur))
                return i
        }
        return 0
    }

    /** Kick off background thumbnail generation for all entries. */
    function startThumbBatch() {
        const files = root.entries.map(e => e.path)
        if (files.length === 0) {
            root.thumbsReady = true
            return
        }
        const script = 'd="$1"; shift; mkdir -p "$d"; ' +
            'for f; do ' +
            '  [ -f "$f" ] || continue; ' +
            '  t="$d/$(basename "$f")"; ' +
            '  [ "$t" -nt "$f" ] 2>/dev/null && continue; ' +
            '  magick "$f" -thumbnail "400x400>" -strip "$t" 2>/dev/null; ' +
            'done'
        const args = ["bash", "-c", script, "_", root.thumbDir].concat(files)
        thumbBatchProc.command = args
        thumbBatchProc.running = true
    }

    Process {
        id: listProc
        command: ["bash", "-c",
            "find -L \"$1\" -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.bmp' \\) -printf '%T@\\t%p\\n' 2>/dev/null | sort -rn | cut -f2-",
            "_", root.wpDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n")
                const out = []
                for (let i = 0; i < lines.length; i++) {
                    const path = lines[i].trim()
                    if (!path.length)
                        continue
                    const name = path.substring(path.lastIndexOf("/") + 1)
                    out.push({ path: path, name: name, thumb: root.thumbDir + "/" + name })
                }
                root.entries = out
                currentProc.running = true
                root.startThumbBatch()
            }
        }
    }

    Process {
        id: currentProc
        command: ["bash", "-c",
            "p=$(jq -r '.background.wallpaperPath // empty' \"$1\" 2>/dev/null); " +
            "if [[ -z \"$p\" || ! -f \"$p\" ]]; then p=$(cat \"$2\" 2>/dev/null); fi; " +
            "echo -n \"$p\"",
            "_", root.iiConfig, root.wpCurrentFile]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim()
                if (p.length)
                    root.current = p
            }
        }
    }

    Process {
        id: thumbBatchProc
        onExited: exitCode => {
            if (exitCode === 0)
                root.thumbsReady = true
        }
    }

    /** Lightweight directory mtime check — run at picker open to detect new wallpapers. */
    Process {
        id: mtimeCheckProc
        command: ["stat", "--format=%Y", root.wpDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = parseInt(text.trim(), 10)
                if (!isNaN(m) && m > root._lastDirMtime) {
                    root._lastDirMtime = m
                    root.forceRefresh()
                }
            }
        }
    }

    Process {
        id: applyProc
        onExited: Qt.callLater(() => WallustColors.reloadPaletteFromDisk())
    }

    Component.onCompleted: refresh()
}
