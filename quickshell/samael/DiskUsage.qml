pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real diskTotal: 1
    property real diskUsed: 0
    property real diskAvailable: 0
    property real diskUsedPercentage: diskUsed / diskTotal

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: diskCheck.running = true
    }

    Process {
        id: diskCheck
        running: false
        command: ["bash", "-c", "df -B 1 / | tail -n 1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text.trim()
                const parts = text.split(/\s+/)
                if (parts.length >= 6) {
                    const total = parseInt(parts[1]) || 1
                    const used = parseInt(parts[2]) || 0
                    const available = parseInt(parts[3]) || 0
                    root.diskTotal = total
                    root.diskUsed = used
                    root.diskAvailable = available
                }
            }
        }
    }

    Component.onCompleted: diskCheck.running = true
}
