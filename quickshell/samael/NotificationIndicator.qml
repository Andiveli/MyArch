import QtQuick
import Quickshell.Io

/**
 * Módulo de notificaciones - estilo Waybar Samael
 */
Item {
    id: root

    property int unreadCount: 0
    property string tooltipText: "Sin notificaciones"

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
            text: ""
            font.pixelSize: 14
            font.family: "JetBrainsMono Nerd Font"
            color: "#ffd700"
        }

        Text {
            text: `${unreadCount}`
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
        onClicked: Quickshell.execDetached(["swaync-client", "-t", "-sw"])

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
        onTriggered: checkNotifications.running = true
    }

    Process {
        id: checkNotifications
        running: false
        command: ["bash", "-c", "swaync-client -c 2>/dev/null | grep -o '[0-9]*' | head -1 || echo '0'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const count = parseInt(this.text.trim()) || 0
                root.unreadCount = count
                root.tooltipText = count === 0 ? "Sin notificaciones" : `${count} notificaciones`
            }
        }
    }
}
