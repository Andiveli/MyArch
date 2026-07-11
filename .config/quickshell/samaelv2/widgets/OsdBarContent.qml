import QtQuick
import "../singletons"

/** Volume / brightness bar (pill OSD chip, Wallust). */
Item {
    id: root

    property string kind: "volume"
    property real level: 0
    property bool muted: false

    width: parent ? parent.width : implicitWidth
    implicitWidth: row.implicitWidth
    implicitHeight: 28
    height: implicitHeight

    Row {
        id: row
        spacing: 9
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.kind === "brightness" ? "\uf185" : (root.muted ? "\uf6a9" : "\uf028")
            color: root.kind === "volume" && root.muted
                    ? Qt.rgba(WallustColors.moduleText.r, WallustColors.moduleText.g, WallustColors.moduleText.b, 0.45)
                    : WallustColors.moduleText
            font.family: Style.fontFamily
            font.pixelSize: 13
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 64
            height: 3
            radius: 1.5
            color: Qt.rgba(WallustColors.borderColor.r, WallustColors.borderColor.g, WallustColors.borderColor.b, 0.35)

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * Math.max(0, Math.min(1, root.level))
                radius: parent.radius
                color: root.kind === "volume" && root.muted ? WallustColors.red : WallustColors.sapphire
                Behavior on width { NumberAnimation { duration: Motion.fast } }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(root.level * 100) + "%"
            color: root.kind === "volume" && root.muted
                    ? Qt.rgba(WallustColors.moduleText.r, WallustColors.moduleText.g, WallustColors.moduleText.b, 0.45)
                    : WallustColors.moduleText
            font.family: Style.fontFamily
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }
    }
}