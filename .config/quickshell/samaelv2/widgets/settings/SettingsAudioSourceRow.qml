import QtQuick
import QtQuick.Layouts
import "../../singletons"

/** Card-style source row — l/Enter opens stream detail. */
SettingsConnectedRow {
    id: root

    readonly property bool settingsFocusable: true
    property var stream: ({})
    signal drillRequested(string id)

    readonly property string streamId: String(stream.id || "")
    readonly property string drillId: streamId

    implicitHeight: 52

    MouseArea {
        anchors.fill: parent
        hoverEnabled: false
        onClicked: {
            if (root.streamId.length)
                root.drillRequested(root.streamId)
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 10

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            width: 36
            height: 36
            radius: 10
            color: Qt.rgba(WallustColors.accent.r, WallustColors.accent.g, WallustColors.accent.b, 0.18)
            Text {
                anchors.centerIn: parent
                text: stream.muted ? "\uf6a9" : "\uf028"
                color: WallustColors.accent
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize
                opacity: stream.muted ? 0.55 : 1
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2
            Text {
                Layout.fillWidth: true
                text: stream.label || "?"
                color: WallustColors.moduleText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize
                font.bold: root.vimFocus
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                visible: (stream.mediaTitle || "").length > 0
                text: stream.mediaTitle || ""
                color: WallustColors.moduleText
                opacity: 0.55
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize - 2
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: AudioRouteService.sinkDescription(stream.sinkId) + " · " + (stream.volume ?? "?") + "%"
                color: WallustColors.moduleText
                opacity: 0.4
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize - 2
                elide: Text.ElideRight
            }
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: "\uf054"
            color: WallustColors.accent
            opacity: root.vimFocus ? 1 : 0.35
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize - 1
        }
    }
}