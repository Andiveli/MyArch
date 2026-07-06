pragma Singleton

import QtQuick
import qs.services

/** Documents bridge contract: vendored lock must use qs.services Colours (Wallust-backed). */
QtObject {
    readonly property color primary: Colours.palette.m3primary
    readonly property color surface: Colours.palette.m3surface
    readonly property color onSurface: Colours.palette.m3onSurface
}