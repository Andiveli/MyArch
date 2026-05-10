pragma Singleton
pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property real cpuTemperature: 0
    property string temperatureStatus: "normal"

    Process {
        running: true
        command: ["bash", "-c", "cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text.trim()
                if (text.length > 0) {
                    const temp = parseInt(text)
                    if (!isNaN(temp)) {
                        root.cpuTemperature = temp
                        if (temp >= 90000) root.temperatureStatus = "critical"
                        else if (temp >= 75000) root.temperatureStatus = "hot"
                        else if (temp >= 55000) root.temperatureStatus = "warm"
                        else root.temperatureStatus = "normal"
                    }
                }
            }
        }
    }
}
