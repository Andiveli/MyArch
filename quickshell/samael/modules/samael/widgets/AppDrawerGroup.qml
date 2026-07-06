import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.samael

// Waybar group/app_drawer: solo menú; hijos al hover (transition-left-to-right, 500ms)
Item {
    id: root
    property bool expanded: false
    property int barNavIndex: 0
    readonly property bool barNavFocused: GlobalStates.samaelBarNavActive
&& GlobalStates.samaelBarFocus === barNavIndex

    readonly property int drawerDuration: 500
    readonly property real stripHeight: Math.max(menuButton.implicitHeight, drawerRow.implicitHeight)

    implicitHeight: stripHeight
    implicitWidth: menuButton.implicitWidth + drawerClip.width
    width: implicitWidth
    height: stripHeight

    // Hover sin bloquear clics (no usar MouseArea encima de los botones)
    HoverHandler {
        id: groupHover
        onHoveredChanged: root.expanded = groupHover.hovered
    }

    SamaelBarButton {
        id: menuButton
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        z: 1
        text: ""
        onClicked: () => Quickshell.execDetached("rofi -show drun -modi run,drun,filebrowser,window")
    }

    Rectangle {
        anchors.left: menuButton.left
        anchors.verticalCenter: menuButton.verticalCenter
        width: menuButton.implicitWidth + 4
        height: menuButton.implicitHeight + 4
        radius: 8
        color: "transparent"
        border.width: root.barNavFocused ? 2 : 0
        border.color: WallustColors.workspaceActive
        z: 2
        visible: root.barNavFocused
    }

    Item {
        id: drawerClip
        z: 1
        anchors.left: menuButton.right
        anchors.verticalCenter: parent.verticalCenter
        height: drawerRow.implicitHeight
        width: root.expanded ? drawerRow.implicitWidth : 0
        clip: true

        Behavior on width {
            NumberAnimation {
                duration: root.drawerDuration
                easing.type: Easing.OutCubic
            }
        }

        RowLayout {
            id: drawerRow
            spacing: SamaelStyle.moduleRowSpacing
            height: implicitHeight

            AppIconButton {
                glyph: "󰔎"
                onActivated: () => Quickshell.execDetached("bash -c '$HOME/.config/hypr/scripts/DarkLight.sh'")
            }
            AppIconButton {
                glyph: ""
                onActivated: () => Quickshell.execDetached("bash -c '$HOME/.config/hypr/scripts/WaybarScripts.sh --files'")
            }
            AppIconButton {
                glyph: ""
                onActivated: () => Quickshell.execDetached("bash -c '$HOME/.config/hypr/scripts/WaybarScripts.sh --term'")
            }
            AppIconButton {
                glyph: ""
                onActivated: () => Quickshell.execDetached("xdg-open https://")
            }
            AppIconButton {
                glyph: ""
                onActivated: () => Quickshell.execDetached("bash -c '$HOME/.config/hypr/scripts/Kool_Quick_Settings.sh'")
            }
        }
    }

    component AppIconButton: SamaelBarButton {
        property string glyph
        text: glyph
        property var onActivated
        onClicked: () => onActivated()
    }
}