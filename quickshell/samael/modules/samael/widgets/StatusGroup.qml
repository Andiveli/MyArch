import QtQuick
import qs.modules.samael
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common
import qs.services

Item {
    id: root
    implicitWidth: mainBtn.implicitWidth
    implicitHeight: mainBtn.implicitHeight

        property bool drawerOpen: false
        property int barNavIndex: 7
        readonly property bool barNavFocused: GlobalStates.samaelBarNavActive
            && GlobalStates.samaelBarFocus === barNavIndex
    property bool capsLockOn: false
    property int drawerWidth: 200

    function abbreviateLayoutCode(fullCode) {
        return fullCode.split(':').map(layout => layout.split('-')[0].slice(0, 4)).join('/')
    }

    Row {
        id: mainBtn

        Text {
            id: powerIcon
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: SamaelStyle.fontPixelSize
            color: WallustColors.moduleText
            text: "⏻"
        }
    }

    Process {
        id: capsProc
        command: ["bash", "-c", "xset q 2>/dev/null | grep -q 'Caps Lock:   on' && echo on || echo off"]
        stdout: SplitParser {
            onRead: (data) => { root.capsLockOn = data.trim() === "on" }
        }
    }

    Timer {
        interval: 3000
        running: GlobalStates.barOpen
        repeat: true
        onTriggered: {
            capsProc.running = false
            capsProc.running = true
        }
    }

    Rectangle {
        id: drawer
        anchors {
            top: mainBtn.bottom
            topMargin: 2
            right: root.right
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
                right: parent.right
                rightMargin: 6
            }
            spacing: 10

            StatusAction {
                icon: "⏻"
                action: () => GlobalStates.sessionOpen = true
            }
            StatusAction {
                icon: "󰌾"
                action: () => Quickshell.execDetached(["hyprlock"])
            }
            Text {
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: SamaelStyle.fontPixelSize
                color: root.capsLockOn ? WallustColors.workspaceActive : WallustColors.moduleText
                text: root.capsLockOn ? "󰪛" : "󰪚"
            }
            Text {
                visible: HyprlandXkb.layoutCodes.length > 0
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: SamaelStyle.fontPixelSize
                color: WallustColors.moduleText
                text: root.abbreviateLayoutCode(HyprlandXkb.currentLayoutCode)
            }
        }
    }

    component StatusAction: MouseArea {
        property string icon
        property var action
        implicitWidth: label.implicitWidth + 8
        implicitHeight: label.implicitHeight + 4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (action) action()

        Text {
            id: label
            anchors.centerIn: parent
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: SamaelStyle.fontPixelSize
            color: WallustColors.moduleText
            text: parent.icon
        }
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

    MouseArea {
        anchors.fill: mainBtn
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: GlobalStates.sessionOpen = true
    }
}
