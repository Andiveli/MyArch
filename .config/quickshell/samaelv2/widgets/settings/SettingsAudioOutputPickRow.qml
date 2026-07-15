import QtQuick
import QtQuick.Layouts
import "../../singletons"

/** Output choice under an expanded stream (c). */
SettingsConnectedRow {
    id: root

    readonly property bool settingsFocusable: true
    readonly property bool audioOutputPickRow: true

    property var sink: ({})
    property string streamId: ""
    property string activeSinkId: ""

    readonly property bool isActive: String(activeSinkId) === String(sink.id || "")

    function trigger() {
        if (streamId.length && sink.id !== undefined)
            AudioRouteService.moveStream(streamId, sink.id)
    }

    implicitHeight: 34

    MouseArea {
        z: 2
        anchors.fill: parent
        onClicked: root.trigger()
    }

    RowLayout {
        anchors.fill: parent
        spacing: 8
        Text {
            text: "  "
            font.pixelSize: 1
        }
        Text {
            Layout.alignment: Qt.AlignVCenter
            text: isActive ? "\uf00c" : "\uf111"
            color: isActive ? WallustColors.accent : WallustColors.moduleText
            opacity: isActive ? 1 : 0.2
            font.family: Style.fontFamily
            font.pixelSize: 9
        }
        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: sink.description || sink.name || "?"
            color: WallustColors.moduleText
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize - 2
            font.bold: root.vimFocus || isActive
            elide: Text.ElideRight
        }
    }
}