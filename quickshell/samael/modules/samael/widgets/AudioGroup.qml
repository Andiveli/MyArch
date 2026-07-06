import QtQuick
import qs.modules.samael
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common
import qs.services

Item {
    id: root
    implicitWidth: mainBtn.implicitWidth
    implicitHeight: mainBtn.implicitHeight

        property bool drawerOpen: false
        property int drawerWidth: 200
        property int barNavIndex: 6

        function toggleDrawer() {
            root.drawerOpen = !root.drawerOpen
        }

        readonly property bool barNavFocused: GlobalStates.samaelBarNavActive
            && GlobalStates.samaelBarFocus === barNavIndex

    function sinkIcon(): string {
        const muted = Audio.sink?.audio?.muted ?? true
        if (muted)
            return "󰖁"
        const v = Audio.value
        if (v <= 0) return "󰖁"
        if (v < 0.34) return "󰕿"
        if (v < 0.67) return "󰖀"
        return "󰕾"
    }

    function sourceIcon(): string {
        const muted = Audio.source?.audio?.muted ?? false
        if (muted)
            return "󰍭"
        return "󰍬"
    }

    function volumePercent(): int {
        return Math.round((Audio.sink?.audio?.volume ?? 0) * 100)
    }

    function micPercent(): int {
        return Math.round((Audio.source?.audio?.volume ?? 0) * 100)
    }

    Rectangle {
        anchors.fill: mainBtn
        radius: 8
        color: "transparent"
        border.width: root.barNavFocused ? 2 : 0
        border.color: WallustColors.workspaceActive
        z: 5
        visible: root.barNavFocused
    }

    Row {
        id: mainBtn
        spacing: 2

        Text {
            id: volIcon
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: SamaelStyle.fontPixelSize
            color: WallustColors.moduleText
            text: root.sinkIcon()
        }

        Text {
            id: volText
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: SamaelStyle.fontPixelSize
            color: WallustColors.moduleText
            text: root.volumePercent() + "%"
        }
    }

    Rectangle {
        id: drawer
        anchors {
            top: mainBtn.bottom
            topMargin: 2
            left: root.left
        }
        width: root.drawerWidth
        height: root.drawerOpen ? drawerRow.implicitHeight + 8 : 0
        radius: 8
        color: Qt.rgba(0, 0, 0, 0.6)
        opacity: root.drawerOpen ? 1 : 0
        clip: true
        z: 100

        Behavior on height {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: 100 }
        }

        RowLayout {
            id: drawerRow
            anchors {
                top: parent.top
                topMargin: 4
                left: parent.left
                leftMargin: 6
            }
            spacing: 8

            Text {
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: SamaelStyle.fontPixelSize
                color: WallustColors.moduleText
                text: root.sourceIcon() + " " + root.micPercent() + "%"
            }

            MouseArea {
                implicitWidth: micToggle.implicitWidth + 8
                implicitHeight: micToggle.implicitHeight + 4
                onClicked: Audio.toggleMicMute()

                Text {
                    id: micToggle
                    anchors.centerIn: parent
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: SamaelStyle.fontPixelSize
                    color: WallustColors.moduleText
                    text: (Audio.source?.audio?.muted ?? false) ? "󰍭" : "󰍬"
                }
            }
        }
    }

    MouseArea {
        anchors.fill: volIcon
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Audio.toggleMute()
    }

    MouseArea {
        anchors.fill: volText
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton)
                Quickshell.execDetached(["bash", "-c", Config.options.apps.volumeMixer])
            else
                root.drawerOpen = !root.drawerOpen
        }
    }

    WheelHandler {
        target: mainBtn
        onWheel: (event) => {
            if (event.angleDelta.y > 0)
                Audio.incrementVolume()
            else if (event.angleDelta.y < 0)
                Audio.decrementVolume()
            event.accepted = true
        }
    }

    function refreshVolumeLabel() {
        volIcon.text = root.sinkIcon()
        volText.text = root.volumePercent() + "%"
    }

    Connections {
        target: Audio.sink?.audio
        function onVolumeChanged() { root.refreshVolumeLabel() }
        function onMutedChanged() { root.refreshVolumeLabel() }
    }

    Component.onCompleted: {
refreshVolumeLabel()
SamaelBarNavHub.audio = root
    }
    Component.onDestruction: {
if (SamaelBarNavHub.audio === root)
SamaelBarNavHub.audio = null
    }
}
