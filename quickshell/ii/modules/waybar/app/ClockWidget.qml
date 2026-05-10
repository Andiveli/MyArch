import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

/**
 * Clock widget - Waybar style
 * Shows time with seconds
 */
Item {
    id: root
    implicitWidth: clockLayout.implicitWidth + 16
    implicitHeight: Appearance.sizes.barHeight

    readonly property color colClock: "#fe640b"    // Orange
    readonly property color colText: "#e5d9f5"

    readonly property string timeString: DateTime.time

    RowLayout {
        id: clockLayout
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        // Clock icon
        MaterialSymbol {
            text: "schedule"
            iconSize: Appearance.font.pixelSize.normal
            color: root.colClock
        }

        // Time
        StyledText {
            text: root.timeString
            font.pixelSize: Appearance.font.pixelSize.normal
            font.weight: Font.Bold
            color: root.colText
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
    }
}
