import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Módulo de Power (apagar) - estilo Waybar
 */
Item {
    id: root

    property string tooltipText: "Menú de apagado"

    implicitWidth: row.width + 20
    implicitHeight: 28

    clip: true

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        radius: 15
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: 2
        border.color: "#f700ff"
        radius: 15
    }

    Row {
        id: row
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            leftMargin: 10
        }
        spacing: 6

        Text {
            text: "⏻"
            font.pixelSize: 14
            font.family: "JetBrainsMono Nerd Font"
            color: "#f53c3c"
        }

        Text {
            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"
            color: "#e5d9f5"
        }
    }

    // Tooltip
    MouseArea {
        id: tooltipArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                Quickshell.execDetached(["bash", "-c", "$HOME/.config/hypr/scripts/Wlogout.sh"])
            }
        }

        Rectangle {
            visible: parent.containsMouse
            y: -35
            height: 24
            color: "#1a1a2e"
            radius: 6
            border.width: 1
            border.color: "#f700ff"
            anchors { horizontalCenter: parent.horizontalCenter }

            Text {
                anchors.centerIn: parent
                text: root.tooltipText
                font.pixelSize: 11
                font.family: "JetBrainsMono Nerd Font"
                color: "#e5d9f5"
            }

            Behavior on opacity { NumberAnimation { duration: 150 } }
            opacity: parent.containsMouse ? 1 : 0
        }
    }
}
