pragma Singleton

import QtQuick
import Caelestia.Config
import Caelestia.Services

/** Caelestia paths + optional hook for other surfaces (panel mirrors samael Lyrics.setTrack). */
Item {
    id: root

    function applyPathsFromConfig() {
        if (typeof GlobalConfig === "undefined" || !GlobalConfig.paths)
            return
        const dir = ShellConfig.lyricsDirExpanded
        if (dir.length && GlobalConfig.paths.lyricsDir !== dir)
            GlobalConfig.paths.lyricsDir = dir
        const backend = ShellConfig.lyricsBackend
        if (backend.length && GlobalConfig.services && GlobalConfig.services.lyricsBackend !== backend)
            GlobalConfig.services.lyricsBackend = backend
    }

    readonly property var lines: Lyrics.lyrics
    readonly property bool hasLyrics: Lyrics.hasLyrics
    readonly property bool loading: Lyrics.loading

    function indexForTime(t) { return Lyrics.indexForTime(t) }
    function timeForIndex(i) { return Lyrics.timeForIndex(i) }

    Component.onCompleted: {
        applyPathsFromConfig()
        Qt.callLater(applyPathsFromConfig)
    }

    Timer {
        interval: 400
        running: true
        repeat: false
        onTriggered: root.applyPathsFromConfig()
    }
}
