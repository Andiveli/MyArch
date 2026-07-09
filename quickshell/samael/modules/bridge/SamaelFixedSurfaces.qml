pragma Singleton

import QtQuick
import qs.modules.samael

/**
 * Panel fills derived from Wallust wallpaper palette (background-alt / moduleBackground).
 * Accents and borders use WallustColors directly elsewhere.
 */
QtObject {
    readonly property color dropShellFill: {
        const _g = WallustColors.paletteGeneration
        const b = WallustColors.moduleBackground
        return Qt.rgba(
            b.r * 0.55,
            b.g * 0.55,
            b.b * 0.55,
            Math.min(0.97, b.a + 0.28))
    }

    readonly property color cardFill: {
        const _g = WallustColors.paletteGeneration
        const b = WallustColors.moduleBackground
        return Qt.rgba(
            b.r * 0.42,
            b.g * 0.42,
            b.b * 0.42,
            Math.min(0.96, b.a + 0.35))
    }

    readonly property color mediaPanelFill: {
        const _g = WallustColors.paletteGeneration
        const b = WallustColors.moduleBackground
        return Qt.rgba(
            b.r * 0.50,
            b.g * 0.50,
            b.b * 0.50,
            Math.min(0.97, b.a + 0.30))
    }

    readonly property color lockPanelFill: {
        const _g = WallustColors.paletteGeneration
        const b = WallustColors.moduleBackground
        return Qt.rgba(
            b.r * 0.48,
            b.g * 0.48,
            b.b * 0.48,
            Math.min(0.96, b.a + 0.32))
    }
}