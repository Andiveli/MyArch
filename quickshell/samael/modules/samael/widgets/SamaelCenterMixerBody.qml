import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.samael

/**
 * Compact center-dock mixer: default sink/source volume + mute toggles.
 */
Item {
    id: root
    focus: true

    readonly property int panelWidth: 320
    readonly property int faderHeight: 140

    implicitWidth: panelWidth
    implicitHeight: card.implicitHeight

    function closeMixer() {
        GlobalStates.samaelCenterMixerOpen = false
    }

    function sinkIcon(): string {
        const muted = Audio.sink?.audio?.muted ?? true
        if (muted)
            return "󰖁"
        const v = Audio.value
        if (v <= 0)
            return "󰖁"
        if (v < 0.34)
            return "󰕿"
        if (v < 0.67)
            return "󰖀"
        return "󰕾"
    }

    function sourceIcon(): string {
        const muted = Audio.source?.audio?.muted ?? false
        return muted ? "󰍭" : "󰍬"
    }

    function setSinkVolume(norm) {
        if (!Audio.sink?.audio)
            return
        Audio.sink.audio.volume = Math.max(0, Math.min(1, norm))
    }

    function setSourceVolume(norm) {
        if (!Audio.source?.audio)
            return
        Audio.source.audio.volume = Math.max(0, Math.min(1, norm))
    }

    Rectangle {
        id: card
        width: root.panelWidth
        radius: 12
        color: SamaelFixedSurfaces.dropShellFill
        border.width: 2
        border.color: WallustColors.borderColor
        implicitHeight: column.implicitHeight + 20

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.closeMixer()
                event.accepted = true
            }
        }

        ColumnLayout {
            id: column
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Mixer"
                    color: WallustColors.moduleText
                    font.family: SamaelStyle.fontFamily
                    font.pixelSize: SamaelStyle.fontPixelSize + 1
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "Esc close"
                    color: WallustColors.buttonHover
                    font.family: SamaelStyle.fontFamily
                    font.pixelSize: 8
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 24

                SamaelCenterMixerFader {
                    title: "Output"
                    icon: root.sinkIcon()
                    muted: Audio.sink?.audio?.muted ?? false
                    volume: Audio.sink?.audio?.volume ?? 0
                    faderHeight: root.faderHeight
                    onToggleMute: Audio.toggleMute()
                    onVolumeCommitted: v => root.setSinkVolume(v)
                }

                SamaelCenterMixerFader {
                    title: "Input"
                    icon: root.sourceIcon()
                    muted: Audio.source?.audio?.muted ?? false
                    volume: Audio.source?.audio?.volume ?? 0
                    faderHeight: root.faderHeight
                    onToggleMute: Audio.toggleMicMute()
                    onVolumeCommitted: v => root.setSourceVolume(v)
                }
            }
        }
    }

    Connections {
        target: GlobalStates
        function onSamaelCenterMixerOpenChanged() {
            if (GlobalStates.samaelCenterMixerOpen)
                Qt.callLater(() => root.forceActiveFocus())
        }
    }
}