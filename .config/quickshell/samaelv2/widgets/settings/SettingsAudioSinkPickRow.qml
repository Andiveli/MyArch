import QtQuick
import QtQuick.Layouts
import "../../singletons"

SettingsConnectedRow {
    id: root

    readonly property bool settingsFocusable: true
    property var sink: ({})
    property string activeSinkId: ""
    property string streamId: ""

    readonly property bool isActive: String(activeSinkId) === String(sink.id || "")

    implicitHeight: 40

    function trigger() {
        if (root.streamId.length && sink.id !== undefined)
            AudioRouteService.moveStream(root.streamId, sink.id)
    }

    MouseArea {
        z: 2
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.trigger()
    }

    RowLayout {
        anchors.fill: parent
        spacing: 8

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: root.isActive ? "\uf00c" : "\uf111"
            color: root.isActive ? WallustColors.accent : WallustColors.moduleText
            opacity: root.isActive ? 1 : 0.25
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize - 2
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0
            Text {
                Layout.fillWidth: true
                text: sink.description || sink.name || "?"
                color: WallustColors.moduleText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize - 1
                font.bold: root.isActive || root.vimFocus
                elide: Text.ElideRight
            }
        }
    }
}