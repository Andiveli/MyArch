import QtQuick
import QtQuick.Layouts
import "../../singletons"

SettingsConnectedRow {
    id: root

    readonly property bool settingsFocusable: true
    property string label: ""
    property string subtext: ""
    property int value: 0
    property int from: 0
    property int to: 100
    property int step: 1
    signal moved(int v)

    function bump(delta) {
        const v = Math.max(from, Math.min(to, value + delta * step))
        if (v !== value)
            root.moved(v)
    }

    width: parent && parent.width > 0 ? parent.width : implicitWidth
    implicitWidth: 280
    implicitHeight: subtext.length > 0 ? 40 : 34

    RowLayout {
        id: col
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 8
        anchors.topMargin: 6
        anchors.bottomMargin: 6
        spacing: 8

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
            }
            Text {
                Layout.fillWidth: true
                visible: root.subtext.length > 0
                text: root.subtext
                color: WallustColors.moduleText
                opacity: 0.5
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize - 2
            }
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: String(root.value)
            color: WallustColors.accent
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize + 1
            font.bold: true
        }
    }
}