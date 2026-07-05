import QtQuick
import qs.modules.samael

Rectangle {
    color: Qt.rgba(0.08, 0.09, 0.12, 1)
    border.color: SamaelStyle.borderColor
    radius: 4
    implicitWidth: 280
    implicitHeight: 280

    property string placeholderKey: ""
    property string weatherLine: ""

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8
        Text {
            text: placeholderKey.toUpperCase()
            font.family: SamaelStyle.fontFamily
            font.pixelSize: 11
            font.bold: true
            color: "#1a8cff"
        }
        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            font.family: SamaelStyle.fontFamily
            font.pixelSize: 10
            color: SamaelStyle.textColor
            text: {
                switch (placeholderKey) {
                case "audio":
                    return "Default I/O, streams, routing — batch 5."
                case "network":
                    return "Wi‑Fi list — batch 4."
                case "weather":
                    return weatherLine.length ? weatherLine : "WeatherWrap."
                case "display":
                    return "Brightness — batch 4."
                case "theme":
                    return "Wallpaper / Wallust — batch 3."
                default:
                    return "Coming soon."
                }
            }
        }
    }
}