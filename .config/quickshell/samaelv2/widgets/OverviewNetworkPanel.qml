import QtQuick
import QtQuick.Layouts
import "../singletons"

/** Two-card-wide network block: labels (≤1 card) + dual sparkline for the rest. */
Rectangle {
    id: root

    property int textColumnMaxWidth: 124

    radius: 10
    color: Qt.rgba(0, 0, 0, 0.18)
    border.width: 1
    border.color: Qt.rgba(WallustColors.borderColor.r, WallustColors.borderColor.g,
        WallustColors.borderColor.b, 0.45)

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 10

        ColumnLayout {
            Layout.maximumWidth: root.textColumnMaxWidth
            Layout.preferredWidth: Math.min(root.textColumnMaxWidth, implicitWidth)
            Layout.fillHeight: true
            spacing: 6

            Text {
                text: "Network"
                font.family: Style.fontFamily
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: WallustColors.moduleText
            }
            Text {
                Layout.fillWidth: true
                text: "\uf019  " + SystemOverviewLogic.formatRate(SystemOverviewLogic.downloadBps)
                font.family: Style.fontFamily
                font.pixelSize: 9
                color: WallustColors.moduleText
                opacity: 0.9
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: "\uf093  " + SystemOverviewLogic.formatRate(SystemOverviewLogic.uploadBps)
                font.family: Style.fontFamily
                font.pixelSize: 9
                color: WallustColors.moduleText
                opacity: 0.9
                elide: Text.ElideRight
            }
            Item { Layout.fillHeight: true }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
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
                Item { Layout.fillWidth: true }
            }
        }
    }
}