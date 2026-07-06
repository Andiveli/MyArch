pragma Singleton

import QtQuick
import qs.modules.samael

/** M3 lock surface roles derived from Wallust (shared by Colours bridge). */
QtObject {
    readonly property color surface: Qt.rgba(
        WallustColors.moduleBackground.r * 0.45,
        WallustColors.moduleBackground.g * 0.45,
        WallustColors.moduleBackground.b * 0.45,
        0.96)
    readonly property color surfaceContainer: Qt.rgba(
        WallustColors.moduleBackground.r * 0.38,
        WallustColors.moduleBackground.g * 0.38,
        WallustColors.moduleBackground.b * 0.38,
        0.94)
    readonly property color surfaceHigh: Qt.rgba(
        WallustColors.moduleBackground.r * 0.72,
        WallustColors.moduleBackground.g * 0.72,
        WallustColors.moduleBackground.b * 0.72,
        0.92)
    readonly property color surfaceHighest: Qt.rgba(0.08, 0.09, 0.12, 0.95)
    readonly property color surfaceLow: Qt.rgba(
        WallustColors.moduleBackground.r * 0.28,
        WallustColors.moduleBackground.g * 0.28,
        WallustColors.moduleBackground.b * 0.28,
        0.90)
    readonly property color surfaceLowest: Qt.rgba(
        WallustColors.moduleBackground.r * 0.18,
        WallustColors.moduleBackground.g * 0.18,
        WallustColors.moduleBackground.b * 0.18,
        0.88)
        readonly property color onSurface: WallustColors.foreground
        readonly property color onSurfaceVariant: Qt.rgba(
            WallustColors.foreground.r,
            WallustColors.foreground.g,
            WallustColors.foreground.b,
            0.72)
    readonly property color primary: WallustColors.sapphire
    readonly property color secondary: WallustColors.mauve
    readonly property color error: WallustColors.red
    readonly property color border: WallustColors.borderColor
    readonly property color outline: WallustColors.borderColor
    readonly property color outlineVariant: Qt.rgba(
        WallustColors.borderColor.r,
        WallustColors.borderColor.g,
        WallustColors.borderColor.b,
        0.6)
}