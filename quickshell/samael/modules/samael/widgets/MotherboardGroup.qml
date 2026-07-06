import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.modules.samael

Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    property int barNavIndexPower: 1
    property int barNavIndexMem: 2
    property int barNavIndexDisk: 3

    function toggleMemDisplay() {
root.memShowPercent = !root.memShowPercent
    }

    function toggleDiskDisplay() {
root.diskShowRatio = !root.diskShowRatio
root.refreshDiskLabel()
    }

    function stepPowerProfile(delta) {
root._stepPowerDelta = delta
root._cyclePower = false
pwrGetProc.running = false
pwrGetProc.running = true
    }

    property real cpuUsage: 0
    property var _prevCpu: null

    property int memTotalKb: 1
    property int memUsedKb: 0
    property bool memShowPercent: false
    property bool diskShowRatio: false
    property string diskUsed: ""
    property string diskTotal: ""
    property int diskPct: 0
    property int _stepPowerDelta: 0

    Row {
        id: row
        spacing: SamaelStyle.moduleRowSpacing

        SamaelPaddedText {
            id: cpuText
            textColor: WallustColors.mauve
            text: Math.round(root.cpuUsage * 100) + "% 󰍛"
        }

            SamaelBarButton {
                id: powerBtn
                text: ""
                property bool barNavFocused: GlobalStates.samaelBarNavActive
                    && GlobalStates.samaelBarFocus === root.barNavIndexPower
                onClicked: () => root.cyclePowerProfile()
                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: "transparent"
                    border.width: parent.barNavFocused ? 2 : 0
                    border.color: WallustColors.workspaceActive
                    z: 10
                    visible: parent.barNavFocused
                }
            }

        SamaelBarButton {
            id: memBtn
            normalColor: WallustColors.sapphire
            text: "0.0G 󰾆"
            property bool barNavFocused: GlobalStates.samaelBarNavActive
                && GlobalStates.samaelBarFocus === root.barNavIndexMem
            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton)
                    Quickshell.execDetached("bash -c '$HOME/.config/hypr/scripts/WaybarScripts.sh --btop'")
                else
                    root.toggleMemDisplay()
            }
            Rectangle {
                anchors.fill: parent
                radius: 8
                color: "transparent"
                border.width: parent.barNavFocused ? 2 : 0
                border.color: WallustColors.workspaceActive
                z: 10
                visible: parent.barNavFocused
            }
        }

        Item {
            id: tempHit
            implicitWidth: tempText.implicitWidth
            implicitHeight: tempText.implicitHeight
            SamaelPaddedText {
                id: tempText
                anchors.centerIn: parent
                property bool tempCritical: false
                textColor: tempCritical ? WallustColors.temperatureCritical : WallustColors.moduleText
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: SamaelBarNavHub.togglePerformanceDrop()
            }
        }

            Item {
                id: diskHit
                implicitWidth: diskText.implicitWidth
                implicitHeight: diskText.implicitHeight
                property bool barNavFocused: GlobalStates.samaelBarNavActive
                    && GlobalStates.samaelBarFocus === root.barNavIndexDisk
                SamaelPaddedText {
                    id: diskText
                    anchors.centerIn: parent
                    textColor: WallustColors.sky
                }
                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: "transparent"
                    border.width: diskHit.barNavFocused ? 2 : 0
                    border.color: WallustColors.workspaceActive
                    z: 10
                    visible: diskHit.barNavFocused
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.toggleDiskDisplay()
                }
            }
    }

    function updateMemLabel() {
        if (root.memShowPercent) {
            const pct = Math.round(100 * root.memUsedKb / root.memTotalKb)
            memBtn.text = pct + "% 󰾆"
        } else {
            memBtn.text = (root.memUsedKb / (1024 * 1024)).toFixed(1) + "G 󰾆"
        }
    }

    readonly property var powerCycle: ["performance", "balanced", "power-saver"]

    function cyclePowerProfile() {
        root._stepPowerDelta = 0
        pwrGetProc.running = false
        pwrGetProc.running = true
        root._cyclePower = true
    }

    property bool _cyclePower: false

    function profileIcon(profile) {
        const p = profile.toLowerCase()
        if (p.includes("performance"))
            return ""
        if (p.includes("power-saver") || p.includes("power_saver"))
            return ""
        return ""
    }

    function profileIndex(current) {
        const cur = current.trim().toLowerCase()
        let idx = powerCycle.findIndex(n => cur.includes(n.replace("-", "")) || cur === n)
        if (idx < 0) {
            if (cur.includes("performance"))
                idx = 0
            else if (cur.includes("balanced"))
                idx = 1
            else if (cur.includes("power"))
                idx = 2
            else
                idx = 1
        }
        return idx
    }

    function applyProfileAtIndex(idx) {
        const i = ((idx % powerCycle.length) + powerCycle.length) % powerCycle.length
        const next = powerCycle[i]
        pwrSetProc.command = ["powerprofilesctl", "set", next]
        pwrSetProc.running = false
        pwrSetProc.running = true
    }

    function applyNextProfile(current) {
        applyProfileAtIndex(profileIndex(current) + 1)
    }

    FileView { id: fileStat; path: "/proc/stat" }
    FileView { id: fileMeminfo; path: "/proc/meminfo" }

    function pollCpu() {
        fileStat.reload()
        const line = fileStat.text().match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/m)
        if (!line)
            return
        const stats = line.slice(1).map(Number)
        const total = stats.reduce((a, b) => a + b, 0)
        const idle = stats[3] + stats[4]
        if (root._prevCpu) {
            const dt = total - root._prevCpu.total
            const di = idle - root._prevCpu.idle
            if (dt > 0)
                root.cpuUsage = 1 - di / dt
        }
        root._prevCpu = { total: total, idle: idle }
    }

    function pollMemory() {
        fileMeminfo.reload()
        const t = fileMeminfo.text()
        root.memTotalKb = Number(t.match(/MemTotal:\s*(\d+)/)?.[1] ?? 1)
        const avail = Number(t.match(/MemAvailable:\s*(\d+)/)?.[1] ?? 0)
        root.memUsedKb = root.memTotalKb - avail
        root.updateMemLabel()
    }

    onMemShowPercentChanged: root.updateMemLabel()

    function readTemperature() {
        for (const path of tempPaths) {
            tempReader.path = path
            tempReader.reload()
            const raw = parseInt(tempReader.text().trim())
            if (!isNaN(raw) && raw > 0) {
                const c = raw >= 1000 ? raw / 1000.0 : raw
                tempText.text = c.toFixed(0) + "°C 󰈸"
                tempText.tempCritical = c >= 82
                return
            }
        }
        tempText.text = "—°C 󰈸"
    }

    readonly property var tempPaths: [
        "/sys/class/hwmon/hwmon1/temp1_input",
        "/sys/class/thermal/thermal_zone0/temp"
    ]

    FileView { id: tempReader; path: tempPaths[0] }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.pollCpu()
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.pollMemory()
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.readTemperature()
    }

    function refreshDiskLabel() {
        if (root.diskShowRatio && root.diskUsed.length && root.diskTotal.length)
            diskText.text = root.diskUsed + "/" + root.diskTotal + " 󰋊"
        else
            diskText.text = root.diskPct + "% 󰋊"
    }

    Process {
        id: diskProc
        command: ["bash", "-c", "df -h / | tail -1 | awk '{print $5,$3,$2}'"]
        stdout: SplitParser {
            onRead: (data) => {
                const parts = data.trim().split(/\s+/)
                root.diskPct = parseInt(String(parts[0]).replace("%", "")) || 0
                root.diskUsed = parts[1] || ""
                root.diskTotal = parts[2] || ""
                root.refreshDiskLabel()
            }
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            diskProc.running = false
            diskProc.running = true
        }
    }

    Process {
        id: pwrGetProc
        command: ["powerprofilesctl", "get"]
        stdout: SplitParser {
            onRead: (data) => {
                const profile = data.trim()
                powerBtn.text = root.profileIcon(profile)
                if (root._stepPowerDelta !== 0) {
                    const d = root._stepPowerDelta
                    root._stepPowerDelta = 0
                    root.applyProfileAtIndex(root.profileIndex(profile) + d)
                } else if (root._cyclePower) {
                    root._cyclePower = false
                    root.applyNextProfile(profile)
                }
            }
        }
    }

    Process {
        id: pwrSetProc
        command: ["powerprofilesctl", "set", "balanced"]
        onExited: () => {
            pwrGetProc.running = false
            pwrGetProc.running = true
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root._cyclePower = false
            pwrGetProc.running = false
            pwrGetProc.running = true
        }
    }
}