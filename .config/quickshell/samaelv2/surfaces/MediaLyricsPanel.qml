import QtQuick
import QtQuick.Controls
import Quickshell.Services.Mpris
import Caelestia.Config
import Caelestia.Services
import "../singletons"
import "../widgets"

/**
 * samael Lyrics wiring + Apple-ish scroll + per-word highlight (approximation).
 *
 * Track metadata changes (new song, title resolving after player connects) are
 * detected via side-effect binding (readonly property var _), matching samael ref.
 */
Item {
    id: root

    property bool active: true
    readonly property var player: MprisPlayers.activePlayer

    readonly property var lyricList: Lyrics.lyrics
    readonly property bool hasLyrics: Lyrics.hasLyrics
    readonly property bool loading: Lyrics.loading
    readonly property real edgeFade: 0.12

    readonly property real playbackSec: {
        MprisPlaybackClock.tick
        return MprisPlaybackClock.positionSec
    }

    /**
     * Guard: _ skips the first evaluation (runs during construction before config
     * is applied). Component.onCompleted applies config then sets _ready = true,
     * triggering a real _ evaluation with correct paths.
     */
    property bool _ready: false

    /** Side-effect binding: re-evaluates when player or track metadata changes (ref: samael SamaelLyricList). */
    readonly property var _: {
        if (!_ready) return
        const p = player
        if (p)
            Lyrics.setTrack(p.trackArtist, p.trackTitle, p.trackAlbum, p.length)
        else
            Lyrics.clearTrack()
    }

    Component.onCompleted: {
        LyricsService.applyPathsFromConfig()
        _ready = true
    }

    function stepManualLine(delta) {
        if (!lyricList.length)
            return
        let i = list.currentIndex
        if (i < 0)
            i = Lyrics.indexForTime(MprisPlayers.getPositionSec(player, true))
        i = Math.max(0, Math.min(lyricList.length - 1, i + delta))
        list.currentIndex = i
        list.positionViewAtIndex(i, ListView.Center)
    }

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
                id: list
                anchors.fill: parent
                visible: root.hasLyrics && !root.loading
                clip: true
                model: root.lyricList
                spacing: 6
                boundsBehavior: Flickable.StopAtBounds
                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: height * 0.38
                preferredHighlightEnd: height * 0.62
                highlightMoveDuration: 520
                highlightMoveVelocity: -1
                snapMode: ListView.SnapToItem

                displaced: Transition {
                    NumberAnimation {
                        properties: "y"
                        duration: Motion.standard
                        easing.type: Easing.OutCubic
                    }
                }

                Component.onCompleted: {
                    currentIndex = Qt.binding(function() {
                        root._
                        root.playbackSec
                        return Lyrics.indexForTime(MprisPlayers.getPositionSec(player, true))
                    })
                    positionViewAtIndex(currentIndex, ListView.Center)
                }

                onModelChanged: Qt.callLater(() => positionViewAtIndex(currentIndex, ListView.Center))

                onCurrentIndexChanged: {
                    if (currentIndex >= 0)
                        positionViewAtIndex(currentIndex, ListView.Center)
                }

                delegate: Item {
                    id: lineHost
                    required property int index
                    required property string modelData

                    width: list.width
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
                        lineText: modelData
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

            Rectangle {
                anchors.fill: parent
                visible: root.hasLyrics
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0; color: Qt.rgba(WallustColors.moduleBackground.r,
                        WallustColors.moduleBackground.g, WallustColors.moduleBackground.b, 0.92) }
                    GradientStop { position: root.edgeFade; color: "transparent" }
                    GradientStop { position: 1 - root.edgeFade; color: "transparent" }
                    GradientStop { position: 1; color: Qt.rgba(WallustColors.moduleBackground.r,
                        WallustColors.moduleBackground.g, WallustColors.moduleBackground.b, 0.92) }
                }
                z: 2
                enabled: false
            }

            Loader {
                id: loadingIndicator
                anchors.centerIn: parent
                asynchronous: true
                active: root.loading
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
                anchors.centerIn: parent
                width: parent.width - 8
                visible: !root.hasLyrics && !root.loading
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("No lyrics found")
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize - 1
                color: WallustColors.buttonHover
            }
        }
    }

    Timer {
        running: root.active
                && player?.playbackState === MprisPlaybackState.Playing
        interval: (typeof GlobalConfig !== "undefined" && GlobalConfig.dashboard)
                ? GlobalConfig.dashboard.mediaUpdateInterval
                : 500
        repeat: true
        onTriggered: {
            if (!list.visible || !root.lyricList.length)
                return
            const i = Lyrics.indexForTime(MprisPlayers.getPositionSec(player, true))
            if (i >= 0 && i !== list.currentIndex)
                list.currentIndex = i
        }
    }
}
