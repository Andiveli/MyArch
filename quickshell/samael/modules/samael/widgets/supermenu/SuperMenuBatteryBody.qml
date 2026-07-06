import QtQuick
import Quickshell.Io
import qs
import qs.services
import qs.modules.samael

Rectangle {
    color: "transparent"
    implicitWidth: 480
    implicitHeight: 220

    property string currentProfile: ""
    property int focusIndex: 0
    readonly property var profiles: ["power-saver", "balanced", "performance"]

    function handleKey(event): bool {
        if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
            focusIndex = Math.min(profiles.length - 1, focusIndex + 1)
            event.accepted = true
            return true
        }
        if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
            focusIndex = Math.max(0, focusIndex - 1)
            event.accepted = true
            return true
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            setProfileProc.command = ["powerprofilesctl", "set", profiles[focusIndex]]
            setProfileProc.running = true
            event.accepted = true
            return true
        }
        return false
    }

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8
        Text {
            text: "POWER PROFILE"
            font.family: SamaelStyle.fontFamily
            font.pixelSize: 11
            font.bold: true
            color: "#1a8cff"
        }
        Text {
            text: Battery.available ? `${Math.round(Battery.percentage * 100)}% battery` : "No battery"
            font.family: SamaelStyle.fontFamily
            font.pixelSize: 10
            color: SamaelStyle.textColor
        }
        Text {
            text: "Active: " + (currentProfile || "…")
            font.family: SamaelStyle.fontFamily
            font.pixelSize: 9
            color: Qt.rgba(1, 1, 1, 0.6)
        }
        Repeater {
            model: profiles
            delegate: Rectangle {
                required property int index
                required property string modelData
                width: parent.width
                height: 26
                color: root.focusIndex === index ? Qt.rgba(0.1, 0.45, 1, 0.2) : "transparent"
                border.width: currentProfile === modelData ? 1 : (root.focusIndex === index ? 1 : 0)
                border.color: "#1a8cff"
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData
                    font.family: SamaelStyle.fontFamily
                    font.pixelSize: 10
                    color: SamaelStyle.textColor
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.focusIndex = index
                        setProfileProc.command = ["powerprofilesctl", "set", modelData]
                        setProfileProc.running = true
                    }
                }
            }
        }
    }

    Process {
        id: getProfileProc
        running: true
        command: ["powerprofilesctl", "get"]
        stdout: SplitParser {
            onRead: data => { root.currentProfile = data.trim() }
        }
    }

    Process {
        id: setProfileProc
        onExited: getProfileProc.running = true
    }
}