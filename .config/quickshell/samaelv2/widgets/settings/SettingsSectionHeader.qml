import QtQuick
import "../../singletons"

Text {
    property bool first: false

    width: parent && parent.width > 0 ? parent.width : implicitWidth
    topPadding: first ? 2 : 8
    bottomPadding: 3
    text: ""
    color: WallustColors.moduleText
    opacity: 0.55
    font.family: Style.fontFamily
    font.pixelSize: Style.fontPixelSize - 1
    font.bold: true
    font.letterSpacing: 0.6
}