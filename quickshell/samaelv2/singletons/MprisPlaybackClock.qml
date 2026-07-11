pragma Singleton

import QtQuick
import Quickshell.Services.Mpris

/**
 * Smooth playback time (Spotify / browser MPRIS: position is stale unless positionChanged() is polled).
 * Interpolates between polls while Playing.
 */
QtObject {
    id: root

    property int tick: 0
    property real positionSec: 0

    readonly property var player: MprisPlayers.activePlayer
    readonly property bool _pollActive: ShellActions.mediaPanelOpen && player != null

    property real _anchorPos: 0
    property real _anchorMs: 0
    property real _lastPollPos: -1

    function nowMs() {
        return Date.now()
    }

    function syncAnchor(pos) {
        _anchorPos = pos
        _anchorMs = nowMs()
        positionSec = pos
        tick++
    }

    function interpolatedPos() {
        const p = player
        if (!MprisPlayers.hasUsablePosition(p))
            return 0
        if (p.playbackState === MprisPlaybackState.Playing) {
            const elapsed = (nowMs() - _anchorMs) / 1000
            const len = MprisPlayers.getTrackLengthSec(p)
            let t = _anchorPos + elapsed
            if (len > 0)
                t = Math.min(t, len)
            return Math.max(0, t)
        }
        return MprisPlayers.readPositionSec(p)
    }

    function refresh() {
        const p = player
        if (!MprisPlayers.hasUsablePosition(p)) {
            positionSec = 0
            tick++
            return
        }
        const pos = MprisPlayers.readPositionSec(p)
        if (p.playbackState === MprisPlaybackState.Playing) {
            if (_lastPollPos < 0 || Math.abs(pos - _lastPollPos) > 0.04) {
                _lastPollPos = pos
                syncAnchor(pos)
                return
            }
        } else {
            _lastPollPos = pos
            syncAnchor(pos)
            return
        }
        positionSec = interpolatedPos()
        tick++
    }

    /** Quickshell: position does not update reactively until positionChanged() is emitted. */
    function pollDBusPosition() {
        const p = player
        if (!p)
            return
        // Quickshell: always poll while a player exists; harmless if unsupported.
        p.positionChanged()
    }

    function bumpTimingRevision() {
        MprisPlayers.timingRevision++
    }

    function nudgeTiming() {
        pollDBusPosition()
        refresh()
        MprisPlayers.refreshActiveTrackLength()
        bumpTimingRevision()
    }

    property Timer _playTick: Timer {
        interval: 50
        repeat: true
        running: root._pollActive && root.player && root.player.playbackState === MprisPlaybackState.Playing
        onTriggered: root.refresh()
    }

    property Timer _dbusPoll: Timer {
        interval: 400
        repeat: true
            running: root._pollActive
                    && root.player.playbackState === MprisPlaybackState.Playing

        onTriggered: root.pollDBusPosition()
    }

    property Timer _lengthPoll: Timer {
        interval: 350
        repeat: true
            running: root._pollActive
            onTriggered: MprisPlayers.refreshActiveTrackLength()

    }

    property Timer _pausePoll: Timer {
        interval: 300
        repeat: true
            running: root._pollActive
                    && root.player.playbackState === MprisPlaybackState.Paused

        onTriggered: {
            root.pollDBusPosition()
            root.refresh()
        }
    }

        property Connections _playerConn: Connections {
            enabled: root._pollActive
            target: root.player

            function onPositionChanged() {
                root.refresh()
                MprisPlayers.refreshActiveTrackLength()
            }
        function onPlaybackStateChanged() {
            root._lastPollPos = -1
            root.pollDBusPosition()
            root.refresh()
        }
            function onTrackTitleChanged() {
                root._lastPollPos = -1
                root.pollDBusPosition()
                root.refresh()
                MprisPlayers.refreshActiveTrackLength()
                if (root.player)
                    MprisLengthProbe.forceRequest(root.player)
                root.bumpTimingRevision()
            }
        function onMetadataChanged() {
            root.pollDBusPosition()
            root.refresh()
            MprisPlayers.refreshActiveTrackLength()
            root.bumpTimingRevision()
        }
        function onLengthChanged() {
            root.tick++
            root.bumpTimingRevision()
        }
    }

    onPlayerChanged: {
        if (!ShellActions.mediaPanelOpen)
        return
        _lastPollPos = -1
        pollDBusPosition()
        refresh()
        bumpTimingRevision()
    }
}