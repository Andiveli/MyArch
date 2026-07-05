import QtQuick
import qs
import qs.services
import qs.modules.samael

// Quickshell Notifications — Samael menu (replaces swaync / II sidebar)
Item {
    id: root
    property int barNavIndex: 4
    readonly property bool barNavFocused: GlobalStates.samaelBarNavActive
&& GlobalStates.samaelBarFocus === barNavIndex
    implicitWidth: hit.implicitWidth
    implicitHeight: hit.implicitHeight

    Rectangle {
        anchors.fill: hit
        radius: 8
        color: "transparent"
        border.width: root.barNavFocused ? 2 : 0
        border.color: WallustColors.workspaceActive
        z: 3
        visible: root.barNavFocused
    }

    SamaelBarButton {
        id: hit
        normalColor: WallustColors.notificationIcon
        text: Notifications.silent ? "" : ""
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton)
                Notifications.silent = !Notifications.silent
            else {
                GlobalStates.samaelWifiMenuOpen = false
                GlobalStates.samaelBluetoothMenuOpen = false
                GlobalStates.samaelNotificationsMenuOpen = !GlobalStates.samaelNotificationsMenuOpen
            }
        }
    }

    Text {
        visible: !Notifications.silent && Notifications.unread > 0
        text: ""
        color: WallustColors.notificationBadge
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
}