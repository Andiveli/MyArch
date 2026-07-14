pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/** Sink level via wpctl — on demand; Hypr scripts can push level instantly via IPC. */
Singleton {
    id: root

    property real volume: 0
    property bool muted: false
    property int lastPct: -1

    signal levelChanged()

    function setFromHypr(pct, isMuted) {
        const p = Math.max(0, Math.min(150, parseInt(pct, 10)))
        if (isNaN(p))
            return
        root.muted = !!isMuted
        root.volume = root.muted ? 0 : Math.min(1, p / 100.0)
        root.lastPct = root.muted ? 0 : p
    }

    function poll() {
        wpctlProc.exec()
    }

    Process {
        id: wpctlProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        function exec() {
            running = false
            running = true
        }
        stdout: StdioCollector {
            onStreamFinished: {
                const d = String(text).trim()
                if (!d.length)
                    return
                const m = d.match(/[0-9.]+/)
                if (!m)
                    return
                const f = parseFloat(m[0])
                if (isNaN(f))
                    return
                const pct = Math.round(f * 100)
                const wasMuted = root.muted
                root.muted = d.indexOf("[MUTED]") >= 0
                root.volume = Math.max(0, Math.min(1, f))
                if (root.lastPct < 0 || pct !== root.lastPct || wasMuted !== root.muted)
                    root.levelChanged()
                root.lastPct = pct
            }
        }
    }

    Component.onCompleted: poll()
}