import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Módulo de RAM - click para cambiar entre % y GB
 */
Item {
    id: root

    property bool showPercentage: true

    readonly property string usedGb: ResourceUsage.memoryUsedGb.toFixed(1) + "G"
    readonly property string totalGb: (ResourceUsage.memoryTotal / (1024 * 1024)).toFixed(1) + "G"
    readonly property string displayText: {
        if (showPercentage) {
            return Math.round(ResourceUsage.memoryUsedPercentage * 100) + "%"
        }
        return usedGb
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
        spacing: 4

        Text {
            text: "󰾆"
            font.pixelSize: 14
            font.family: "JetBrainsMono Nerd Font"
            color: "#ff00bf"
        }

        Text {
            text: root.displayText
            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"
            color: "#e5d9f5"
        }
    }

    MouseArea {
        id: tooltipArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            root.showPercentage = !root.showPercentage
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
                text: usedGb + "/" + totalGb
                font.pixelSize: 11
                font.family: "JetBrainsMono Nerd Font"
                color: "#e5d9f5"
            }

            Behavior on opacity { NumberAnimation { duration: 150 } }
            opacity: parent.containsMouse ? 1 : 0
        }
    }
}
