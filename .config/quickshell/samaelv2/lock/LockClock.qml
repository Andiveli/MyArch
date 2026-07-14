import QtQuick
import "../singletons"

/** Caelestia lock clock: hours (sapphire) + minutes (mauve). */
Item {
    id: root

    required property real contentScale

    readonly property real s: Math.max(0.85, Style.fontPixelSize / 11)
    readonly property string hourStr: Qt.formatDateTime(clockDate, "HH")
    readonly property string minuteStr: Qt.formatDateTime(clockDate, "mm")
    property var clockDate: new Date()

    implicitWidth: hours.implicitWidth + minutes.implicitWidth + 6 * s
    implicitHeight: Math.max(hours.implicitHeight, minutes.implicitHeight)

    Text {
        id: hours
        text: root.hourStr
        color: WallustColors.sapphire
        font.family: Style.fontFamily
        font.pixelSize: Math.round((42 + 14 * contentScale) * s)
        font.bold: true
        font.features: { "tnum": 1 }
    }

    Text {
        id: minutes
        anchors.left: hours.right
        anchors.leftMargin: 6 * s
        anchors.baseline: hours.baseline
        text: root.minuteStr
        color: WallustColors.mauve
        font.family: Style.fontFamily
        font.pixelSize: Math.round((42 + 14 * contentScale) * s)
        font.bold: true
        font.features: { "tnum": 1 }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.clockDate = new Date()
    }
}