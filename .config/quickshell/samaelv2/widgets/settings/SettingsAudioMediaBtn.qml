import QtQuick
import QtQuick.Layouts
import "../../singletons"

SettingsConnectedRow {
    id: root

    readonly property bool settingsFocusable: true
    property string glyph: "\uf04b"
    property string caption: ""
    property bool enabled: true
    signal triggered()

    implicitHeight: 44
    opacity: enabled ? 1 : 0.35

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        onClicked: root.triggered()
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 2
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.glyph
            color: root.vimFocus ? WallustColors.accent : WallustColors.moduleText
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize + 2
        }
        Text {
            visible: caption.length > 0
            Layout.alignment: Qt.AlignHCenter
            text: root.caption
            color: WallustColors.moduleText
            opacity: 0.45
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize - 3
        }
    }
}