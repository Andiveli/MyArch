import QtQuick
import "../singletons"

Text {
    height: Style.barContentHeight
    verticalAlignment: Text.AlignVCenter
    color: WallustColors.clockText
    font.pixelSize: Style.fontPixelSize
    font.family: Style.fontFamily

    readonly property string clockGlyph: "\uf017"

    Timer {
        interval: 1000
        running: ShellConfig.barEnabled && ShellConfig.hasWidgetAnywhere("clock")
        repeat: true
        triggeredOnStart: true
        onTriggered: parent.text = parent.clockGlyph + "  " + Qt.formatDateTime(new Date(), "HH:mm")
    }
}