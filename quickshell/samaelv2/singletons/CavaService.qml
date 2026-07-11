pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    readonly property string configPath: Quickshell.shellPath("scripts/cava/samael_waybar.conf")
    readonly property bool wantProcess: ShellConfig.barEnabled && ShellConfig.hasWidget("right", "cava")

    property bool available: true
    property list<double> bars: []

    onWantProcessChanged: {
        if (!wantProcess)
            bars = []
    }

    Process {
        id: cavaProcess
        command: ["cava", "-p", root.configPath]
        running: root.wantProcess
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
}