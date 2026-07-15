import QtQuick
import QtQuick.Layouts
import "../../singletons"
import "../../widgets"

/** One stream in the flat mixer list — vim: h/l vol, m mute, Space play, c output menu. */
SettingsConnectedRow {
    id: root

    readonly property bool settingsFocusable: true
    readonly property bool audioStreamRow: true

    property var stream: ({})
    property bool outputMenuOpen: false
    signal toggleOutputMenu()

    readonly property string streamId: String(stream.id || "")
    readonly property real level: Math.max(0, Math.min(1, (stream.volume || 0) / 100))
    readonly property var mprisPlayer: AudioRouteService.findMprisForStream(stream)

    function bump(delta) {
        if (!streamId.length)
            return
        const step = 3
        const v = Math.max(0, Math.min(100, (stream.volume || 0) + delta * step))
        AudioRouteService.setStreamVolume(streamId, v)
    }

    function audioMuteToggle() {
        if (streamId.length)
            AudioRouteService.toggleStreamMute(streamId)
    }

    function audioPlayToggle() {
        const p = AudioRouteService.findMprisForStream(stream)
        if (p)
            AudioRouteService.mprisOp(p, "playpause")
    }

    function openOutputMenu() {
        root.toggleOutputMenu()
    }

    implicitHeight: 56

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
                        return stream.corked ? (t + " · idle") : t
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
                text: {
                    let s = ""
                    if (stream.muted)
                        s += "\uf6a9 "
                    if (mprisPlayer)
                        s += (mprisPlayer.isPlaying ? "\uf04c " : "\uf04b ")
                    s += (stream.volume ?? 0) + "%"
                    return s
                }
                color: WallustColors.moduleText
                opacity: 0.6
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize - 2
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