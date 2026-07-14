import QtQuick
import "../singletons"

/**
 * Middle-bar marker: CodexBar usage menu entry (no live usage polling).
 * Opens Usage surface via click / Super+Shift+A.
 */
Item {
    id: root

    implicitWidth: glyph.implicitWidth + 4
    implicitHeight: Style.barContentHeight
    width: implicitWidth
    height: implicitHeight

    Text {
        id: glyph
        anchors.verticalCenter: parent.verticalCenter
        // chart / usage glyph — static presence only
        text: "\uf201"
        color: WallustColors.moduleText
        font.pixelSize: Style.fontPixelSize
        font.family: Style.fontFamily
        opacity: 0.9
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        onClicked: ShellActions.toggleUsage?.()
    }
}
