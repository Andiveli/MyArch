import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.samael

Item {
    id: root
    implicitWidth: hit.implicitWidth
    implicitHeight: hit.implicitHeight

    property int count: 0
    property bool dnd: false

    SamaelBarButton {
        id: hit
        text: root.dnd ? "" : ""
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton)
                Quickshell.execDetached("swaync-client -d -sw")
            else
                Quickshell.execDetached("swaync-client -t -sw")
        }
    }

    Text {
        visible: root.count > 0 && !root.dnd
        text: ""
        color: "#ff0000"
        font.family: SamaelStyle.fontFamily
        font.pixelSize: 8
        z: 2
        anchors {
            top: hit.top
            right: hit.right
            topMargin: -2
            rightMargin: -2
        }
    }

    Process {
        id: fetchProcess
        command: ["swaync-client", "-swb"]
        stdout: SplitParser {
            onRead: (data) => {
                try {
                    const state = JSON.parse(data.trim())
                    root.count = state.count || 0
                    root.dnd = state.dnd || false
                } catch (e) { }
            }
        }
        running: true
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            fetchProcess.running = false
            fetchProcess.running = true
        }
    }
}
