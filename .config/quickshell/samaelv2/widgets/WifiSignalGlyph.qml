import QtQuick
import QtQuick.Shapes
import "../singletons"

/** Wi‑Fi arcs (no Nerd Font) — level 0–100. */
Item {
    id: root
    property int level: 0
    property bool radioOn: true
    property color strokeColor: WallustColors.moduleText

    implicitWidth: 16
    implicitHeight: 16

    readonly property int litCount: !radioOn ? 0 : (level > 66 ? 3 : (level > 33 ? 2 : (level > 0 ? 1 : 0)))
    readonly property color dimColor: Qt.rgba(strokeColor.r, strokeColor.g, strokeColor.b, radioOn ? 0.28 : 0.14)

    readonly property real u: Math.min(width, height) / 24

    Shape {
        width: 24
        height: 24
        scale: root.u
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.litCount >= 1 ? root.strokeColor : root.dimColor
            fillColor: "transparent"
            strokeWidth: 2
            capStyle: ShapePath.RoundCap
            PathSvg { path: "M9.17 13.17 A4 4 0 0 1 14.83 13.17" }
        }
        ShapePath {
            strokeColor: root.litCount >= 2 ? root.strokeColor : root.dimColor
            fillColor: "transparent"
            strokeWidth: 2
            capStyle: ShapePath.RoundCap
            PathSvg { path: "M6.34 10.34 A8 8 0 0 1 17.66 10.34" }
        }
        ShapePath {
            strokeColor: root.litCount >= 3 ? root.strokeColor : root.dimColor
            fillColor: "transparent"
            strokeWidth: 2
            capStyle: ShapePath.RoundCap
            PathSvg { path: "M3.5 7.5 A12 12 0 0 1 20.5 7.5" }
        }
        ShapePath {
            strokeColor: "transparent"
            fillColor: root.litCount >= 1 ? root.strokeColor : root.dimColor
            PathSvg { path: "M12 14.1 A1.5 1.5 0 0 1 12 17.1 A1.5 1.5 0 0 1 12 14.1z" }
        }
    }
}