import QtQuick
import QtQuick.Layouts
import "../../singletons"

SettingsConnectedRow {
    id: root

    readonly property bool settingsFocusable: true
    readonly property bool keybindDrillBack: true

    signal backRequested()

    implicitHeight: 34

    MouseArea {
        anchors.fill: parent
        onClicked: root.backRequested()
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: "\uf060  Back"
        color: WallustColors.accent
        font.family: Style.fontFamily
        font.pixelSize: Style.fontPixelSize - 1
        font.bold: root.vimFocus
    }
}