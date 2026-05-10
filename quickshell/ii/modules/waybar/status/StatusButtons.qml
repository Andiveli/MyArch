import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

/**
 * Status buttons: Power, Lock, Keyboard layout - Waybar style
 */
RowLayout {
    id: root
    spacing: 2

    readonly property color colPower: "#f5c2e7"   // Pink
    readonly property color colLock: "#f9e2af"   // Yellow
    readonly property color colKeyboard: "#89b4fa" // Blue
    readonly property color colText: "#e5d9f5"

    // Power button
    Item {
        id: powerButton
        implicitWidth: powerLayout.implicitWidth + 8
        implicitHeight: Appearance.sizes.barHeight

        RowLayout {
            id: powerLayout
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            MaterialSymbol {
                text: "power_settings_new"
                iconSize: Appearance.font.pixelSize.normal
                color: root.colPower
            }
        }

        TapHandler {
            onTapped: {
                // Show power menu
                Quickshell.execDetached(["bash", "-c", "$HOME/.config/hypr/scripts/Wlogout.sh"])
            }
        }
    }

    // Lock button
    Item {
        id: lockButton
        implicitWidth: lockLayout.implicitWidth + 8
        implicitHeight: Appearance.sizes.barHeight

        RowLayout {
            id: lockLayout
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            MaterialSymbol {
                text: "lock"
                iconSize: Appearance.font.pixelSize.normal
                color: root.colLock
            }
        }

        TapHandler {
            onTapped: {
                Quickshell.execDetached(["bash", "-c", "$HOME/.config/hypr/scripts/LockScreen.sh"])
            }
        }
    }

    // Keyboard layout indicator
    Item {
        id: keyboardButton
        implicitWidth: keyboardLayout.implicitWidth + 8
        implicitHeight: Appearance.sizes.barHeight

        readonly property string layout: HyprlandXkb.currentLayout

        RowLayout {
            id: keyboardLayout
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            MaterialSymbol {
                text: "keyboard"
                iconSize: Appearance.font.pixelSize.normal
                color: root.colKeyboard
            }

            StyledText {
                text: keyboardButton.layout?.toUpperCase() || "US"
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: root.colText
            }
        }

        TapHandler {
            onTapped: {
                HyprlandXkb.switchToNextLayout()
            }
        }
    }
}
