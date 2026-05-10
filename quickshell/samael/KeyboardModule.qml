import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Módulo de keyboard layout - estilo Waybar
 */
Item {
    id: root

    property string layout: "US"
    property string icon: "󰌌"
    property string tooltipText: "Keyboard: US"

    readonly property var layouts: {
        "us": "US",
        "jp": "JP",
        "ara": "AR",
        "es": "ES",
        "fr": "FR",
        "de": "DE"
    }

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
            text: icon
            font.pixelSize: 14
            font.family: "JetBrainsMono Nerd Font"
            color: "#7da6ff"
        }

        Text {
            text: layout
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
        onClicked: toggleLayout()

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
        onTriggered: checkLayout.running = true
    }

    Process {
        id: checkLayout
        running: false
        command: ["bash", "-c", "\
setxkbmap -query 2>/dev/null | grep layout | awk '{print $2}' | head -1 || \
hyprctl devices | grep 'keyboard' -A5 | grep 'layout' | awk '{print $2}' | head -1 || \
echo 'us'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = this.text.trim().toLowerCase()
                root.layout = layouts[l] || l.toUpperCase()
                root.tooltipText = "Keyboard: " + (layouts[l] || l.toUpperCase())
            }
        }
    }

    function toggleLayout() {
        Quickshell.execDetached(["bash", "-c", "hyprctl switchxkblayout all next"])
    }
}
