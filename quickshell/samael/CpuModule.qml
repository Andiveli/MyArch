import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Módulo de CPU + Power Profile
 */
Item {
    id: root

    readonly property string profileIcon: {
        if (profile === "performance") return "⚡"
        if (profile === "power-saver") return "🔋"
        return "⚖️"
    }

    readonly property string profileColor: {
        if (profile === "performance") return "#ff5349"
        if (profile === "power-saver") return "#89b4fa"
        return "#cba6f7"
    }

    property string profile: "balanced"

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
            text: "󰍛"
            font.pixelSize: 14
            font.family: "JetBrainsMono Nerd Font"
            color: "#cba6f7"
        }

        Text {
            text: `${Math.round(ResourceUsage.cpuUsage * 100)}%`
            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"
            color: "#9d6fbf"
        }

        Text {
            text: root.profileIcon
            font.pixelSize: 14
            font.family: "JetBrainsMono Nerd Font"
            color: root.profileColor
        }
    }

    MouseArea {
        id: tooltipArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            if (PowerProfiles.available) {
                PowerProfiles.cycleProfile()
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
                text: PowerProfiles.available ? "Click: cambiar profile" : "No disponible"
                font.pixelSize: 11
                font.family: "JetBrainsMono Nerd Font"
                color: "#e5d9f5"
            }

            Behavior on opacity { NumberAnimation { duration: 150 } }
            opacity: parent.containsMouse ? 1 : 0
        }
    }

    Component.onCompleted: {
        if (PowerProfiles.available) {
            root.profile = PowerProfiles.currentProfile
        }
    }

    Connections {
        target: PowerProfiles
        function onCurrentProfileChanged() {
            root.profile = PowerProfiles.currentProfile
        }
    }
}
