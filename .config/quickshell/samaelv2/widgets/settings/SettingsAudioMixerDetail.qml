import QtQuick
import QtQuick.Layouts
import "../../singletons"

Item {
    id: root

    required property string streamId
    property var stream: null
    property var mprisPlayer: null
    signal back()

    readonly property int _ar: AudioRouteService.revision

    implicitWidth: 320
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 4

        SettingsKeybindBackRow {
            Layout.fillWidth: true
            first: true
            onBackRequested: root.back()
        }

        SettingsConnectedRow {
            Layout.fillWidth: true
            implicitHeight: 40
            RowLayout {
                anchors.fill: parent
                spacing: 8
                Text {
                    Layout.fillWidth: true
                    text: stream ? (stream.mediaTitle || stream.label) : "—"
                    color: WallustColors.moduleText
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontPixelSize
                    font.bold: true
                    elide: Text.ElideRight
                }
                Text {
                    text: stream ? stream.label : ""
                    color: WallustColors.moduleText
                    opacity: 0.45
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontPixelSize - 2
                    elide: Text.ElideLeft
                    Layout.maximumWidth: 120
                }
            }
        }

        SettingsAudioVolumeRow {
            Layout.fillWidth: true
            streamId: root.streamId
            value: stream ? (stream.volume || 0) : 0
            muted: stream ? !!stream.muted : false
        }

        SettingsAudioToggleBtnRow {
            Layout.fillWidth: true
            label: stream?.muted ? "\uf6a9  Unmute" : "\uf028  Mute"
            enabled: root.streamId.length > 0
            onActivated: {
                if (root.streamId.length)
                    AudioRouteService.toggleStreamMute(root.streamId)
            }
        }

        SettingsAudioToggleBtnRow {
            id: playRow
            Layout.fillWidth: true
            visible: mprisPlayer !== null
            readonly property bool playing: mprisPlayer ? !!mprisPlayer.isPlaying : false
            label: playing ? "\uf04c  Pause" : "\uf04b  Play"
            enabled: mprisPlayer !== null
            onActivated: AudioRouteService.mprisOp(mprisPlayer, "playpause")
        }

        SettingsSectionHeader { text: "OUTPUT" }

        Repeater {
            id: sinkPick
            model: AudioRouteService.sinks
            delegate: SettingsAudioSinkPickRow {
                required property int index
                required property var modelData
                Layout.fillWidth: true
                first: index === 0
                last: index === sinkPick.count - 1
                sink: modelData
                streamId: root.streamId
                activeSinkId: stream ? String(stream.sinkId) : ""
            }
        }
    }
}