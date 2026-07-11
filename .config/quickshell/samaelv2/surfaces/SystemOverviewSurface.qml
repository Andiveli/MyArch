import QtQuick
import QtQuick.Layouts
import "../singletons"
import "../widgets"

FocusScope {
    id: root

    property bool open: false
    property real morphCloseness: 1

    readonly property int cardW: 124
    readonly property int topRowH: 128
    readonly property int bottomRowH: 96
    readonly property int batteryW: 52
    readonly property int gap: 8
    readonly property int pad: 10

    implicitWidth: pad * 2 + cardW * 3 + gap * 3 + batteryW
    implicitHeight: pad * 2 + topRowH + gap + bottomRowH

    opacity: open ? Math.pow(morphCloseness, 1.2) : 0
    visible: opacity > 0.02

    /** Flip false when you have a real battery and want live upower data. */
    property bool batteryDemo: true

    readonly property real batteryLevelNorm: {
        if (batteryDemo)
            return 0.68
        const p = SystemOverviewLogic.batteryPct
        return (p > 1) ? (p / 100) : p
    }

    onOpenChanged: SystemOverviewLogic.panelOpen = open

    Rectangle {
        anchors.fill: parent
        radius: ShellConfig.cornerRadius - 4
        color: "transparent"
    }

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

                // CPU
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

                        OverviewSmoothBar {
                            Layout.fillWidth: true
                            fraction: isNaN(SystemOverviewLogic.temperatureC)
                                ? 0 : SystemOverviewLogic.temperatureC / 100
                            fillColor: SystemOverviewLogic.temperatureColor(SystemOverviewLogic.temperatureC)
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

                // GPU
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

                        OverviewSmoothBar {
                            Layout.fillWidth: true
                            fraction: isNaN(SystemOverviewLogic.gpuPowerW)
                                ? 0 : SystemOverviewLogic.gpuPowerW / SystemOverviewLogic.gpuPowerMaxW
                            fillColor: Qt.rgba(0.65, 0.55, 0.95, 0.9)
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

                // RAM
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

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape && open) {
            if (ShellActions.closeRightSurface)
                ShellActions.closeRightSurface()
            event.accepted = true
        }
    }
}