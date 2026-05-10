import QtQuick

/**
 * Módulo de reloj/hora - estilo Waybar Samael
 */
Item {
    id: root

    readonly property string time: new Date().toLocaleTimeString(Qt.locale("es_ES"), "HH:mm:ss")
    readonly property string date: new Date().toLocaleDateString(Qt.locale("es_ES"), "dddd, d MMMM yyyy")
    property string tooltipText: date

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
            text: ""
            font.pixelSize: 14
            font.family: "JetBrainsMono Nerd Font"
            color: "#fe640b"
        }

        Text {
            text: root.time
            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"
            color: "#fe640b"
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
    }
}
