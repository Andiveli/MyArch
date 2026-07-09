import QtQuick
import QtQuick.Layouts
import qs.modules.samael

Item {
    id: root
    required property string title
    required property string icon
    required property bool muted
    required property real volume
    required property int faderHeight

    signal toggleMute()
    /** Not volumeChanged — collides with QML volume property change signal */
    signal volumeCommitted(real v)

    implicitWidth: 96
    implicitHeight: column.implicitHeight

    Column {
        id: column
        spacing: 6
        anchors.horizontalCenter: parent.horizontalCenter

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.title
            color: WallustColors.sapphire
            font.family: SamaelStyle.fontFamily
            font.pixelSize: SamaelStyle.fontPixelSize - 1
        }

        MouseArea {
            anchors.horizontalCenter: parent.horizontalCenter
            implicitWidth: muteLabel.implicitWidth + 12
            implicitHeight: muteLabel.implicitHeight + 8
            onClicked: root.toggleMute()
            Text {
                id: muteLabel
                anchors.centerIn: parent
                text: root.icon
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 20
                color: root.muted ? WallustColors.buttonHover : WallustColors.moduleText
            }
        }

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 36
            height: root.faderHeight

            Rectangle {
                anchors.centerIn: parent
                width: 8
                height: parent.height
                radius: 4
                color: Qt.rgba(0, 0, 0, 0.35)
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                width: 8
                height: Math.max(4, (1 - root.volume) * parent.height)
                radius: 4
                color: "transparent"
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                width: 8
                height: Math.max(4, root.volume * parent.height)
                radius: 4
                color: WallustColors.workspaceActive
            }

            MouseArea {
                anchors.fill: parent
                onPositionChanged: mouse => root.applyPos(mouse.y)
                onPressed: mouse => root.applyPos(mouse.y)
            }

            Text {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: -2
                text: Math.round(root.volume * 100) + "%"
                color: WallustColors.moduleText
                font.family: SamaelStyle.fontFamily
                font.pixelSize: 9
            }
        }
    }

    function applyPos(y) {
        const h = faderHeight
        const norm = 1 - Math.max(0, Math.min(1, y / h))
        root.volumeCommitted(norm)
    }
}