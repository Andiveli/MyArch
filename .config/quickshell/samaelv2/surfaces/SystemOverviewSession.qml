
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * CPU, GPU, RAM, disk, temp, network rates, battery for SystemOverviewSurface.
 */
Item {
    id: root

    property bool panelOpen: false

    property real cpuUsage: 0
    property int memTotalKb: 1
    property int memUsedKb: 0
    readonly property real memUsedRatio: memTotalKb > 0 ? memUsedKb / memTotalKb : 0

    property real gpuUsage: NaN
    property bool gpuAvailable: false
    /** "nvidia" | "intel" | "" */
    property string gpuKind: ""
    property string gpuLabel: ""
    property real gpuPowerW: NaN
    /** Scale for PWR bar (W) */
    property real gpuPowerMaxW: 28
    property var _prevGpuEnergy: null

    property int diskPct: 0
    property string diskUsed: ""
    property string diskTotal: ""

    property real temperatureC: NaN

    property real downloadBps: 0
    property real uploadBps: 0
    property var netHistoryDown: []
    property var netHistoryUp: []

    property bool batteryAvailable: false
    property real batteryPct: 1
    property bool batteryCharging: false

    property var _prevCpu: null
    property var _prevNet: null

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
                cpuUsage = Math.max(0, Math.min(1, 1 - di / dt))
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
                return
            }
        }
        temperatureC = NaN
    }

    function pushHistory(arr, v, maxLen) {
        const next = arr.slice()
        next.push(v)
        while (next.length > maxLen)
            next.shift()
        return next
    }

    function pollNetwork() {
        fileNet.reload()
        const text = fileNet.text()
        let rx = 0
        let tx = 0
        const lines = text.split("\n")
        for (let i = 0; i < lines.length; i++) {
            const ln = lines[i].trim()
            if (!ln.length || ln.indexOf(":") < 0)
                continue
            const name = ln.split(":")[0].trim()
            if (name === "lo")
                continue
            const parts = ln.split(":")[1].trim().split(/\s+/)
            if (parts.length < 10)
                continue
            rx += Number(parts[0]) || 0
            tx += Number(parts[8]) || 0
        }
        const now = Date.now()
        if (_prevNet) {
            const dt = (now - _prevNet.t) / 1000
            if (dt > 0.05) {
                downloadBps = Math.max(0, (rx - _prevNet.rx) / dt)
                uploadBps = Math.max(0, (tx - _prevNet.tx) / dt)
                netHistoryDown = pushHistory(netHistoryDown, downloadBps, 48)
                netHistoryUp = pushHistory(netHistoryUp, uploadBps, 48)
            }
        }
        _prevNet = { rx: rx, tx: tx, t: now }
    }

        function formatPowerW(w) {
            if (!isFinite(w) || w < 0)
                return "— W"
            if (w < 10)
                return w.toFixed(1) + " W"
            return Math.round(w) + " W"
        }

    function formatRate(bps) {
        if (!isFinite(bps) || bps < 1)
            return "0 B/s"
        if (bps < 1024)
            return Math.round(bps) + " B/s"
        if (bps < 1024 * 1024)
            return (bps / 1024).toFixed(1) + " KB/s"
        return (bps / (1024 * 1024)).toFixed(2) + " MB/s"
    }

    function formatMemShort() {
        const u = memUsedKb / (1024 * 1024)
        const t = memTotalKb / (1024 * 1024)
        return u.toFixed(1) + " / " + t.toFixed(0) + " GB"
    }

    FileView { id: fileStat; path: "/proc/stat" }
    FileView { id: fileMeminfo; path: "/proc/meminfo" }
    FileView { id: fileNet; path: "/proc/net/dev" }
    FileView { id: tempReader; path: tempPaths[0] }

    Timer {
        interval: 1500
        running: root.panelOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: root.pollCpu()
    }

    Timer {
        interval: 2000
        running: root.panelOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.pollMemory()
            root.readTemperature()
            root.pollNetwork()
            diskProc.running = false
            diskProc.running = true
            gpuProc.running = false
            gpuProc.running = true
            batProc.running = false
            batProc.running = true
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
            id: gpuProc
            command: ["bash", "-c",
                "util=NA; pwr=NA; kind=; label=; rapl=; "
                    + "if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L 2>/dev/null | grep -q GPU; then "
                    + "util=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1); "
                    + "pwr=$(nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits 2>/dev/null | head -1); "
                    + "kind=nvidia; label=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1); "
                    + "else for p in /sys/class/drm/card*/device/gpu_busy_percent; do "
                    + "[ -f \"$p\" ] || continue; util=$(cat \"$p\" 2>/dev/null); [ -z \"$util\" ] && util=0; kind=intel; label='Intel iGPU'; break; done; fi; "
                    + "if [ -z \"$util\" ] || [ \"$util\" = NA ]; then "
                    + "if command -v intel_gpu_top >/dev/null 2>&1; then "
                    + "line=$(timeout 0.55 intel_gpu_top -l 1 2>/dev/null | head -25 | grep -E '[0-9]+' | head -1); "
                    + "util=$(echo \"$line\" | awk '{for(i=NF;i>=1;i--) if($i+0==$i && $i<=100) {print $i; exit}}'); "
                    + "[ -z \"$util\" ] && util=0; kind=intel; label='Intel Gen9'; fi; fi; "
                    + "for z in /sys/class/powercap/intel-rapl/intel-rapl:0/intel-rapl:0:*; do "
                    + "[ -f \"$z/energy_uj\" ] || continue; n=$(cat \"$z/name\" 2>/dev/null); "
                    + "echo \"$n\" | grep -qiE 'gpu|uncore' && rapl=$(cat \"$z/energy_uj\" 2>/dev/null) && break; done; "
                    + "[ -z \"$rapl\" ] && [ -f /sys/class/powercap/intel-rapl/intel-rapl:0/energy_uj ] "
                    + "&& rapl=$(cat /sys/class/powercap/intel-rapl/intel-rapl:0/energy_uj 2>/dev/null); "
                    + "echo \"${util}|${pwr}|${kind}|${label}|${rapl}\""]

            stdout: SplitParser {
                onRead: data => {
                    const parts = data.trim().split("|")
                    const utilS = parts[0] || ""
                    const pwrS = parts[1] || ""
                    const kind = parts[2] || ""
                    const label = parts[3] || ""
                    const raplUj = parts[4] || ""
                    if (utilS === "NA" || utilS === "") {
                        root.gpuAvailable = false
                        root.gpuUsage = NaN
                        root.gpuKind = ""
                        root.gpuLabel = ""
                    } else {
                        const n = parseFloat(utilS)
                        if (isFinite(n)) {
                            root.gpuAvailable = true
                            root.gpuUsage = Math.max(0, Math.min(1, n / 100))
                            root.gpuKind = kind
                            root.gpuLabel = label.length ? label : (kind === "nvidia" ? "NVIDIA" : "Intel iGPU")
                            root.gpuPowerMaxW = kind === "nvidia" ? 120 : 28
                        } else if (kind.length) {
                            root.gpuAvailable = true
                            root.gpuUsage = 0
                            root.gpuKind = kind
                            root.gpuLabel = label.length ? label : "GPU"
                        } else {
                            root.gpuAvailable = false
                            root.gpuUsage = NaN
                        }
                    }
                    let pw = parseFloat(pwrS)
                    if (isFinite(pw) && pw >= 0)
                        root.gpuPowerW = pw
                    else if (raplUj.length) {
                        const uj = parseFloat(raplUj)
                        const now = Date.now()
                        if (isFinite(uj) && root._prevGpuEnergy) {
                            const dt = (now - root._prevGpuEnergy.t) / 1000
                            const du = uj - root._prevGpuEnergy.uj
                            if (dt > 0.3 && du >= 0)
                                root.gpuPowerW = du / dt / 1e6
                        }
                        if (isFinite(uj))
                            root._prevGpuEnergy = { uj: uj, t: now }
                    } else if (!isFinite(pw))
                        root.gpuPowerW = NaN
                }
            }
        }

    Process {
        id: batProc
        command: ["bash", "-c",
            "upower -i $(upower -e | grep -m1 'BAT\\|battery' | head -1) 2>/dev/null | "
                + "awk -F: '/percentage/{gsub(/[^0-9]/,\"\",$2); p=$2+0} /state/{gsub(/^[ \\t]+|[ \\t]+$/,\"\",$2); s=$2} END{print p\"|\"s}'"]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split("|")
                const p = parseFloat(parts[0])
                if (isFinite(p) && p >= 0) {
                    root.batteryAvailable = true
                    root.batteryPct = Math.max(0, Math.min(1, p / 100))
                    const st = (parts[1] || "").toLowerCase()
                    root.batteryCharging = st.indexOf("charging") >= 0
                } else {
                    root.batteryAvailable = false
                }
            }
        }
    }
}