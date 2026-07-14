import QtQuick
import QtQuick.Layouts
import "../singletons"
import "../widgets"

FocusScope {
    id: root

    property bool open: false
    property real morphCloseness: 1

    /** metrics | processes — horizontal slide */
    property string overviewPage: "metrics"
    property int procColumn: 0
    property int procRow: 0

    readonly property int cardW: 124
    readonly property int topRowH: 128
    readonly property int bottomRowH: 96
    readonly property int batteryW: 52
    readonly property int gap: 8
    readonly property int pad: 10
    readonly property int metricsW: pad * 2 + cardW * 3 + gap * 3 + batteryW
    readonly property int metricsH: pad * 2 + topRowH + gap + bottomRowH
    readonly property int procsW: metricsW
    /** Same vertical canvas as metrics so both cards fit 3 rows. */
    readonly property int procsH: metricsH

    implicitWidth: Math.max(metricsW, procsW)
    implicitHeight: metricsH

    readonly property real slideX: overviewPage === "processes" ? -implicitWidth : 0

    opacity: open ? Math.pow(morphCloseness, 1.2) : 0
    visible: opacity > 0.02
    focus: open
    activeFocusOnTab: false

    property bool batteryDemo: true

    readonly property real batteryLevelNorm: {
        if (batteryDemo)
            return 0.68
        const p = SystemOverviewLogic.batteryPct
        return (p > 1) ? (p / 100) : p
    }

    onOpenChanged: {
        SystemOverviewLogic.panelOpen = open
        if (open) {
            overviewPage = "metrics"
            procColumn = 0
            procRow = 0
            Qt.callLater(forceActiveFocus)
        }
    }

    function procRowCount(col) {
        const n = col === 0 ? SystemOverviewLogic.topCpuProcesses.length
            : SystemOverviewLogic.topMemProcesses.length
        return Math.min(3, Math.max(n, 1))
    }

    function clampProcNav() {
        procColumn = Math.max(0, Math.min(1, procColumn))
        const maxR = procRowCount(procColumn) - 1
        procRow = Math.max(0, Math.min(maxR, procRow))
    }

    function stepProcRow(delta) {
        const maxR = procRowCount(procColumn) - 1
        if (maxR < 0)
            return
        procRow = Math.max(0, Math.min(maxR, procRow + delta))
    }

    Rectangle {
        anchors.fill: parent
        radius: ShellConfig.cornerRadius - 4
        color: "transparent"
    }

    Item {
        anchors.fill: parent
        clip: true

        Item {
            id: slideTrack
            width: root.implicitWidth * 2
            height: parent.height
            x: root.slideX

            Behavior on x {
                NumberAnimation {
                    duration: Motion.morph
                    easing.type: Motion.easeMorph
                    easing.bezierCurve: Motion.morphCurve
                }
            }

            // —— Metrics (left card) ——
            Item {
                width: root.implicitWidth
                height: parent.height
                x: 0

            RowLayout {
                anchors.fill: parent
                anchors.margins: pad
                spacing: gap

                ColumnLayout {
                    Layout.fillHeight: true
                    spacing: gap

                    RowLayout {
                        spacing: gap
                        Layout.preferredHeight: topRowH

                        Rectangle {
                            Layout.preferredWidth: cardW
                            Layout.fillHeight: true
                            radius: 10
                            color: Qt.rgba(0, 0, 0, 0.18)
                            border.width: 1
                            border.color: Qt.rgba(WallustColors.borderColor.r, WallustColors.borderColor.g,
                                WallustColors.borderColor.b, 0.45)

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 4

                                OverviewArcGauge {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.preferredWidth: 84
                                    Layout.preferredHeight: 72
                                    value: SystemOverviewLogic.cpuUsage
                                    centerGlyph: "\uf2db"
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: Math.round(SystemOverviewLogic.cpuUsage * 100) + "%"
                                    font.family: Style.fontFamily
                                    font.pixelSize: 10
                                    color: WallustColors.moduleText
                                }

                                OverviewTrafficBar {
                                    Layout.fillWidth: true
                                    implicitHeight: 6
                                    barRadius: 3
                                    fraction: isNaN(SystemOverviewLogic.temperatureC)
                                        ? 0 : SystemOverviewLogic.temperatureC / 100
                                    trackOpacity: 0.12
                                }

                                Row {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 4
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: SystemOverviewLogic.temperatureIcon(SystemOverviewLogic.temperatureC)
                                        font.family: Style.fontFamily
                                        font.pixelSize: 10
                                        color: SystemOverviewLogic.temperatureColor(SystemOverviewLogic.temperatureC)
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: isNaN(SystemOverviewLogic.temperatureC)
                                            ? "—°C"
                                            : Math.round(SystemOverviewLogic.temperatureC) + "°C"
                                        font.family: Style.fontFamily
                                        font.pixelSize: 9
                                        color: SystemOverviewLogic.temperatureColor(SystemOverviewLogic.temperatureC)
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: cardW
                            Layout.fillHeight: true
                            radius: 10
                            color: Qt.rgba(0, 0, 0, 0.18)
                            border.width: 1
                            border.color: Qt.rgba(WallustColors.borderColor.r, WallustColors.borderColor.g,
                                WallustColors.borderColor.b, 0.45)

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 4

                                OverviewArcGauge {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.preferredWidth: 84
                                    Layout.preferredHeight: 72
                                    value: {
                                        const u = SystemOverviewLogic.gpuUsage
                                        return (isFinite(u) && !isNaN(u)) ? u : 0
                                    }
                                    centerGlyph: "\uf108"
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: SystemOverviewLogic.gpuAvailable
                                        ? Math.round(SystemOverviewLogic.gpuUsage * 100) + "%"
                                        : "N/A"
                                    font.family: Style.fontFamily
                                    font.pixelSize: 10
                                    color: WallustColors.moduleText
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    visible: SystemOverviewLogic.gpuLabel.length > 0
                                    text: SystemOverviewLogic.gpuLabel
                                    font.family: Style.fontFamily
                                    font.pixelSize: 7
                                    color: WallustColors.moduleText
                                    opacity: 0.55
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: cardW - 8
                                }

                                OverviewTrafficBar {
                                    Layout.fillWidth: true
                                    implicitHeight: 6
                                    barRadius: 3
                                    fraction: isNaN(SystemOverviewLogic.gpuPowerW)
                                        ? 0 : SystemOverviewLogic.gpuPowerW / SystemOverviewLogic.gpuPowerMaxW
                                    trackOpacity: 0.12
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: SystemOverviewLogic.formatPowerW(SystemOverviewLogic.gpuPowerW)
                                    font.family: Style.fontFamily
                                    font.pixelSize: 9
                                    color: WallustColors.moduleText
                                    opacity: 0.75
                                }
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: cardW
                            Layout.fillHeight: true
                            radius: 10
                            color: Qt.rgba(0, 0, 0, 0.18)
                            border.width: 1
                            border.color: Qt.rgba(WallustColors.borderColor.r, WallustColors.borderColor.g,
                                WallustColors.borderColor.b, 0.45)

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 4

                                OverviewArcGauge {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.preferredWidth: 84
                                    Layout.preferredHeight: 72
                                    value: SystemOverviewLogic.memUsedRatio
                                    centerGlyph: "\u{F0F86}"
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: Math.round(SystemOverviewLogic.memUsedRatio * 100) + "%"
                                    font.family: Style.fontFamily
                                    font.pixelSize: 10
                                    color: WallustColors.moduleText
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: SystemOverviewLogic.formatMemShort()
                                    font.family: Style.fontFamily
                                    font.pixelSize: 8
                                    color: WallustColors.moduleText
                                    opacity: 0.7
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: bottomRowH
                        spacing: gap

                        OverviewNetworkPanel {
                            Layout.preferredWidth: cardW * 2 + gap
                            Layout.fillHeight: true
                            textColumnMaxWidth: cardW
                        }

                        OverviewDiskCard {
                            Layout.preferredWidth: cardW
                            Layout.fillHeight: true
                        }
                    }
                }

                OverviewBatteryColumn {
                    Layout.preferredWidth: batteryW
                    Layout.fillHeight: true
                    available: root.batteryDemo ? true : SystemOverviewLogic.batteryAvailable
                    level: root.batteryLevelNorm
                    charging: root.batteryDemo ? true : SystemOverviewLogic.batteryCharging
                }
            }
            }

            // —— Processes (right card) ——
            Item {
                width: root.implicitWidth
                height: parent.height
                x: root.implicitWidth

                OverviewProcsPanel {
                    anchors.fill: parent
                    anchors.margins: pad
                    selectedColumn: root.procColumn
                    selectedRow: root.procRow
                }
            }
        }
    }

    readonly property int _procRev: SystemOverviewLogic.procsRevision
    on_ProcRevChanged: clampProcNav()

    Keys.onPressed: event => {
        if (!open)
            return
        if (event.key === Qt.Key_Escape) {
            if (overviewPage === "processes") {
                overviewPage = "metrics"
                event.accepted = true
                return
            }
            if (ShellActions.closeRightSurface)
                ShellActions.closeRightSurface()
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Tab) {
            overviewPage = overviewPage === "metrics" ? "processes" : "metrics"
            clampProcNav()
            event.accepted = true
            return
        }
        if (overviewPage === "processes") {
            const t = event.text
            if (t === "h" || (event.key === Qt.Key_Left && !(event.modifiers & Qt.ShiftModifier))) {
                procColumn = 0
                clampProcNav()
                event.accepted = true
                return
            }
            if (t === "l" || event.key === Qt.Key_Right) {
                procColumn = 1
                clampProcNav()
                event.accepted = true
                return
            }
            if (t === "j" || event.key === Qt.Key_Down) {
                stepProcRow(1)
                event.accepted = true
                return
            }
            if (t === "k" || event.key === Qt.Key_Up) {
                stepProcRow(-1)
                event.accepted = true
            }
        }
    }
}