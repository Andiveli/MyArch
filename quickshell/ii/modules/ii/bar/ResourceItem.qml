import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

/**
 * Simple resource item with icon and percentage - Waybar style
 */
Item {
    id: root
    property string iconName
    property double percentage
    property color iconColor: Appearance.colors.colOnSecondaryContainer
    property color textColor: Appearance.colors.colOnLayer1
    property bool showPercentage: true
    property int iconSize: Appearance.font.pixelSize.normal

    implicitWidth: rowLayout.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    RowLayout {
        id: rowLayout
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        MaterialSymbol {
            text: iconName
            iconSize: root.iconSize
            color: root.iconColor
        }

        StyledText {
            visible: showPercentage
            text: `${Math.round(percentage * 100)}%`
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: root.textColor
        }
    }

    TapHandler {
        onTapped: {
            // Optional: show popup with more info
        }
    }
}
