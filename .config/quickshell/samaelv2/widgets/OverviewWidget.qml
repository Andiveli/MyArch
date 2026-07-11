import QtQuick
import "../singletons"

Item {
    implicitWidth: glyph.implicitWidth + 4
    implicitHeight: Style.barContentHeight

    Text {
        id: glyph
        anchors.verticalCenter: parent.verticalCenter
        text: "\uf080"
        font.family: Style.fontFamily
        font.pixelSize: Style.fontPixelSize
        color: WallustColors.moduleText
        opacity: 0.92
    }

    MouseArea {
        anchors.fill: parent
        onClicked: ShellActions.toggleOverview?.()
    }
}