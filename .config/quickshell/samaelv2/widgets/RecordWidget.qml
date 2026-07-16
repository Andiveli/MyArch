import QtQuick
import "../singletons"

Item {
    implicitWidth: glyph.implicitWidth + (RecordService.running ? 8 : 0)
    implicitHeight: Style.barContentHeight

    readonly property int _rev: RecordService.revision

    Text {
        id: glyph
        anchors.verticalCenter: parent.verticalCenter
        text: RecordService.running ? "\uf04d" : "\uf03d"
        color: RecordService.running ? WallustColors.red : WallustColors.moduleText
        font.family: Style.fontFamily
        font.pixelSize: Style.fontPixelSize
        opacity: RecordService.running ? 1 : 0.85
    }

    Rectangle {
        visible: RecordService.running
        width: 6
        height: 6
        radius: 3
        color: WallustColors.red
        anchors.left: glyph.right
        anchors.leftMargin: 2
        anchors.verticalCenter: parent.verticalCenter
    }

    MouseArea {
        anchors.fill: parent
        onClicked: ShellActions.toggleRecord?.()
    }
}