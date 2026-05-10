import QtQuick
import Quickshell
import Quickshell.Hyprland

/**
 * Módulo de workspaces con kanjis - estilo Waybar Samael
 * Usa eventos nativos de Hyprland (sin polling)
 */
Item {
    id: root

    readonly property var kanjiNumbers: ["一", "二", "三", "四", "五"]
    readonly property int activeWorkspace: Hyprland.focusedWorkspace?.id || 1
    readonly property string tooltipText: "Workspace " + activeWorkspace

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

        Repeater {
            model: 5

            delegate: Item {
                property int wsId: index + 1
                property bool isActive: root.activeWorkspace === wsId

                width: 20
                height: 28

                Text {
                    id: text
                    anchors.centerIn: parent
                    text: root.kanjiNumbers[index]
                    font.pixelSize: 14
                    font.bold: true
                    font.family: "Droid Sans Japanese, DejaVu Sans, sans-serif"
                    color: isActive ? "#2600ff" : "#ff029e"
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("workspace " + wsId.toString())

                    Rectangle {
                        visible: parent.containsMouse
                        y: -25
                        height: 20
                        color: "#1a1a2e"
                        radius: 4
                        anchors { horizontalCenter: parent.horizontalCenter }

                        Text {
                            anchors.centerIn: parent
                            text: "Workspace " + wsId
                            font.pixelSize: 10
                            font.family: "JetBrainsMono Nerd Font"
                            color: "#e5d9f5"
                        }

                        opacity: parent.containsMouse ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 100 } }
                    }
                }
            }
        }
    }
}
