pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Service that provides disk usage information.
 */
Singleton {
    id: root

    property real diskTotal: 1
    property real diskUsed: 0
    property real diskFree: 0
    property real diskUsedPercentage: diskUsed / diskTotal
    property string diskRoot: "/"

    readonly property int historyLength: Config?.options.resources.historyLength ?? 60
    property list<real> diskUsageHistory: []

    function bytesToGbString(bytes) {
        return (bytes / (1024 * 1024 * 1024)).toFixed(1) + " GB";
    }

    function updateDiskUsageHistory() {
        diskUsageHistory = [...diskUsageHistory, diskUsedPercentage]
        if (diskUsageHistory.length > historyLength) {
            diskUsageHistory.shift()
        }
    }

    Process {
        id: initialDiskProc
        running: true
        command: ["bash", "-c", "df -B 1 / | tail -n 1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text.trim()
                const parts = text.split(/\s+/)
                if (parts.length >= 6) {
                    const total = parseInt(parts[1]) || 1
                    const used = parseInt(parts[2]) || 0
                    const free = parseInt(parts[3]) || 0
                    diskTotal = total
                    diskUsed = used
                    diskFree = free
                }
                root.updateDiskUsageHistory()
            }
        }
    }

    Timer {
        id: diskCheckTimer
        interval: Config.options?.resources?.updateInterval ?? 3000
        running: true
        repeat: true
        onTriggered: {
            diskCheckProc.running = true
        }
    }

    Process {
        id: diskCheckProc
        running: false
        command: ["bash", "-c", "df -B 1 / | tail -n 1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text.trim()
                const parts = text.split(/\s+/)
                if (parts.length >= 6) {
                    const total = parseInt(parts[1]) || 1
                    const used = parseInt(parts[2]) || 0
                    const free = parseInt(parts[3]) || 0
                    diskTotal = total
                    diskUsed = used
                    diskFree = free
                }
                root.updateDiskUsageHistory()
            }
        }
    }
}
