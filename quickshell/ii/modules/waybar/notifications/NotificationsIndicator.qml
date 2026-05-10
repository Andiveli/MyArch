import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

/**
 * Notifications indicator (swaync style) - Waybar style
 */
Item {
    id: root
    implicitWidth: rowLayout.implicitWidth + 8
    implicitHeight: Appearance.sizes.barHeight

    readonly property int unreadCount: Notifications.unread
    readonly property bool isSilent: Notifications.silent

    RowLayout {
        id: rowLayout
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        // Bell icon
        MaterialSymbol {
            text: "notifications"
            iconSize: Appearance.font.pixelSize.normal
            color: isSilent ? Appearance.colors.colOnLayer0 : "#ffd700"
        }

        // Unread count badge
        Rectangle {
            visible: unreadCount > 0
            width: unreadCountText.implicitWidth + 6
            height: unreadCountText.implicitHeight + 2
            radius: 4
            color: "#ff0000"

            StyledText {
                id: unreadCountText
                anchors.centerIn: parent
                text: unreadCount > 99 ? "99+" : unreadCount.toString()
                font.pixelSize: Appearance.font.pixelSize.tiny
                color: "#ffffff"
            }
        }
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: {
            // Toggle notification center
            Quickshell.execDetached(["swaync-client", "-t", "-sw"])
        }
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: {
            // Toggle DND
            Quickshell.execDetached(["swaync-client", "-d", "-sw"])
        }
    }
}
