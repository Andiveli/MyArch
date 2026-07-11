import QtQuick
import QtQuick.Layouts
import "../singletons"

/** Network text (1 card) + dual sparkline (2 cards) + disk (1 card). */
RowLayout {
    id: root

    property int cardW: 124
    property int gap: 8

    spacing: gap

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
            anchors.margins: 8
            spacing: 4

            Text {
                text: "Network"
                font.family: Style.fontFamily
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: WallustColors.moduleText
            }
            Text {
                text: "\uf019  " + SystemOverviewLogic.formatRate(SystemOverviewLogic.downloadBps)
                font.family: Style.fontFamily
                font.pixelSize: 9
                color: WallustColors.moduleText
                opacity: 0.85
            }
            Text {
                text: "\uf093  " + SystemOverviewLogic.formatRate(SystemOverviewLogic.uploadBps)
                font.family: Style.fontFamily
                font.pixelSize: 9
                color: WallustColors.moduleText
                opacity: 0.85
            }
            Item { Layout.fillHeight: true }
        }
    }

    Rectangle {
        Layout.preferredWidth: cardW * 2 + gap
        Layout.fillHeight: true
        radius: 10
        color: Qt.rgba(0, 0, 0, 0.18)
        border.width: 1
        border.color: Qt.rgba(WallustColors.borderColor.r, WallustColors.borderColor.g,
            WallustColors.borderColor.b, 0.45)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 2

            OverviewNetDualSparkline {
                Layout.fillWidth: true
                Layout.fillHeight: true
                downSamples: SystemOverviewLogic.netHistoryDown
                upSamples: SystemOverviewLogic.netHistoryUp
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Text {
                    text: "download"
                    font.family: Style.fontFamily
                    font.pixelSize: 7
                    opacity: 0.45
                    color: WallustColors.moduleText
                }
                Text {
                    text: "upload"
                    font.family: Style.fontFamily
                    font.pixelSize: 7
                    opacity: 0.45
                    color: WallustColors.moduleText
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
            anchors.margins: 8
            spacing: 4

            Text {
                text: "Disk"
                font.family: Style.fontFamily
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: WallustColors.moduleText
            }
            Text {
                text: SystemOverviewLogic.diskPct + "%"
                font.family: Style.fontFamily
                font.pixelSize: 18
                font.weight: Font.DemiBold
                color: WallustColors.moduleText
            }
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 8
                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    color: Qt.rgba(WallustColors.moduleText.r, WallustColors.moduleText.g,
                        WallustColors.moduleText.b, 0.1)
                }
                Rectangle {
                    height: parent.height
                    width: parent.width * Math.min(1, SystemOverviewLogic.diskPct / 100)
                    radius: 4
                    color: Qt.rgba(0.45, 0.82, 0.62, 0.9)
                }
            }
            Text {
                visible: SystemOverviewLogic.diskUsed.length > 0
                text: SystemOverviewLogic.diskUsed + " / " + SystemOverviewLogic.diskTotal
                font.family: Style.fontFamily
                font.pixelSize: 8
                color: WallustColors.moduleText
                opacity: 0.7
            }
            Item { Layout.fillHeight: true }
        }
    }
}