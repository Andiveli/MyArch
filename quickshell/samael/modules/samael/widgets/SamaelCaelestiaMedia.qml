pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Caelestia.Components
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.components.widgets
import qs.services
import qs.utils
import qs.modules.samael

/**
 * Caelestia dashboard Media (vertical) or bar drop (horizontal: disc | meta + controls).
 * Data: SamaelPlayers. Keys: parent SamaelMediaManager.
 */
Item {
    id: root

    readonly property var active: SamaelPlayers.active

    /** false = vendored dash/Media.qml column; true = bar drop row */
    property bool horizontalBarLayout: false
    /** Total width when horizontal; 0 = dashboard column (Tokens mediaWidth) */
    property int columnWidthOverride: 0
    /** Third column: synced lyrics (Caelestia Lyrics service) */
    property bool showLyricsColumn: true
    /** Radial cava (off until cover art is stable) */
    property bool showCavaRing: false
    /** Narrower bar drop + smaller type */
    property bool compactBarDrop: false
    property int barDiscWidth: 228
    property int barMetaWidth: 208
    property int barLyricsWidth: 220

        readonly property int dashColumnWidth: Tokens.sizes.dashboard.mediaWidth
        readonly property int discColumnWidth: horizontalBarLayout
        ? (compactBarDrop ? barDiscWidth : 268)
        : dashColumnWidth
        readonly property int metaStripWidth: horizontalBarLayout && compactBarDrop ? barMetaWidth : 248
        readonly property int lyricsColumnWidth: horizontalBarLayout && compactBarDrop
        ? barLyricsWidth
        : Tokens.sizes.dashboard.mediaSectionWidth
        readonly property int barRowSpacing: compactBarDrop && horizontalBarLayout
        ? Tokens.spacing.medium
        : Tokens.spacing.large
        readonly property int columnWidth: horizontalBarLayout
            ? (columnWidthOverride > 0 ? columnWidthOverride
                : discColumnWidth + Tokens.spacing.large + metaStripWidth
                    + (showLyricsColumn ? Tokens.spacing.large + lyricsColumnWidth : 0))
            : (columnWidthOverride > 0 ? columnWidthOverride : dashColumnWidth)

        readonly property int metaColumnWidth: horizontalBarLayout ? metaStripWidth : columnWidth

    /** Vim focus ring 0=shuffle … 4=loop (from SamaelMediaManager) */
    property int controlFocusIndex: -1

    function lengthStr(length) {
        if (length < 0 || isNaN(length))
            return "-:--"
        const hours = Math.floor(length / 3600)
        const mins = Math.floor((length % 3600) / 60)
        const secs = Math.floor(length % 60).toString().padStart(2, "0")
        if (hours > 0)
            return `${hours}:${mins.toString().padStart(2, "0")}:${secs}`
        return `${mins}:${secs}`
    }

    function cycleLoopState() {
        const p = active
        if (!p?.loopSupported)
            return
        const state = p.loopState
        if (state === MprisLoopState.None)
            p.loopState = MprisLoopState.Track
        else if (state === MprisLoopState.Track)
            p.loopState = MprisLoopState.Playlist
        else
            p.loopState = MprisLoopState.None
    }

    function toggleShuffle() {
        const p = active
        if (p?.shuffleSupported)
            p.shuffle = !p.shuffle
    }

    function stepLyrics(delta: int): void {
        if (showLyricsColumn && lyricPanel)
            lyricPanel.stepManualLine(delta)
    }

    property real playerProgress: {
        const p = active
        if (!p?.length)
            return 0
        const len = p.length
        const pos = len > 0 ? ((p.position % len) + len) % len : p.position
        return pos / len
    }

    readonly property real arcCoverGap: Tokens.spacing.extraSmall

    implicitWidth: columnWidth
    implicitHeight: horizontalBarLayout
        ? Math.max(rowLayout.implicitHeight, showLyricsColumn ? (compactBarDrop ? 248 : 280) : 0)
        : verticalRoot.implicitHeight
    width: implicitWidth
    height: implicitHeight

    Behavior on playerProgress {
        Anim {
            type: Anim.StandardLarge
        }
    }

    Timer {
        running: active?.playbackState === MprisPlaybackState.Playing
        interval: (typeof GlobalConfig !== "undefined" && GlobalConfig.dashboard)
            ? GlobalConfig.dashboard.mediaUpdateInterval
            : 500
        triggeredOnStart: true
        repeat: true
        onTriggered: active?.positionChanged()
    }

    function syncPlayersActive() {
        if (!active)
            return
        if (Players.manualActive !== active)
            Players.manualActive = active
    }

    Component.onCompleted: syncPlayersActive()

    Connections {
        target: MprisController
        function onPlayersChanged() {
            root.syncPlayersActive()
        }
    }

    // —— Bar drop: | disc | title/album/artist + controls ——
    RowLayout {
        id: rowLayout
        visible: horizontalBarLayout
        anchors.fill: parent
        spacing: root.barRowSpacing

        Item {
            id: discHost
            clip: false
            Layout.preferredWidth: discColumnWidth
            Layout.preferredHeight: discColumnWidth
            Layout.alignment: Qt.AlignVCenter

            readonly property int arcThick: Tokens.sizes.dashboard.mediaProgressThickness
            readonly property int strokePx: Math.max(arcThick, 5)
            /** Wavy ring needs ~stroke×(1+2×amp)×2 margin; avoid binding to progRow.thickness (layout cycle) */
            readonly property real ringMargin: strokePx * 3.2
            readonly property real coverSide: Math.max(100,
                discColumnWidth - (Tokens.padding.medium + root.arcCoverGap + ringMargin) * 2)
            readonly property real ringSize: coverSide + root.arcCoverGap + ringMargin * 2

            SamaelCoverArt {
                id: coverRow
                z: 1
                anchors.centerIn: parent
                width: discHost.coverSide
                height: discHost.coverSide
            }

            CircularProgress {
                id: progRow
                z: 3
                anchors.centerIn: parent
                width: discHost.ringSize
                height: discHost.ringSize
                fgColour: Colours.palette.m3primary
                strokeWidth: discHost.strokePx
                startAngle: -90 - sweepAngle / 2
                sweepAngle: Tokens.sizes.dashboard.mediaProgressSweep
                value: root.playerProgress
                wavy: true
                waveFrequency: 8
                waveAmplitude: 0.65
                waveDuration: 2000
                wavePaused: !(active?.playbackState === MprisPlaybackState.Playing)
            }
        }

            ColumnLayout {
                id: metaColumn
                Layout.preferredWidth: metaColumnWidth
                Layout.maximumWidth: metaColumnWidth
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignVCenter
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    Layout.fillWidth: true
                    animate: true
                    text: (active?.trackTitle ?? "") || qsTr("Unknown title")
                    font: root.compactBarDrop ? Tokens.font.title.small : Tokens.font.title.medium
                    color: Colours.palette.m3primary
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    animate: true
                    text: active?.trackArtist || qsTr("Unknown artist")
                    color: Colours.palette.m3onSurfaceVariant
                    font: root.compactBarDrop ? Tokens.font.body.small : Tokens.font.title.small
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    animate: true
                    text: active?.trackAlbum || qsTr("Unknown album")
                    color: Colours.palette.m3secondary
                    font: root.compactBarDrop ? Tokens.font.body.small : Tokens.font.title.small
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: SamaelPlayers.list.length > 1
                    text: `${SamaelPlayers.getIdentity(active)} · Tab`
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                    elide: Text.ElideRight
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Tokens.spacing.small
                    spacing: Tokens.spacing.small

                    TextMetrics {
                        id: timeMetrics
                        text: active ? root.lengthStr(Math.max(active.position, active.length)).replace(/[1-9]/g, "0") : "00:00"
                        font: root.compactBarDrop ? Tokens.font.label.small : Tokens.font.label.medium
                    }

                    StyledText {
                        id: positionLabel
                        Layout.preferredWidth: timeMetrics.width
                        text: root.lengthStr(active?.position ?? -1)
                        color: Colours.palette.m3onSurfaceVariant
                        font: timeMetrics.font
                        horizontalAlignment: Text.AlignHCenter
                    }

                    StyledSlider {
                        id: positionSlider
                        Layout.fillWidth: true
                        value: active ? active.position / (active.length || 1) : 0
                        enabled: active?.canSeek ?? false
                        wavy: true
                        animateWave: active?.playbackState === MprisPlaybackState.Playing
                        waveFrequency: 5
                        waveDuration: 2000
                        interactionOnMove: false
                        onInteraction: value => {
                            const p = active
                            if (p?.canSeek && p?.positionSupported)
                                p.position = value * p.length
                        }

                        Binding {
                            target: positionLabel
                            property: "text"
                            value: root.lengthStr(positionSlider.pos * (active?.length ?? 0))
                            when: positionSlider.dragging
                        }
                    }

                    StyledText {
                        Layout.preferredWidth: timeMetrics.width
                        text: root.lengthStr(active?.length ?? -1)
                        color: Colours.palette.m3onSurfaceVariant
                        font: timeMetrics.font
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                ButtonRow {
                    id: controlsRow
                    Layout.fillWidth: true
                    Layout.topMargin: Tokens.spacing.small
                    spacing: Tokens.spacing.extraSmall

                    IconButton {
                        type: IconButton.Tonal
                        icon: "shuffle"
                        isRound: true
                        shapeMorph: true
                        checked: (active?.shuffle ?? false) || controlFocusIndex === 0
                        font: Tokens.font.icon.builders.medium.weight(Font.Medium).build()
                        disabled: !active?.shuffleSupported
                        implicitWidth: Math.round(implicitHeight * 0.9)
                        onClicked: root.toggleShuffle()
                    }

                    IconButton {
                        type: IconButton.Tonal
                        icon: "skip_previous"
                        isRound: true
                        shapeMorph: true
                        checked: controlFocusIndex === 1
                        font: Tokens.font.icon.medium
                        implicitWidth: root.compactBarDrop ? 34 : 40
                        implicitHeight: root.compactBarDrop ? 34 : 40
                        disabled: !active?.canGoPrevious
                        onClicked: active?.previous()
                    }

                    IconButton {
                        icon: active?.playbackState === MprisPlaybackState.Playing ? "pause" : "play_arrow"
                        isRound: true
                        shapeMorph: true
                        fillWidth: false
                        Layout.preferredWidth: root.compactBarDrop ? 38 : 44
                        Layout.preferredHeight: root.compactBarDrop ? 38 : 44
                        checked: (active?.playbackState === MprisPlaybackState.Playing) || controlFocusIndex === 2
                        font: Tokens.font.icon.medium
                        disabled: !active?.canTogglePlaying
                        onClicked: active?.togglePlaying()
                    }

                    IconButton {
                        type: IconButton.Tonal
                        icon: "skip_next"
                        isRound: true
                        shapeMorph: true
                        checked: controlFocusIndex === 3
                        font: Tokens.font.icon.medium
                        implicitWidth: root.compactBarDrop ? 34 : 40
                        implicitHeight: root.compactBarDrop ? 34 : 40
                        disabled: !active?.canGoNext
                        onClicked: active?.next()
                    }

                    IconButton {
                        type: IconButton.Tonal
                        icon: active?.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
                        isRound: true
                        shapeMorph: true
                        checked: (active?.loopState === MprisLoopState.Track
                            || active?.loopState === MprisLoopState.Playlist) || controlFocusIndex === 4
                        font: Tokens.font.icon.builders.medium.weight(Font.Medium).build()
                        disabled: !active?.loopSupported
                        implicitWidth: Math.round(implicitHeight * 0.9)
                        onClicked: root.cycleLoopState()
                    }
                }
            }

            ColumnLayout {
                visible: showLyricsColumn
                Layout.preferredWidth: lyricsColumnWidth
                Layout.fillHeight: true
                    Layout.minimumHeight: root.compactBarDrop ? 220 : 260
                    Layout.alignment: Qt.AlignTop
                    spacing: Tokens.spacing.small

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small

                        MaterialIcon {
                            text: "lyrics"
                            fontStyle: root.compactBarDrop
                                ? Tokens.font.icon.builders.small.build()
                                : Tokens.font.icon.medium
                            color: Colours.palette.m3primary
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Lyrics")
                            font: root.compactBarDrop ? Tokens.font.label.medium : Tokens.font.title.small
                        color: Colours.palette.m3onSurface
                    }
                }

                SamaelLyricList {
                    id: lyricPanel
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: root.compactBarDrop ? 168 : 200
                }
            }
        }

    // —— Dashboard-style vertical column (reference) ——
    Item {
        id: verticalRoot
        visible: !horizontalBarLayout
        width: columnWidth
        implicitWidth: columnWidth
        implicitHeight: controls.y + controls.height + Tokens.padding.large

        CircularProgress {
            id: prog
            anchors.centerIn: cover
            implicitSize: cover.width + root.arcCoverGap + thickness * 2
            fgColour: Colours.palette.m3primary
            strokeWidth: Tokens.sizes.dashboard.mediaProgressThickness
            startAngle: -90 - sweepAngle / 2
            sweepAngle: Tokens.sizes.dashboard.mediaProgressSweep
            value: root.playerProgress
            wavy: true
            waveFrequency: 8
            waveDuration: 2000
            wavePaused: !(active?.playbackState === MprisPlaybackState.Playing)
        }

        CoverArt {
            id: cover
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Tokens.padding.medium + root.arcCoverGap + prog.thickness
            implicitHeight: width
        }

        StyledText {
            id: title
            anchors.top: cover.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: Tokens.spacing.medium
            animate: true
            horizontalAlignment: Text.AlignHCenter
            text: (active?.trackTitle ?? qsTr("No media")) || qsTr("Unknown title")
            color: Colours.palette.m3primary
            font: Tokens.font.title.small
            width: root.columnWidth - Tokens.padding.extraLargeIncreased
            elide: Text.ElideRight
        }

        StyledText {
            id: album
            anchors.top: title.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: Tokens.spacing.small
            animate: true
            horizontalAlignment: Text.AlignHCenter
            text: (active?.trackAlbum ?? qsTr("No media")) || qsTr("Unknown album")
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
            width: root.columnWidth - Tokens.padding.extraLargeIncreased
            elide: Text.ElideRight
        }

        StyledText {
            id: artist
            anchors.top: album.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: Tokens.spacing.small
            animate: true
            horizontalAlignment: Text.AlignHCenter
            text: (active?.trackArtist ?? qsTr("No media")) || qsTr("Unknown artist")
            color: Colours.palette.m3secondary
            font: Tokens.font.body.small
            width: root.columnWidth - Tokens.padding.extraLargeIncreased
            elide: Text.ElideRight
        }

        ButtonRow {
            id: controls
            anchors.top: artist.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: Tokens.spacing.medium
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.extraSmall

            IconButton {
                type: IconButton.Tonal
                icon: "skip_previous"
                isRound: true
                shapeMorph: true
                disabled: !active?.canGoPrevious
                onClicked: active?.previous()
            }

            IconButton {
                fillWidth: true
                icon: active?.playbackState === MprisPlaybackState.Playing ? "pause" : "play_arrow"
                isRound: true
                shapeMorph: true
                checked: active?.playbackState === MprisPlaybackState.Playing
                disabled: !active?.canTogglePlaying
                onClicked: active?.togglePlaying()
            }

            IconButton {
                type: IconButton.Tonal
                icon: "skip_next"
                isRound: true
                shapeMorph: true
                disabled: !active?.canGoNext
                onClicked: active?.next()
            }
        }
    }
}