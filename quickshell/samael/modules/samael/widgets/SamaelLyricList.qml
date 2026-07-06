pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.effects
import qs.services
import qs.modules.samael

/**
 * Caelestia LyricList wired to SamaelPlayers + Lyrics singleton (Caelestia.Services).
 */
Item {
    id: root

    readonly property var active: SamaelPlayers.active

    readonly property var _: {
        const p = active
        if (p)
            Lyrics.setTrack(p.trackArtist, p.trackTitle, p.trackAlbum, p.length)
        else
            Lyrics.clearTrack()
    }

    function syncPlayersForLyrics() {
        if (!active)
            return
        if (Players.manualActive !== active)
            Players.manualActive = active
    }

    Component.onCompleted: syncPlayersForLyrics()

    Connections {
        target: MprisController
        function onPlayersChanged() {
            root.syncPlayersForLyrics()
        }
    }

    readonly property real fadeAmount: 0.1
    property bool flag
    property list<string> lyricList: Lyrics.lyrics

    layer.enabled: true
    layer.effect: Mask {
        maskSource: mask

        Rectangle {
            id: mask
            layer.enabled: true
            visible: false
            implicitWidth: root.width
            implicitHeight: root.height

            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { color: Qt.alpha("black", 0); position: 0 }
                GradientStop { color: Qt.alpha("black", 1); position: root.fadeAmount }
                GradientStop { color: Qt.alpha("black", 1); position: 1 - root.fadeAmount }
                GradientStop { color: Qt.alpha("black", 0); position: 1 }
            }
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
            PropertyChanges { target: lyrics; opacity: 0 }
            PropertyChanges { target: noLyrics; opacity: 0 }
        },
        State {
            name: "hasLyrics"
            PropertyChanges { target: loadingIndicator; opacity: 0 }
            PropertyChanges { target: lyrics; opacity: 1 }
            PropertyChanges { target: noLyrics; opacity: 0 }
        },
        State {
            name: "noLyrics"
            PropertyChanges { target: loadingIndicator; opacity: 0 }
            PropertyChanges { target: lyrics; opacity: 0 }
            PropertyChanges { target: noLyrics; opacity: 1 }
        }
    ]

    Connections {
        target: Lyrics
        function onHasLyricsChanged() {
            root.flag = !root.flag
        }
    }

    Loader {
        id: loadingIndicator
        anchors.centerIn: parent
        asynchronous: true
        active: opacity > 0
        opacity: 0
        sourceComponent: ColumnLayout {
            spacing: Tokens.spacing.medium
            LoadingIndicator {
                Layout.alignment: Qt.AlignHCenter
                implicitSize: 36
                containsIcon: true
            }
            StyledText {
                text: qsTr("Loading lyrics...")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.medium
            }
        }
    }

    Loader {
        id: noLyrics
        anchors.centerIn: parent
        asynchronous: true
        active: opacity > 0
        opacity: 0
        sourceComponent: ColumnLayout {
            spacing: Tokens.spacing.small
            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "sentiment_sad"
                fontStyle: Tokens.font.icon.large
                color: Colours.palette.m3outline
            }
            StyledText {
                text: qsTr("No lyrics found")
                color: Colours.palette.m3outline
                font: Tokens.font.label.medium
            }
        }
    }

    StyledListView {
        id: lyrics

        anchors.fill: parent
        anchors.topMargin: parent.height * root.fadeAmount / 2
        anchors.bottomMargin: parent.height * root.fadeAmount / 2

        displayMarginBeginning: anchors.topMargin
        displayMarginEnd: anchors.bottomMargin

        model: root.lyricList

        Component.onCompleted: {
            currentIndex = Qt.binding(() => {
                model
                return Lyrics.indexForTime(active?.position ?? 0)
            })
            positionViewAtIndex(currentIndex, ListView.Center)
        }
        onModelChanged: Qt.callLater(() => positionViewAtIndex(currentIndex, ListView.Center))

        highlightRangeMode: ListView.ApplyRange
        highlightMoveDuration: Tokens.anim.durations.large
        highlightMoveVelocity: -1
        preferredHighlightBegin: (height - (currentItem?.implicitHeight ?? 0)) / 2
        preferredHighlightEnd: (height + (currentItem?.implicitHeight ?? 0)) / 2

        spacing: Tokens.spacing.small
        opacity: 0

        delegate: StyledText {
            id: lyric
            required property string modelData
            required property int index
            property real effectScale: ListView.isCurrentItem ? 1 : 0

            anchors.left: lyrics.contentItem.left
            anchors.right: lyrics.contentItem.right

            text: modelData || ". . ."
            color: ListView.isCurrentItem ? Colours.palette.m3primary
                : mouse.containsMouse ? Colours.palette.m3onSurface : Colours.palette.m3outline
            font: Tokens.font.body.small
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere

            Behavior on effectScale {
                Anim { type: Anim.SlowEffects }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    const p = active
                    if (p?.canSeek && p.positionSupported)
                        p.position = Lyrics.timeForIndex(lyric.index)
                }
            }
        }
    }

    /** Manual vim step (j/k) without seeking playback */
    function stepManualLine(delta: int): void {
        if (!root.lyricList.length)
        return
        const n = root.lyricList.length
        let i = lyrics.currentIndex
        if (i < 0)
        i = Lyrics.indexForTime(active?.position ?? 0)
        i = Math.max(0, Math.min(n - 1, i + delta))
        lyrics.currentIndex = i
        lyrics.positionViewAtIndex(i, ListView.Center)
    }

    Timer {
        running: active?.playbackState === MprisPlaybackState.Playing
        interval: (typeof GlobalConfig !== "undefined" && GlobalConfig.dashboard)
            ? GlobalConfig.dashboard.mediaUpdateInterval
            : 500
        repeat: true
        onTriggered: {
            if (lyrics.opacity > 0 && root.lyricList.length)
                lyrics.positionViewAtIndex(
                    Lyrics.indexForTime(active?.position ?? 0),
                    ListView.Center)
        }
    }
}