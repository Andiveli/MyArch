pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell.Services.Mpris
import Caelestia.Config
import Caelestia.Services
import "../singletons"
import "../widgets"

/**
 * Lyrics column — same flow as samael SamaelLyricList / caelestia LyricList:
 * binding setTrack, state machine (loading → hasLyrics | noLyrics), flag on hasLyricsChanged.
 */
Item {
    id: root

    property bool active: true
    readonly property var player: MprisPlayers.activePlayer

    readonly property real fadeAmount: 0.1
    property bool flag
    readonly property list<string> lyricList: Lyrics.lyrics

    readonly property real playbackSec: {
        MprisPlaybackClock.tick
        return MprisPlaybackClock.positionSec
    }

    function trackDurationSec() {
        const p = player
        if (!p)
            return 0
        const len = MprisPlayers.getTrackLengthSec(p)
        if (len > 0)
            return len
        const raw = Number(p.length)
        if (isFinite(raw) && raw > 0 && p.lengthSupported)
            return raw
        return 0
    }

    function syncLyricsTrack() {
        LyricsService.applyPathsFromConfig()
        const p = player
        if (!p || !root.active) {
            Lyrics.clearTrack()
            return
        }
        Lyrics.setTrack(p.trackArtist, p.trackTitle, p.trackAlbum, trackDurationSec())
    }

    // Caelestia "funny binding hack" — re-runs when player/metadata changes
    readonly property var _: {
        flag
        MprisPlayers.timingRevision
        trackDurationSec()
        const p = player
        if (!root.active) {
            return
        }
        if (p)
            Lyrics.setTrack(p.trackArtist, p.trackTitle, p.trackAlbum, trackDurationSec())
        else
            Lyrics.clearTrack()
    }

    Component.onCompleted: {
        LyricsService.applyPathsFromConfig()
        syncLyricsTrack()
    }

    onActiveChanged: {
        if (active) {
            LyricsService.applyPathsFromConfig()
            Qt.callLater(syncLyricsTrack)
        }
    }

    Connections {
        target: Lyrics
        function onHasLyricsChanged() {
            root.flag = !root.flag
        }
        function onLoadingChanged() {
            if (!Lyrics.loading && !Lyrics.hasLyrics && root.active && player)
                Qt.callLater(root.syncLyricsTrack)
        }
    }

    state: {
        flag
        if (Lyrics.hasLyrics)
            return "hasLyrics"
        if (Lyrics.loading)
            return "loading"
        return "noLyrics"
    }

    states: [
        State {
            name: "loading"
            PropertyChanges { target: loadingIndicator; opacity: 1 }
            PropertyChanges { target: lyricsList; opacity: 0 }
            PropertyChanges { target: noLyrics; opacity: 0 }
        },
        State {
            name: "hasLyrics"
            PropertyChanges { target: loadingIndicator; opacity: 0 }
            PropertyChanges { target: lyricsList; opacity: 1 }
            PropertyChanges { target: noLyrics; opacity: 0 }
        },
        State {
            name: "noLyrics"
            PropertyChanges { target: loadingIndicator; opacity: 0 }
            PropertyChanges { target: lyricsList; opacity: 0 }
            PropertyChanges { target: noLyrics; opacity: 1 }
        }
    ]

    Column {
        anchors.fill: parent
        spacing: 6

        Text {
            width: parent.width
            text: "\uf001  " + qsTr("Lyrics")
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize
            color: WallustColors.moduleText
        }

        Item {
            width: parent.width
            height: parent.height - parent.spacing - 22

            ListView {
                id: lyricsList
                anchors.fill: parent
                anchors.topMargin: parent.height * root.fadeAmount / 2
                anchors.bottomMargin: parent.height * root.fadeAmount / 2
                clip: true
                model: root.lyricList
                spacing: 6
                opacity: 0
                boundsBehavior: Flickable.StopAtBounds
                highlightRangeMode: ListView.ApplyRange
                highlightMoveDuration: 520
                highlightMoveVelocity: -1
                preferredHighlightBegin: (height - (currentItem?.height ?? 0)) / 2
                preferredHighlightEnd: (height + (currentItem?.height ?? 0)) / 2

                Component.onCompleted: {
                    currentIndex = Qt.binding(function() {
                        root._
                        root.playbackSec
                        return Lyrics.indexForTime(MprisPlayers.getPositionSec(player, true))
                    })
                    positionViewAtIndex(currentIndex, ListView.Center)
                }
                onModelChanged: Qt.callLater(() => positionViewAtIndex(currentIndex, ListView.Center))

                delegate: Item {
                    id: lineHost
                    required property int index
                    required property string modelData

                    width: lyricsList.width
                    height: lyricRow.height

                    readonly property bool isCurrent: ListView.isCurrentItem
                    scale: isCurrent ? 1.03 : 0.92
                    opacity: isCurrent ? 1 : 0.5
                    transformOrigin: Item.Left

                    Behavior on scale {
                        NumberAnimation { duration: 420; easing.type: Easing.OutCubic }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: 360; easing.type: Easing.OutCubic }
                    }

                    MediaLyricLine {
                        id: lyricRow
                        width: lineHost.width
                        lineText: modelData || ". . ."
                        lineIndex: index
                        lineCount: root.lyricList.length
                        isCurrent: lineHost.isCurrent
                        playbackSec: root.playbackSec
                        playerRef: player
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const p = player
                            const t = Lyrics.timeForIndex(index)
                            if (p?.canSeek && MprisPlayers.hasUsablePosition(p) && t >= 0)
                                p.position = t
                        }
                    }
                }
            }

            Loader {
                id: loadingIndicator
                anchors.centerIn: parent
                asynchronous: true
                active: opacity > 0
                opacity: 0
                sourceComponent: Column {
                    spacing: 8
                    LoadingIndicator {
                        anchors.horizontalCenter: parent.horizontalCenter
                        implicitSize: 36
                        containsIcon: true
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: qsTr("Loading lyrics…")
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize - 1
                        color: WallustColors.buttonHover
                    }
                }
            }

            Text {
                id: noLyrics
                anchors.centerIn: parent
                width: parent.width - 8
                opacity: 0
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("No lyrics found")
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize - 1
                color: WallustColors.buttonHover
            }
        }
    }

    function stepManualLine(delta) {
        if (!root.lyricList.length)
            return
        let i = lyricsList.currentIndex
        if (i < 0)
            i = Lyrics.indexForTime(MprisPlayers.getPositionSec(player, true))
        i = Math.max(0, Math.min(root.lyricList.length - 1, i + delta))
        lyricsList.currentIndex = i
        lyricsList.positionViewAtIndex(i, ListView.Center)
    }

    Timer {
        running: root.active && player?.playbackState === MprisPlaybackState.Playing
        interval: (typeof GlobalConfig !== "undefined" && GlobalConfig.dashboard)
                ? GlobalConfig.dashboard.mediaUpdateInterval
                : 500
        repeat: true
        onTriggered: {
            if (lyricsList.opacity > 0 && root.lyricList.length)
                lyricsList.positionViewAtIndex(
                    Lyrics.indexForTime(MprisPlayers.getPositionSec(player, true)),
                    ListView.Center)
        }
    }
}