import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

/**
 * Network indicator with speed - Waybar style
 */
RowLayout {
    id: root
    spacing: 4

    readonly property color colIcon: "#b700ff"  // Purple
    readonly property color colText: "#e5d9f5" // Light text

    // Icon
    MaterialSymbol {
        text: NetworkSpeed.materialSymbol
        iconSize: Appearance.font.pixelSize.normal
        color: root.colIcon
    }

    // Network name
    StyledText {
        text: NetworkSpeed.networkName || "───"
        font.pixelSize: Appearance.font.pixelSize.smaller
        color: root.colText
        visible: NetworkSpeed.networkName.length > 0
    }

    // Speed indicator
    RowLayout {
        spacing: 2
        visible: NetworkSpeed.ethernet || NetworkSpeed.wifiEnabled

        // Download
        MaterialSymbol {
            text: "arrow_downward"
            iconSize: Appearance.font.pixelSize.smaller
            color: root.colIcon
        }

        StyledText {
            text: NetworkSpeed.bandwidthDown
            font.pixelSize: Appearance.font.pixelSize.tiny
            color: root.colText
        }

        // Upload
        MaterialSymbol {
            text: "arrow_upward"
            iconSize: Appearance.font.pixelSize.smaller
            color: root.colIcon
        }

        StyledText {
            text: NetworkSpeed.bandwidthUp
            font.pixelSize: Appearance.font.pixelSize.tiny
            color: root.colText
        }
    }

    TapHandler {
        onTapped: {
            // Toggle WiFi or show network menu
            Network.toggleWifi()
        }
    }
}
