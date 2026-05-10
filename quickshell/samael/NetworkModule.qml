import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Módulo de network WiFi con señal dinámica - estilo Waybar
 */
Item {
    id: root

    property int signalStrength: 0
    property bool connected: false
    property string icon: "󰤯"
    property string tooltipText: "Sin conexión"

    readonly property var icons: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]

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
        text: icon
        font.pixelSize: 14
        font.family: "JetBrainsMono Nerd Font"
        color: "#b700ff"
    }

    // Tooltip
    MouseArea {
        id: tooltipArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["bash", "-c", "nmcli device wifi toggle"])

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
        interval: 2000
        running: true
        repeat: true
        onTriggered: checkWifi.running = true
    }

    Process {
        id: checkWifi
        running: false
        command: ["bash", "-c", "\
iw dev wlan0 link 2>/dev/null | grep 'signal' | awk '{print $2}' | tr -d 'dBm' || echo '-100'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const signal = parseInt(this.text.trim())
                if (signal > -100) {
                    root.connected = true
                    if (signal >= -50) root.signalStrength = 4
                    else if (signal >= -60) root.signalStrength = 3
                    else if (signal >= -70) root.signalStrength = 2
                    else if (signal >= -80) root.signalStrength = 1
                    else root.signalStrength = 0
                    root.icon = icons[root.signalStrength]
                    root.tooltipText = "WiFi: " + signal + " dBm"
                } else {
                    root.connected = false
                    root.signalStrength = 0
                    root.icon = icons[0]
                    root.tooltipText = "Sin conexión"
                }
            }
        }
    }
}
