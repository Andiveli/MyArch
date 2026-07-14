import QtQuick
import "../singletons"

/** Middle bar — open launcher surface (Super / click). */
Item {
    implicitWidth: glyph.implicitWidth + 8
    implicitHeight: Style.barContentHeight

    Text {
        id: glyph
        anchors.verticalCenter: parent.verticalCenter
        text: "\uf002"
        font.family: Style.fontFamily
        font.pixelSize: Style.fontPixelSize + 1
        color: WallustColors.sapphire
        opacity: 0.95
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        cursorShape: Qt.PointingHandCursor
        onClicked: ShellActions.toggleLauncher?.()
    }
}