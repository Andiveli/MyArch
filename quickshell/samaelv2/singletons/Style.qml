pragma Singleton

import QtQuick
import Quickshell

Item {
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property bool fontBold: false
    readonly property real waybarFontSizePercent: 0.88

    readonly property int _gtkBaseFontPx: {
        const app = Qt.application.font
        let px = app.pixelSize
        if (px <= 0 && app.pointSize > 0)
            px = Math.round(app.pointSize * 96 / 72)
        if (px <= 0)
            px = 12
        return px
    }

    readonly property int fontPixelSize: Math.max(9, Math.round(_gtkBaseFontPx * waybarFontSizePercent))
    readonly property string fontFeatureSettings: '"zero", "ss01", "ss02", "ss03", "ss04", "ss05", "cv31"'

    readonly property int modulePaddingH: 6
    readonly property int modulePaddingTop: 6
    readonly property int modulePaddingBottom: 4
    readonly property int moduleGroupPadH: 8
    readonly property int moduleRowSpacing: 0

    readonly property color textColor: WallustColors.moduleText
    readonly property color menuPanelFill: Qt.rgba(
        WallustColors.moduleBackground.r * 0.55,
        WallustColors.moduleBackground.g * 0.55,
        WallustColors.moduleBackground.b * 0.55,
        Math.min(0.97, WallustColors.moduleBackground.a + 0.28))
    readonly property color borderColor: WallustColors.borderColor
    readonly property color accentColor: WallustColors.buttonColor
    readonly property color hoverColor: WallustColors.buttonHover
    readonly property color activeGold: WallustColors.workspaceActive
    readonly property color urgentRed: WallustColors.workspaceUrgent

    readonly property int barContentHeight: 22
    readonly property int barReserveSlop: 8
    readonly property int chromeBandHeight: barContentHeight + 4 + 4
}