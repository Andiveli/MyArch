import QtQuick
import QtQuick.Layouts
import "../../singletons"

SettingsConnectedRow {
    id: root

    readonly property bool settingsFocusable: true
    property string label: ""
    property string subtext: ""
    property bool checked: false
    signal toggled(bool value)

    width: parent && parent.width > 0 ? parent.width : implicitWidth
    implicitWidth: 280
    implicitHeight: subtext.length > 0 ? Math.max(44, col.implicitHeight + 12) : 34

    MouseArea {
        anchors.fill: parent
        hoverEnabled: false
        onClicked: root.toggled(!root.checked)
    }

    RowLayout {
        id: col
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 8
        anchors.topMargin: 6
        anchors.bottomMargin: 6
        spacing: 10

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

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            width: 36
            height: 20
            radius: 10
            color: root.checked ? WallustColors.accent : Qt.rgba(WallustColors.borderColor.r, WallustColors.borderColor.g, WallustColors.borderColor.b, 0.6)
            Rectangle {
                width: 16
                height: 16
                radius: 8
                y: 2
                x: root.checked ? parent.width - width - 2 : 2
                color: WallustColors.moduleText
                Behavior on x { NumberAnimation { duration: Motion.fast; easing.type: Motion.easeMorph } }
            }
        }
    }
}