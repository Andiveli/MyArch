pragma Singleton

import QtQuick
import qs.modules.samael
import qs.modules.bridge

/**
 * Drop-in Colours singleton for vendored Caelestia QML.
 * Palette roles map to Wallust via SamaelLockColors; no matugen pipeline.
 */
QtObject {
    id: root

    readonly property bool showPreview: false
    readonly property bool light: false
    readonly property real wallLuminance: 0.35

    readonly property var transparency: QtObject {
        readonly property bool enabled: false
        readonly property real base: 1
        readonly property real layers: 0.4
    }

    readonly property var palette: QtObject {
        readonly property int _g: WallustColors.paletteGeneration

        readonly property color m3surface: SamaelLockColors.surface
        readonly property color m3onSurface: SamaelLockColors.onSurface
        readonly property color m3onSurfaceVariant: SamaelLockColors.onSurfaceVariant
        readonly property color m3onSecondary: WallustColors.foreground
        readonly property color m3onSecondaryContainer: WallustColors.foreground
        readonly property color m3surfaceContainer: SamaelLockColors.surfaceContainer
        readonly property color m3surfaceContainerHigh: SamaelLockColors.surfaceHigh
        readonly property color m3surfaceContainerHighest: SamaelLockColors.surfaceHighest
        readonly property color m3surfaceContainerLow: SamaelLockColors.surfaceLow
        readonly property color m3surfaceContainerLowest: SamaelLockColors.surfaceLowest
        readonly property color m3primary: SamaelLockColors.primary
        readonly property color m3onPrimary: WallustColors.foreground
        readonly property color m3primaryContainer: Qt.rgba(
            WallustColors.sapphire.r, WallustColors.sapphire.g, WallustColors.sapphire.b, 0.35)
        readonly property color m3secondary: SamaelLockColors.secondary
        readonly property color m3secondaryContainer: Qt.rgba(
            WallustColors.mauve.r, WallustColors.mauve.g, WallustColors.mauve.b, 0.4)
        readonly property color m3tertiary: WallustColors.teal
        readonly property color m3onTertiary: WallustColors.foreground
        readonly property color m3error: SamaelLockColors.error
        readonly property color m3onError: WallustColors.foreground
        readonly property color m3errorContainer: Qt.rgba(
            WallustColors.red.r, WallustColors.red.g, WallustColors.red.b, 0.45)
        readonly property color m3onErrorContainer: WallustColors.foreground
        readonly property color m3outline: SamaelLockColors.outline
        readonly property color m3outlineVariant: SamaelLockColors.outlineVariant
        readonly property color m3shadow: Qt.rgba(0, 0, 0, 0.55)
    }

    readonly property var tPalette: QtObject {
        readonly property int _g: WallustColors.paletteGeneration

        readonly property color m3surface: SamaelLockColors.surface
        readonly property color m3surfaceContainer: SamaelLockColors.surfaceContainer
        readonly property color m3surfaceContainerHigh: SamaelLockColors.surfaceHigh
        readonly property color m3surfaceContainerHighest: SamaelLockColors.surfaceHighest
        readonly property color m3surfaceContainerLow: SamaelLockColors.surfaceLow
        readonly property color m3surfaceContainerLowest: SamaelLockColors.surfaceLowest
        readonly property color m3outline: SamaelLockColors.outline
        readonly property color m3outlineVariant: SamaelLockColors.outlineVariant
    }

    function layer(c: color, layerIndex: var): color {
        if (!transparency.enabled)
            return c
        return Qt.alpha(c, transparency.base)
    }

    function on(c: color): color {
        if (c.hslLightness < 0.5)
            return Qt.hsla(c.hslHue, c.hslSaturation, 0.9, 1)
        return Qt.hsla(c.hslHue, c.hslSaturation, 0.1, 1)
    }

    function load(_data: string, _isPreview: bool): void {
        WallustColors.reloadPaletteFromDisk()
    }
}