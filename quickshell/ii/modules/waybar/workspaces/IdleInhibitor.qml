import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

/**
 * Idle inhibitor indicator - Waybar style
 * Shows sun icon when active, moon when inactive
 */
Item {
    id: root
    implicitWidth: rowLayout.implicitWidth + 8
    implicitHeight: Appearance.sizes.barHeight

    readonly property bool isActive: Idle.inhibit

    readonly property color colActive: "#39ff14"  // Green
    readonly property color colInactive: "#1a1a2e" // Dark blue/gray

    RowLayout {
        id: rowLayout
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        MaterialSymbol {
            text: isActive ? "light_mode" : "bedtime"
            iconSize: Appearance.font.pixelSize.normal
            color: isActive ? root.colActive : Appearance.colors.colOnLayer0
        }
    }

    TapHandler {
        onTapped: {
            Idle.toggleInhibit()
        }
    }
}
