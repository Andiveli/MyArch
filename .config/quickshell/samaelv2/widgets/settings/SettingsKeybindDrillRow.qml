import QtQuick
import QtQuick.Layouts
import "../../singletons"

/** Open-surface row: Hypr combo + label; l/Enter drills when drillId is set. */
SettingsConnectedRow {
    id: root

    readonly property bool settingsFocusable: true
    property string keys: ""
    property string action: ""
    property string drillId: ""
    readonly property bool keybindDrillBack: false

    signal drillRequested(string id)

    implicitHeight: 36

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (root.drillId.length)
                root.drillRequested(root.drillId)
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 8
        spacing: 8

        Text {
            Layout.preferredWidth: Math.min(132, implicitWidth)
            Layout.maximumWidth: 132
            text: root.keys
            color: WallustColors.accent
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize - 1
            font.bold: true
            wrapMode: Text.Wrap
        }

        Text {
            Layout.fillWidth: true
            text: root.action
            color: WallustColors.moduleText
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize - 1
            elide: Text.ElideRight
        }

        Text {
            visible: root.drillId.length > 0
            text: "\uf054"
            color: WallustColors.accent
            opacity: root.vimFocus ? 1 : 0.45
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize - 2
        }
    }
}