import QtQuick
import QtQuick.Layouts
import "../../singletons"
import "../../widgets"

/** Overview-style stream row — label, %, level bar; drill on activate. */
SettingsConnectedRow {
    id: root

    readonly property bool settingsFocusable: true
    property var stream: ({})
    signal drillRequested(string id)

    readonly property string streamId: String(stream.id || "")
    readonly property string drillId: streamId
    readonly property real level: Math.max(0, Math.min(1, (stream.volume || 0) / 100))

    implicitHeight: 56

    MouseArea {
        anchors.fill: parent
        hoverEnabled: false
        onClicked: {
            if (streamId.length)
                root.drillRequested(streamId)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 3
                height: 18
                radius: 1
                visible: root.vimFocus
                color: WallustColors.accent
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 0
                Text {
                    Layout.fillWidth: true
                    text: stream.label || "?"
                    color: WallustColors.moduleText
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontPixelSize - 1
                    font.bold: root.vimFocus
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    visible: (stream.mediaTitle || "").length > 0
                    text: {
                        const t = stream.mediaTitle || ""
                        if (stream.corked)
                            return t + " · paused"
                        return t
                    }
                    color: WallustColors.moduleText
                    opacity: 0.5
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontPixelSize - 3
                    elide: Text.ElideRight
                }
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: (stream.muted ? "mute · " : "") + (stream.volume ?? 0) + "%"
                color: WallustColors.moduleText
                opacity: 0.55
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize - 2
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: "\uf054"
                color: WallustColors.accent
                opacity: root.vimFocus ? 0.9 : 0.3
                font.family: Style.fontFamily
                font.pixelSize: 10
            }
        }

        OverviewSmoothBar {
            Layout.fillWidth: true
            implicitHeight: 5
            barRadius: 2
            fraction: stream.muted ? 0 : level
            fillColor: WallustColors.accent
            trackOpacity: 0.12
        }
    }
}