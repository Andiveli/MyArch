import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.modules.samael
import qs.services   // SamaelSystemMonitor is now the single source of truth for CPU/mem/disk/temp

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

    // ── Delegate to the single shared monitor (no more duplicate polling here) ──
    readonly property real cpuUsage: SamaelSystemMonitor.cpuUsage
    readonly property int memTotalKb: SamaelSystemMonitor.memTotalKb
    readonly property int memUsedKb: SamaelSystemMonitor.memUsedKb
    readonly property int diskPct: SamaelSystemMonitor.diskPct
    readonly property string diskUsed: SamaelSystemMonitor.diskUsed
    readonly property string diskTotal: SamaelSystemMonitor.diskTotal
    readonly property real temperatureC: SamaelSystemMonitor.temperatureC
    readonly property bool temperatureCritical: SamaelSystemMonitor.temperatureCritical

    // Local display formatting only
    property bool memShowPercent: false
    property bool diskShowRatio: false
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
                // Live from the single shared monitor (no local FileView / timer)
                text: isNaN(SamaelSystemMonitor.temperatureC) ? "—°C 󰈸"
                    : Math.round(SamaelSystemMonitor.temperatureC) + "°C 󰈸"
                textColor: SamaelSystemMonitor.temperatureCritical
                    ? WallustColors.temperatureCritical
                    : WallustColors.moduleText
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

    // ── Label formatting (single definitions — no duplicates) ───────────
    function updateMemLabel() {
        if (root.memShowPercent) {
            const pct = Math.round(100 * root.memUsedKb / root.memTotalKb)
            memBtn.text = pct + "% 󰾆"
        } else {
            memBtn.text = (root.memUsedKb / (1024 * 1024)).toFixed(1) + "G 󰾆"
        }
    }

    function refreshDiskLabel() {
        if (root.diskShowRatio && root.diskUsed.length && root.diskTotal.length)
            diskText.text = root.diskUsed + "/" + root.diskTotal + " 󰋊"
        else
            diskText.text = root.diskPct + "% 󰋊"
    }

    Component.onCompleted: {
        updateMemLabel()
        refreshDiskLabel()
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

    // ── LOCAL POWER PROFILE CONTROLS ONLY (no more CPU/mem/disk/temp polling here) ──

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
        interval: 15000
        running: GlobalStates.barOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root._cyclePower = false
            pwrGetProc.running = false
            pwrGetProc.running = true
        }
    }

    // ── React to data coming from the shared monitor ───────────────────
    onMemShowPercentChanged: updateMemLabel()

    Connections {
        target: SamaelSystemMonitor
        function onMemUsedKbChanged() { updateMemLabel() }
        function onMemTotalKbChanged() { updateMemLabel() }
        function onDiskUsedChanged() { refreshDiskLabel() }
        function onDiskTotalChanged() { refreshDiskLabel() }
        function onDiskPctChanged() { refreshDiskLabel() }
    }
}