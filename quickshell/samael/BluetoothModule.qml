import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Módulo de bluetooth - estilo Waybar
 */
Item {
    id: root

    property bool enabled: false
    property bool connected: false
    property string tooltipText: "Bluetooth: off"

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
            text: connected ? "󰂱" : (enabled ? "󰂳" : "󰂲")
            font.pixelSize: 14
            font.family: "JetBrainsMono Nerd Font"
            color: "#7da6ff"
        }

        Text {
            text: connected ? "on" : (enabled ? "on" : "off")
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
        onClicked: Quickshell.execDetached(["bash", "-c", "bluetoothctl power toggle"])

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

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: checkBt.running = true
    }

    Process {
        id: checkBt
        running: false
        command: ["bash", "-c", "bluetoothctl show 2>/dev/null | grep 'Powered:' | awk '{print $2}' || echo 'no'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const powered = this.text.trim()
                root.enabled = (powered === "yes")
                root.tooltipText = root.enabled ? "Bluetooth: on" : "Bluetooth: off"
            }
        }
    }
}
