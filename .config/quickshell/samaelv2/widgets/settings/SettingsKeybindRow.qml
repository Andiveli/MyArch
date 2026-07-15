import QtQuick
import QtQuick.Layouts
import "../../singletons"

/** Read-only key + action row (vim-navigable, no edit). */
SettingsConnectedRow {
    id: root

    readonly property bool settingsFocusable: true
    property string keys: ""
    property string action: ""

    implicitHeight: 36

    RowLayout {
        anchors.fill: parent
        spacing: 10

        Text {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: Math.min(140, implicitWidth)
            Layout.maximumWidth: 140
            text: root.keys
            color: WallustColors.accent
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize - 1
            font.bold: true
            wrapMode: Text.Wrap
        }

        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: root.action
            color: WallustColors.moduleText
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize - 1
            wrapMode: Text.WordWrap
            opacity: 0.92
        }
    }
}