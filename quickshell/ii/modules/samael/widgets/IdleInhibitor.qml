import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.modules.samael

Item {
    id: root
    implicitWidth: hit.implicitWidth
    implicitHeight: hit.implicitHeight

    property bool inhibiting: false

    SamaelBarButton {
        id: hit
        text: root.inhibiting ? "\uf06e" : "\uf070"
        normalColor: root.inhibiting ? WallustColors.idleActive : WallustColors.idleInactive
        onClicked: () => {
            Hyprland.dispatch("hypridle", "toggle")
            root.inhibiting = !root.inhibiting
        }
    }

    Process {
        id: statusProcess
        command: ["hyprctl", "hypridle"]
        stdout: SplitParser {
            onRead: (data) => {
                root.inhibiting = data.trim().toLowerCase().includes("inhibited")
            }
        }
        running: true
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            statusProcess.running = false
            statusProcess.running = true
        }
    }
}
