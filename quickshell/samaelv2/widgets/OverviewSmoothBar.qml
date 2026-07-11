import QtQuick
import "../singletons"

/** Horizontal fill bar with smooth width animation. */
Item {
    id: root

    property real fraction: 0
    property color fillColor: WallustColors.accent
    property real trackOpacity: 0.1
    property int barRadius: 3

    readonly property real frac01: Math.max(0, Math.min(1, isNaN(fraction) ? 0 : fraction))

    property real displayFrac: frac01
    Behavior on displayFrac {
        NumberAnimation { duration: 520; easing.type: Easing.OutCubic }
    }
    onFrac01Changed: displayFrac = frac01

    implicitHeight: 6

    Rectangle {
        anchors.fill: parent
        radius: root.barRadius
        color: Qt.rgba(WallustColors.moduleText.r, WallustColors.moduleText.g,
            WallustColors.moduleText.b, root.trackOpacity)
    }
    Rectangle {
        height: parent.height
        width: parent.width * root.displayFrac
        radius: root.barRadius
        color: root.fillColor
    }
}