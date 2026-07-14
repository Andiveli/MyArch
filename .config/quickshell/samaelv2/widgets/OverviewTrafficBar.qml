import QtQuick
import "../singletons"

/** Load bar: smooth green → yellow → red gradient along the filled width. */
Item {
    id: root

    property real fraction: 0
    property real trackOpacity: 0.12
    property int barRadius: 3

    readonly property real frac01: Math.max(0, Math.min(1, isNaN(fraction) ? 0 : fraction))

    readonly property color stopGreen: WallustColors.teal
    readonly property color stopYellow: WallustColors.yellow
    readonly property color stopRed: WallustColors.red

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

    Item {
        height: parent.height
        width: parent.width * root.displayFrac
        clip: true

        Rectangle {
            width: parent.parent.width
            height: parent.height
            radius: root.barRadius

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: root.stopGreen }
                GradientStop {
                    position: 0.35
                    color: Qt.rgba(
                        (root.stopGreen.r + root.stopYellow.r) / 2,
                        (root.stopGreen.g + root.stopYellow.g) / 2,
                        (root.stopGreen.b + root.stopYellow.b) / 2, 1)
                }
                GradientStop { position: 0.5; color: root.stopYellow }
                GradientStop {
                    position: 0.72
                    color: Qt.rgba(
                        (root.stopYellow.r + root.stopRed.r) / 2,
                        (root.stopYellow.g + root.stopRed.g) / 2,
                        (root.stopYellow.b + root.stopRed.b) / 2, 1)
                }
                GradientStop { position: 1.0; color: root.stopRed }
            }
        }
    }
}