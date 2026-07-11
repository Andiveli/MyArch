import QtQuick
import "../singletons"

/** Volume / brightness — centered in the same band as right widgets. */
Item {
    id: root

    property string kind: "volume"
    property real level: 0
    property bool muted: false

    anchors.fill: parent

    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        height: Style.barContentHeight
        anchors.verticalCenter: parent.verticalCenter

        Text {
            id: icon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.kind === "brightness" ? "\uf185" : (root.muted ? "\uf6a9" : "\uf028")
            color: WallustColors.moduleText
            opacity: root.kind === "volume" && root.muted ? 0.45 : 1
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize + 1
        }

        Text {
            id: pct
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            horizontalAlignment: Text.AlignRight
            text: Math.round(root.level * 100) + "%"
            color: WallustColors.moduleText
            opacity: root.kind === "volume" && root.muted ? 0.45 : 1
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize
            font.weight: Font.DemiBold
        }

        Rectangle {
            anchors.left: icon.right
            anchors.leftMargin: 8
            anchors.right: pct.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            height: 4
            radius: 2
            color: Qt.rgba(WallustColors.borderColor.r, WallustColors.borderColor.g, WallustColors.borderColor.b, 0.4)

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
    }
}