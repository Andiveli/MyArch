import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Módulo de Tray - estilo Waybar
 */
Item {
    id: root

    property int itemCount: 0
    property string tooltipText: "Bandeja del sistema"

    implicitWidth: 28
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

    Text {
        anchors.centerIn: parent
        text: "󰅬"
        font.pixelSize: 14
        font.family: "JetBrainsMono Nerd Font"
        color: "#89b4fa"
    }

    // Tooltip
    MouseArea {
        id: tooltipArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["wtype", "-P", "super+v"])

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
