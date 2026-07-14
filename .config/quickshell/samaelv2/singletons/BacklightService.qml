pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/** Backlight % — brightnessctl on demand; Hypr passes % after change for instant OSD. */
Singleton {
    id: root

    property bool present: false
    property real brightness: 0
    property int lastPct: -1

    signal changed()

    function setPercent(pct) {
        const n = parseInt(pct, 10)
        if (isNaN(n))
            return
        const clamped = Math.max(0, Math.min(100, n))
        root.present = true
        root.brightness = clamped / 100.0
        root.lastPct = clamped
    }

    function poll() {
        brightProc.exec()
    }

    Process {
        id: brightProc
        command: ["brightnessctl", "-m"]
        function exec() {
            running = false
            running = true
        }
        stdout: StdioCollector {
            onStreamFinished: {
                const line = String(text).trim()
                if (!line.length)
                    return
                const parts = line.split(",")
                if (parts.length < 4)
                    return
                const pct = parseInt(String(parts[3]).replace("%", "").trim(), 10)
                if (isNaN(pct))
                    return
                root.present = true
                root.brightness = Math.max(0, Math.min(100, pct)) / 100.0
                root.lastPct = pct
            }
        }
    }

    Component.onCompleted: poll()
}