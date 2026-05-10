pragma Singleton
pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Simple polled resource usage service with RAM, Swap, and CPU usage.
 */
Singleton {
    id: root
    property real memoryTotal: 1
    property real memoryFree: 0
    property real memoryUsed: memoryTotal - memoryFree
    property real memoryUsedPercentage: memoryUsed / memoryTotal
    property real swapTotal: 1
    property real swapFree: 0
    property real swapUsed: swapTotal - swapFree
    property real swapUsedPercentage: swapTotal > 0 ? (swapUsed / swapTotal) : 0
    property real cpuUsage: 0

    property string maxAvailableMemoryString: kbToGbString(memoryTotal)
    property string maxAvailableSwapString: kbToGbString(swapTotal)
    property string maxAvailableCpuString: "--"

    readonly property int historyLength: Config?.options.resources.historyLength ?? 60
    property list<real> cpuUsageHistory: []
    property list<real> memoryUsageHistory: []
    property list<real> swapUsageHistory: []

    function kbToGbString(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }

    function updateMemoryUsageHistory() {
        memoryUsageHistory = [...memoryUsageHistory, memoryUsedPercentage]
        if (memoryUsageHistory.length > historyLength) {
            memoryUsageHistory.shift()
        }
    }
    function updateSwapUsageHistory() {
        swapUsageHistory = [...swapUsageHistory, swapUsedPercentage]
        if (swapUsageHistory.length > historyLength) {
            swapUsageHistory.shift()
        }
    }
    function updateCpuUsageHistory() {
        cpuUsageHistory = [...cpuUsageHistory, cpuUsage]
        if (cpuUsageHistory.length > historyLength) {
            cpuUsageHistory.shift()
        }
    }

    // Memory timer - cada 3 segundos
    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            fileMeminfo.reload()
            const textMeminfo = fileMeminfo.text()
            memoryTotal = Number(textMeminfo.match(/MemTotal: *(\d+)/)?.[1] ?? 1)
            memoryFree = Number(textMeminfo.match(/MemAvailable: *(\d+)/)?.[1] ?? 0)
            swapTotal = Number(textMeminfo.match(/SwapTotal: *(\d+)/)?.[1] ?? 1)
            swapFree = Number(textMeminfo.match(/SwapFree: *(\d+)/)?.[1] ?? 0)
            updateMemoryUsageHistory()
            updateSwapUsageHistory()
        }
    }

    // CPU timer - cada 2 segundos con sleep incluido
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            cpuCheckProc.running = true
        }
    }

    Process {
        id: cpuCheckProc
        running: false
        command: ["bash", "-c", "\
read prev < /proc/stat; \
sleep 1; \
read curr < /proc/stat; \
prev_idle=$(echo \"$prev\" | awk '{print $5}'); \
curr_idle=$(echo \"$curr\" | awk '{print $5}'); \
prev_total=$(echo \"$prev\" | awk '{print $2+$3+$4+$5+$6+$7}'); \
curr_total=$(echo \"$curr\" | awk '{print $2+$3+$4+$5+$6+$7}'); \
idle_diff=$((curr_idle - prev_idle)); \
total_diff=$((curr_total - prev_total)); \
if [ $total_diff -gt 0 ]; then echo \"scale=4; ($total_diff - $idle_diff) * 100 / $total_diff\" | bc -l; else echo 0; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text.trim()
                const value = parseFloat(text)
                if (!isNaN(value) && isFinite(value) && value >= 0 && value <= 100) {
                    cpuUsage = value / 100
                }
                root.updateCpuUsageHistory()
            }
        }
    }

    FileView { id: fileMeminfo; path: "/proc/meminfo" }

    Process {
        id: findCpuMaxFreqProc
        environment: ({ LANG: "C", LC_ALL: "C" })
        command: ["bash", "-c", "lscpu | grep 'CPU max MHz' | awk '{print $4}'"]
        running: true
        stdout: StdioCollector {
            id: outputCollector
            onStreamFinished: {
                root.maxAvailableCpuString = (parseFloat(outputCollector.text) / 1000).toFixed(0) + " GHz"
            }
        }
    }
}
