import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../singletons"
import "../widgets"

/**
 * Middle pill media: disc | meta + controls; optional lyrics column (L / y / Shift+L).
 * Wavy seek/ring: ported widgets (see docs/WAVY-PORT.md). Lyrics: optional plugin via LyricsService.
 */
FocusScope {
    id: root

    property bool open: false
    property bool fadeWithMorph: true
    property bool contentShown: true
    property real morphCloseness: 1

    readonly property var player: MprisPlayers.activePlayer
    /** Drives re-bind when MprisPlaybackClock polls / interpolates (position is not reactive). */
    readonly property int _playbackTick: MprisPlaybackClock.tick
    readonly property real trackLengthSec: {
        const _t = _playbackTick
        const _rev = MprisPlayers.timingRevision
        const _cached = MprisPlayers.activeTrackLengthSec
        const p = player
        if (!p)
        return 0
        const live = MprisPlayers.getTrackLengthSec(p)
        return live > 0 ? live : _cached
    }
    readonly property real displayPositionSec: {
        const _t = _playbackTick
        const p = player
        return p ? MprisPlayers.getPositionSec(p, true) : 0
    }
    readonly property real playerProgress: {
        const _t = _playbackTick
        const len = trackLengthSec
        if (!len || len <= 0)
            return 0
        const pos = displayPositionSec
        return Math.max(0, Math.min(1, pos / len))
    }

    readonly property int discCol: 228
    readonly property int metaW: 248
    readonly property int gap: 16
    readonly property int lyricsGap: 12
    property bool lyricsVisible: false
    readonly property int rowW: discCol + gap + metaW
            + (lyricsVisible ? lyricsGap + ShellConfig.lyricsPanelWidth : 0)

    readonly property real contentOpacity: {
        if (!open || !contentShown)
            return 0
        if (!fadeWithMorph)
            return 1
        const m = Math.pow(morphCloseness, 1.2)
        return Math.max(m, open ? 0.35 : 0)
    }

    implicitWidth: rowW
    implicitHeight: Math.max(248, mainRow.implicitHeight)

    opacity: contentOpacity
    visible: opacity > 0.02
    enabled: open
    clip: true
    focus: open
    activeFocusOnTab: false

    function lengthStr(sec) {
        if (sec < 0 || isNaN(sec))
            return "-:--"
        const s = Math.floor(sec)
        const h = Math.floor(s / 3600)
        const m = Math.floor((s % 3600) / 60)
        const ss = (s % 60).toString().padStart(2, "0")
        if (h > 0)
            return `${h}:${m.toString().padStart(2, "0")}:${ss}`
        return `${m}:${ss}`
    }

    function cycleLoop() {
        const p = player
        if (!p?.loopSupported)
            return
        const st = p.loopState
        if (st === MprisLoopState.None)
            p.loopState = MprisLoopState.Track
        else if (st === MprisLoopState.Track)
            p.loopState = MprisLoopState.Playlist
        else
            p.loopState = MprisLoopState.None
    }

    function cyclePlayer(back) {
        const list = MprisPlayers.list
        if (list.length <= 1)
            return
        const cur = player
        let idx = list.indexOf(cur)
        if (idx < 0)
            idx = 0
        const n = list.length
        MprisPlayers.manualActive = list[(idx + (back ? -1 : 1) + n) % n]
    }

    function seekBy(delta) {
        const p = player
        if (!p?.canSeek || !MprisPlayers.hasUsablePosition(p))
            return
        const len = MprisPlayers.getTrackLengthSec(p)
        p.position = Math.max(0, Math.min(len || p.position, displayPositionSec + delta))
    }

    Timer {
        running: root.open && player
                && player.playbackState === MprisPlaybackState.Playing
        interval: 400
        repeat: true
        onTriggered: player.positionChanged()
    }

    Timer {
        id: openTimingKick
        interval: 200
        repeat: true
        property int bursts: 0
            running: root.open && player && bursts < 25
            onTriggered: {
                MprisPlayers.refreshActiveTrackLength()
                MprisPlaybackClock.nudgeTiming()
                bursts++
            }
        onRunningChanged: if (running) bursts = 0
    }

    Timer {
        running: root.open && player?.playbackState === MprisPlaybackState.Playing
        interval: 500
        repeat: true
        onTriggered: progressRing.repaint()
    }

    RowLayout {
        id: mainRow
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: root.gap

        Item {
            id: discHost
            Layout.preferredWidth: root.discCol
            Layout.preferredHeight: root.discCol
            Layout.alignment: Qt.AlignVCenter

            readonly property int strokePx: 5
            readonly property real ringMargin: strokePx * 3.2
            readonly property real arcCoverGap: 4
            readonly property real pad: 12
            readonly property real coverSide: Math.max(100,
                root.discCol - (pad + arcCoverGap + ringMargin) * 2)
            readonly property real ringSize: coverSide + arcCoverGap + ringMargin * 2

            MediaWavyRing {
                id: progressRing
                anchors.centerIn: parent
                width: discHost.ringSize
                height: discHost.ringSize
                strokeWidth: discHost.strokePx
                startAngle: -90 - sweepAngle / 2
                sweepAngle: 180
                value: root.playerProgress
                fgColor: WallustColors.sky
                waveFrequency: 8
                waveAmplitude: 0.65
                waveDuration: 2000
                waveActive: player?.playbackState === MprisPlaybackState.Playing
                z: 0
            }

            MediaCoverDisc {
                anchors.centerIn: parent
                z: 1
                side: Math.round(discHost.coverSide)
                player: root.player
            }
        }

        Item {
            Layout.preferredWidth: root.metaW
            Layout.maximumWidth: root.metaW
            Layout.preferredHeight: metaPlaying.visible ? metaPlaying.implicitHeight : metaIdle.implicitHeight
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

            ColumnLayout {
                id: metaPlaying
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                visible: root.player != null
                spacing: 3

                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: StringUtils.cleanMusicTitle(player?.trackTitle) || qsTr("Unknown title")
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontPixelSize + 3
                    font.bold: true
                    color: WallustColors.sky
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: player?.trackArtist || qsTr("Unknown artist")
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontPixelSize + 1
                    color: WallustColors.buttonHover
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: player?.trackAlbum || qsTr("Unknown album")
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontPixelSize
                    color: WallustColors.mauve
                    opacity: 0.9
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    visible: MprisPlayers.list.length > 1
                    text: MprisPlayers.getIdentity(player) + " · Tab"
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontPixelSize - 2
                    color: WallustColors.buttonHover
                    opacity: 0.75
                    elide: Text.ElideRight
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    spacing: 8

                    Text {
                        id: posLabel
                        Layout.preferredWidth: 44
                        text: lengthStr(root.displayPositionSec)
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize - 1
                        color: WallustColors.buttonHover
                        horizontalAlignment: Text.AlignHCenter
                    }

                    MediaWavySeekBar {
                        id: seek
                        Layout.fillWidth: true
                        Layout.preferredHeight: 18
                        waveFrequency: 5
                        waveDuration: 2000
                        value: root.playerProgress
                        enabled: (player?.canSeek ?? false) && root.trackLengthSec > 0
                                && MprisPlayers.hasUsablePosition(player)
                        animateWave: player?.playbackState === MprisPlaybackState.Playing
                        onSeeked: fraction => {
                            const len = root.trackLengthSec
                            if (player?.canSeek && MprisPlayers.hasUsablePosition(player) && len > 0)
                                player.position = fraction * len
                            posLabel.text = lengthStr(fraction * len)
                        }
                        onValueChanged: if (!seek.draggingProp)
                            posLabel.text = lengthStr(root.displayPositionSec)
                    }

                    Text {
                        Layout.preferredWidth: 44
                        text: root.trackLengthSec > 0 ? lengthStr(root.trackLengthSec) : "-:--"
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize - 1
                        color: WallustColors.buttonHover
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6

                    MediaControlButton {
                        glyph: "\uf074"
                        diameter: 34
                        enabled: player?.shuffleSupported ?? false
                        checked: player?.shuffle ?? false
                        onClicked: { if (player?.shuffleSupported) player.shuffle = !player.shuffle }
                    }
                    MediaControlButton {
                        glyph: "\uf048"
                        diameter: 38
                        enabled: player?.canGoPrevious ?? false
                        onClicked: player?.previous()
                    }
                    MediaControlButton {
                        glyph: player?.isPlaying ? "\uf04c" : "\uf04b"
                        diameter: 44
                        primary: true
                        enabled: player?.canTogglePlaying ?? false
                        checked: player?.isPlaying ?? false
                        onClicked: player?.togglePlaying()
                    }
                    MediaControlButton {
                        glyph: "\uf051"
                        diameter: 38
                        enabled: player?.canGoNext ?? false
                        onClicked: player?.next()
                    }
                    MediaControlButton {
                        glyph: player?.loopState === MprisLoopState.Track ? "\uf01e" : "\uf363"
                        diameter: 34
                        enabled: player?.loopSupported ?? false
                        checked: player?.loopState === MprisLoopState.Track
                                || player?.loopState === MprisLoopState.Playlist
                        onClicked: root.cycleLoop()
                    }
                }
            }

            ColumnLayout {
                id: metaIdle
                anchors.centerIn: parent
                width: parent.width
                visible: root.player == null
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("Nothing playing")
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontPixelSize + 3
                    font.bold: true
                    color: WallustColors.sky
                }

                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: qsTr("Start a player with MPRIS support")
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontPixelSize
                    color: WallustColors.buttonHover
                    opacity: 0.85
                }
            }
        }

        Loader {
            id: lyricsLoader
            Layout.leftMargin: root.lyricsVisible ? root.lyricsGap : 0
            Layout.preferredWidth: root.lyricsVisible ? ShellConfig.lyricsPanelWidth : 0
            Layout.maximumWidth: root.lyricsVisible ? ShellConfig.lyricsPanelWidth : 0
            Layout.preferredHeight: root.lyricsVisible ? Math.max(220, mainRow.implicitHeight) : 0
            Layout.alignment: Qt.AlignVCenter
            active: root.lyricsVisible
            sourceComponent: lyricsPanelComponent
        }
    }

    Component {
        id: lyricsPanelComponent
        MediaLyricsPanel {
            width: ShellConfig.lyricsPanelWidth
            height: 220
            active: root.open && root.lyricsVisible
        }
    }

        onOpenChanged: {
            ShellActions.mediaPanelOpen = open
            if (open) {
                MprisPlaybackClock.nudgeTiming()
                if (player)
                    MprisLengthProbe.forceRequest(player)
                Qt.callLater(forceActiveFocus)
            } else {
                openTimingKick.bursts = 0
            }
        }

    Keys.onPressed: event => {
        if (!open)
            return
        if (event.key === Qt.Key_Escape) {
            ShellActions.closeMiddleSurface?.()
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Tab) {
            cyclePlayer(event.modifiers & Qt.ShiftModifier)
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Space) {
            player?.togglePlaying()
            event.accepted = true
            return
        }
        const t = event.text
        if (t === "h") { player?.previous(); event.accepted = true; return }
        if (t === "l") { player?.next(); event.accepted = true; return }
        if (t === "s") {
            if (player?.shuffleSupported) player.shuffle = !player.shuffle
            event.accepted = true
            return
        }
        if (t === "r") { cycleLoop(); event.accepted = true; return }
        if (t === "y" || (event.key === Qt.Key_L && (event.modifiers & Qt.ShiftModifier))) {
            lyricsVisible = !lyricsVisible
            event.accepted = true
            return
        }
        if (lyricsVisible && lyricsLoader.item) {
            const panel = lyricsLoader.item
            if (t === "j" || event.key === Qt.Key_Down) {
                if (panel.stepManualLine)
                    panel.stepManualLine(1)
                else
                    seekBy(10)
                event.accepted = true
                return
            }
            if (t === "k" || event.key === Qt.Key_Up) {
                if (panel.stepManualLine)
                    panel.stepManualLine(-1)
                else
                    seekBy(-10)
                event.accepted = true
                return
            }
        }
        if (t === "j" || event.key === Qt.Key_Down) { seekBy(10); event.accepted = true; return }
        if (t === "k" || event.key === Qt.Key_Up) { seekBy(-10); event.accepted = true }
    }

    Behavior on opacity {
        enabled: fadeWithMorph
        NumberAnimation {
            duration: Motion.standard
            easing.type: Easing.OutCubic
        }
    }
}