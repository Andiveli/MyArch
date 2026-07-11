import QtQuick
import "../singletons"

Item {
    implicitWidth: icon.implicitWidth
    implicitHeight: Style.barContentHeight

    readonly property bool btOn: BtSurfaceLogic.btOn
    readonly property bool connected: BtSurfaceLogic.activeDevice !== null

    Text {
        id: icon
        anchors.verticalCenter: parent.verticalCenter
        text: "\uf294"
        font.family: Style.fontFamily
        font.pixelSize: Style.fontPixelSize + 1
        color: btOn
            ? (connected ? WallustColors.accent : WallustColors.moduleText)
            : WallustColors.moduleText
        opacity: btOn ? 1 : 0.45
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        onClicked: ShellActions.toggleBluetooth?.()
    }
}