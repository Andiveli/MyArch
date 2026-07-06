pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Samael system sidebar data: CPU, RAM, disk, temp, top processes.
 */
Singleton {
    id: root

    property real cpuUsage: 0
    property int memTotalKb: 1
    property int memUsedKb: 0
    readonly property real memUsedRatio: memUsedKb / memTotalKb

    property int diskPct: 0
    property string diskUsed: ""
    property string diskTotal: ""

    property real temperatureC: NaN
    property bool temperatureCritical: false

    property var topProcessesByCpu: []
    property var topProcessesByMem: []

    property var _prevCpu: null

    readonly property string _psPipeline:
        "ps ax -o pid=,comm=,%cpu=,%mem= --no-headers | awk '"
        + "{c=$3+0;m=$4+0;n=$2;"
        + "if(n~/^(ps|awk|sort|bash|head|sh|sed|grep|tee|cat)$/)next;"
        + "if(c>0.05||m>0.05) printf \"%s|%d|%.1f|%.1f\\n\",n,$1,c,m}"
        + "'"

    readonly property var tempPaths: [
        "/sys/class/hwmon/hwmon1/temp1_input",
        "/sys/class/thermal/thermal_zone0/temp",
    ]

    function pollCpu() {
        fileStat.reload()
        const line = fileStat.text().match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/m)
        if (!line)
            return
        const stats = line.slice(1).map(Number)
        const total = stats.reduce((a, b) => a + b, 0)
        const idle = stats[3] + stats[4]
        if (_prevCpu) {
            const dt = total - _prevCpu.total
            const di = idle - _prevCpu.idle
            if (dt > 0)
                cpuUsage = 1 - di / dt
        }
        _prevCpu = { total: total, idle: idle }
    }

    function pollMemory() {
        fileMeminfo.reload()
        const t = fileMeminfo.text()
        memTotalKb = Number(t.match(/MemTotal:\s*(\d+)/)?.[1] ?? 1)
        const avail = Number(t.match(/MemAvailable:\s*(\d+)/)?.[1] ?? 0)
        memUsedKb = memTotalKb - avail
    }

    function readTemperature() {
        for (let i = 0; i < tempPaths.length; i++) {
            tempReader.path = tempPaths[i]
            tempReader.reload()
            const raw = parseInt(tempReader.text().trim())
            if (!isNaN(raw) && raw > 0) {
                const c = raw >= 1000 ? raw / 1000.0 : raw
                temperatureC = c
                temperatureCritical = c >= 82
                return
            }
        }
        temperatureC = NaN
        temperatureCritical = false
    }

    function parseTopProcessLines(lines, limit) {
        const out = []
        for (let i = 0; i < lines.length && out.length < limit; i++) {
            const parts = lines[i].split("|")
            if (parts.length < 4)
                continue
            const name = parts[0].trim()
            const pid = parseInt(parts[1], 10) || 0
            const cpu = parseFloat(parts[2]) || 0
            const mem = parseFloat(parts[3]) || 0
            if (name.length && pid > 0)
                out.push({ name: name, pid: pid, cpu: cpu, mem: mem })
        }
        return out
    }

    FileView { id: fileStat; path: "/proc/stat" }
    FileView { id: fileMeminfo; path: "/proc/meminfo" }
    FileView { id: tempReader; path: tempPaths[0] }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.pollCpu()
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.pollMemory()
            root.readTemperature()
            diskProc.running = false
            diskProc.running = true
            topCpuProc.running = false
            topCpuProc.running = true
            topMemProc.running = false
            topMemProc.running = true
        }
    }

    Process {
        id: diskProc
        command: ["bash", "-c", "df -h / | tail -1 | awk '{print $5,$3,$2}'"]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(/\s+/)
                root.diskPct = parseInt(String(parts[0]).replace("%", "")) || 0
                root.diskUsed = parts[1] || ""
                root.diskTotal = parts[2] || ""
            }
        }
    }

    Process {
        id: topCpuProc
        property var _lines: []
        command: ["bash", "-c", root._psPipeline + " | sort -t'|' -k3 -nr | head -3"]
        stdout: SplitParser {
            onRead: data => {
                const line = data.trim()
                if (line.length)
                    topCpuProc._lines.push(line)
            }
        }
        onExited: exitCode => {
            if (exitCode === 0)
                root.topProcessesByCpu = root.parseTopProcessLines(topCpuProc._lines, 3)
            topCpuProc._lines = []
        }
    }

    Process {
        id: topMemProc
        property var _lines: []
        command: ["bash", "-c", root._psPipeline + " | sort -t'|' -k4 -nr | head -3"]
        stdout: SplitParser {
            onRead: data => {
                const line = data.trim()
                if (line.length)
                    topMemProc._lines.push(line)
            }
        }
        onExited: exitCode => {
            if (exitCode === 0)
                root.topProcessesByMem = root.parseTopProcessLines(topMemProc._lines, 3)
            topMemProc._lines = []
        }
    }
}