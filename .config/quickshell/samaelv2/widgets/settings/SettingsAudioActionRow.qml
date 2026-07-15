import QtQuick
import QtQuick.Layouts
import "../../singletons"

SettingsConnectedRow {
    id: root

    readonly property bool settingsFocusable: true
    property string label: ""
    property string subtext: ""
    signal activated()

    implicitHeight: subtext.length ? Math.max(44, col.implicitHeight + 12) : 34

    MouseArea {
        anchors.fill: parent
        hoverEnabled: false
        onClicked: root.activated()
    }

    RowLayout {
        id: col
        anchors.fill: parent
        spacing: 0

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0
            Text {
                Layout.fillWidth: true
                text: root.label
                color: WallustColors.moduleText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize
                font.bold: root.vimFocus
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                visible: root.subtext.length > 0
                text: root.subtext
                color: WallustColors.moduleText
                opacity: 0.5
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize - 2
                elide: Text.ElideRight
            }
        }
    }
}