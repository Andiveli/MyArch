pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real cpuTemperature: 0

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: tempCheck.running = true
    }

    Process {
        id: tempCheck
        running: false
        command: ["bash", "-c", "cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text.trim()
                if (text.length > 0) {
                    const temp = parseInt(text)
                    if (!isNaN(temp)) root.cpuTemperature = temp
                }
            }
        }
    }
}
