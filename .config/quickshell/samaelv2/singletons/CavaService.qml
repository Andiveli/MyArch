pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Cava — monitors the sink where playback actually is (follows moved sink-inputs).
 */
Item {
    id: root

    readonly property string liveConfigPath: Quickshell.shellPath("scripts/cava/samael_waybar.live.conf")
    readonly property bool wantProcess: ShellConfig.barEnabled && ShellConfig.hasWidget("right", "cava")

    property bool available: true
    property list<double> bars: []
    property string pulseSource: "auto"
    property string _appliedSource: ""

    onWantProcessChanged: {
        if (!wantProcess)
            bars = []
        else
            Qt.callLater(root.resolveAndMaybeRestart)
    }

    function resolveAndMaybeRestart() {
        resolveProc.running = true
    }

    function restartCavaIfNeeded() {
        if (!wantProcess)
            return
        if (pulseSource === _appliedSource && cavaProcess.running)
            return
        _appliedSource = pulseSource
        cavaProcess.running = false
        cavaProcess.running = true
    }

    Process {
        id: resolveProc
        command: [
            "python3",
            Quickshell.shellPath("scripts/cava-monitor-source.py"),
            root.liveConfigPath
        ]
        stdout: StdioCollector { id: resolveOut }
        onExited: (code) => {
            const line = String(resolveOut.text || "").trim().split("\n").pop()
            if (code === 0 && line.length)
                root.pulseSource = line
            else
                root.pulseSource = "auto"
            root.restartCavaIfNeeded()
        }
    }

    Process {
        id: cavaProcess
        command: ["cava", "-p", root.liveConfigPath]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const trimmed = data.trim()
                if (!trimmed.length)
                    return
                const parts = trimmed.split(";").filter(p => p.length > 0)
                const values = parts.map(p => Math.min(Math.max(parseFloat(p) / 7.0, 0), 1.0))
                root.bars = values
            }
        }
        onExited: root.available = false
    }

    Connections {
        target: AudioRouteService
        function onRevisionChanged() {
            if (root.wantProcess)
                root.resolveAndMaybeRestart()
        }
    }

    Component.onCompleted: {
        if (wantProcess)
            resolveAndMaybeRestart()
    }
}