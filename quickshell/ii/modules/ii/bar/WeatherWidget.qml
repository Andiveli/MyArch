import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

/**
 * Weather widget - Waybar style
 */
Item {
    id: root
    implicitWidth: weatherLayout.implicitWidth + 8
    implicitHeight: Appearance.sizes.barHeight

    readonly property color colWeather: "#df8e1d"  // Orange
    readonly property color colText: "#e5d9f5"

    readonly property string weatherText: Weather.current?.description || "───"
    readonly property double temperature: Weather.current?.temperature || 0

    RowLayout {
        id: weatherLayout
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        // Weather icon
        MaterialSymbol {
            text: Weather.getWeatherIcon()
            iconSize: Appearance.font.pixelSize.normal
            color: root.colWeather
        }

        // Temperature
        StyledText {
            text: `${Math.round(temperature)}°`
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: root.colText
        }

        // Weather description
        StyledText {
            text: weatherText
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: root.colText
            visible: weatherText.length > 0 && weatherText !== "───"
        }
    }

    TapHandler {
        onTapped: {
            // Refresh weather
            Weather.refresh()
        }
    }
}
