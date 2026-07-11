pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/** Sink level via wpctl (matches Volume.sh / pamixer on Pipewire). */
Singleton {
    id: root

    property real volume: 0
    property bool muted: false
    property int lastPct: -1

    signal levelChanged()

    Process {
        command: ["sh", "-c", "while true; do wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || echo '0.0'; sleep 0.25; done"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                const d = line.trim()
                root.muted = d.indexOf("[MUTED]") >= 0
                const m = d.match(/[0-9.]+/)
                if (!m)
                    return
                const f = parseFloat(m[0])
                if (isNaN(f))
                    return
                const pct = Math.round(f * 100)
                const prev = root.lastPct
                root.volume = Math.max(0, Math.min(1, f))
                if (prev >= 0 && pct !== prev)
                    root.levelChanged()
                root.lastPct = pct
            }
        }
    }
}