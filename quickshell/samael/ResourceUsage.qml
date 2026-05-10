pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real cpuUsage: 0
    property real memoryTotal: 1
    property real memoryUsed: 0
    property real memoryUsedPercentage: memoryUsed / memoryTotal
    property real memoryUsedGb: 0

    // CPU - método igual que btop (promedio de todos los cores)
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: cpuCheck.running = true
    }

    Process {
        id: cpuCheck
        running: false
        command: ["bash", "-c", "\
cpu=$(cat /proc/stat | grep '^cpu ' | head -1); \
user=$(echo $cpu | awk '{print $2}'); \
nice=$(echo $cpu | awk '{print $3}'); \
system=$(echo $cpu | awk '{print $4}'); \
idle=$(echo $cpu | awk '{print $5}'); \
iowait=$(echo $cpu | awk '{print $6}'); \
irq=$(echo $cpu | awk '{print $7}'); \
softirq=$(echo $cpu | awk '{print $8}'); \
total=$((user + nice + system + idle + iowait + irq + softirq)); \
idle_total=$((idle + iowait)); \
echo \"$total $idle_total\""]
        property string prevLine: ""
        stdout: StdioCollector {
            onStreamFinished: {
                const line = this.text.trim()
                if (cpuCheck.prevLine === "") {
                    cpuCheck.prevLine = line
                    return
                }
                const prev = cpuCheck.prevLine.split(" ")
                const curr = line.split(" ")
                if (prev.length >= 2 && curr.length >= 2) {
                    const prevTotal = parseInt(prev[0])
                    const prevIdle = parseInt(prev[1])
                    const currTotal = parseInt(curr[0])
                    const currIdle = parseInt(curr[1])
                    const totalDiff = currTotal - prevTotal
                    const idleDiff = currIdle - prevIdle
                    if (totalDiff > 0) {
                        root.cpuUsage = (totalDiff - idleDiff) / totalDiff
                    }
                }
                cpuCheck.prevLine = line
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: memCheck.running = true
    }

    Process {
        id: memCheck
        running: false
        command: ["bash", "-c", "cat /proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text
                const total = parseInt(text.match(/MemTotal: *(\d+)/)?.[1] || 1)
                const used = parseInt(text.match(/MemTotal: *(\d+)/)?.[1] || 1) - parseInt(text.match(/MemAvailable: *(\d+)/)?.[1] || 0)
                root.memoryTotal = total
                root.memoryUsed = used
                root.memoryUsedGb = used / (1024 * 1024)
            }
        }
    }
}
