pragma Singleton
import QtQuick

/** Pill-style timing (see ../pill/ANIMATION.md). */
QtObject {
    readonly property real mult: 1
    readonly property int fast: Math.round(140 * mult)
    readonly property int standard: Math.round(300 * mult)
    readonly property int morph: Math.round(420 * mult)
    readonly property int easeMorph: Easing.BezierSpline
    readonly property var morphCurve: [0.16, 1, 0.3, 1, 1, 1]
}