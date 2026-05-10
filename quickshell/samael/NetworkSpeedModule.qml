import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Módulo de velocidad de red - estilo Waybar
 */
Item {
    id: root

    property string downSpeed: "0 B"
    property string upSpeed: "0 B"
    property string icon: "󰌘"
    property string tooltipText: "↓ 0 B/s · ↑ 0 B/s"

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
        spacing: 4

        Text {
            text: icon
            font.pixelSize: 14
            font.family: "JetBrainsMono Nerd Font"
            color: "#b700ff"
        }

        Text {
            text: "↓ " + downSpeed
            font.pixelSize: 11
            font.family: "JetBrainsMono Nerd Font"
            color: "#e5d9f5"
        }

        Text {
            text: "↑ " + upSpeed
            font.pixelSize: 11
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
        interval: 1000
        running: true
        repeat: true
        onTriggered: checkSpeed.running = true
    }

    Process {
        id: checkSpeed
        running: false
        command: ["bash", "-c", "\
read up1 </sys/class/net/wlan0/statistics/tx_bytes 2>/dev/null || echo 0; \
read down1 </sys/class/net/wlan0/statistics/rx_bytes 2>/dev/null || echo 0; \
sleep 1; \
read up2 </sys/class/net/wlan0/statistics/tx_bytes 2>/dev/null || echo 0; \
read down2 </sys/class/net/wlan0/statistics/rx_bytes 2>/dev/null || echo 0; \
up_diff=$((up2 - up1)); down_diff=$((down2 - down1)); \
echo $up_diff $down_diff"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split(" ")
                if (parts.length >= 2) {
                    const up = parseInt(parts[0]) || 0
                    const down = parseInt(parts[1]) || 0
                    root.upSpeed = formatBytes(up)
                    root.downSpeed = formatBytes(down)
                    root.tooltipText = "↓ " + formatBytes(down) + "/s · ↑ " + formatBytes(up) + "/s"
                }
            }
        }
    }

    function formatBytes(bytes) {
        if (bytes < 1024) return bytes + " B"
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " K"
        return (bytes / (1024 * 1024)).toFixed(1) + " M"
    }
}
