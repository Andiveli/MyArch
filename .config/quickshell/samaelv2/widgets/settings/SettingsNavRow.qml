import QtQuick
import QtQuick.Layouts
import "../../singletons"

SettingsConnectedRow {
    id: root

    property string label: ""
    property string status: ""
    property string icon: "\uf105"
    signal activated()

    implicitHeight: 32

    MouseArea {
        anchors.fill: parent
        hoverEnabled: false
        onPressed: root.pressHighlight = true
        onReleased: root.pressHighlight = false
        onCanceled: root.pressHighlight = false
        onClicked: root.activated()
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 8
        anchors.topMargin: 0
        anchors.bottomMargin: 0
        spacing: 8

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: root.icon
            color: root.selected ? WallustColors.accent : WallustColors.moduleText
            opacity: root.selected ? 1 : 0.75
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize
        }

        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: root.label
            color: WallustColors.moduleText
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize
            font.bold: root.selected
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            visible: root.selected
            text: "\uf054"
            color: WallustColors.accent
            opacity: 0.7
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize - 2
        }
    }
}