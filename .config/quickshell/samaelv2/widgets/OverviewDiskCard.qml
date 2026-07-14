import QtQuick
import QtQuick.Layouts
import "../singletons"

Rectangle {
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
        OverviewTrafficBar {
            Layout.fillWidth: true
            barRadius: 4
            implicitHeight: 8
            fraction: SystemOverviewLogic.diskPct / 100
            trackOpacity: 0.12
        }
        Text {
            visible: SystemOverviewLogic.diskUsed.length > 0
            Layout.fillWidth: true
            text: SystemOverviewLogic.diskUsed + " / " + SystemOverviewLogic.diskTotal
            font.family: Style.fontFamily
            font.pixelSize: 8
            color: WallustColors.moduleText
            opacity: 0.7
            elide: Text.ElideRight
        }
        Item { Layout.fillHeight: true }
    }
}