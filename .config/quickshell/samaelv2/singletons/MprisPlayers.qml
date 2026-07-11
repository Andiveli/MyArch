pragma Singleton

import QtQuick
import Quickshell.Services.Mpris

/** Active MPRIS player + cover URL (mpris:artUrl / trackArtUrl + YouTube watch fallback). */
QtObject {
    id: root

    property var manualActive: null
    /** Bump when metadata/length arrives so UI re-reads mpris:length (Firefox). */
    property int timingRevision: 0
    /** Set by refreshActiveTrackLength(); bindings on metadata alone miss late mpris:length. */
    property real activeTrackLengthSec: 0

    function isProxy(p) {
        return (p && p.dbusName ? p.dbusName : "").toLowerCase().indexOf("playerctld") >= 0
    }

    function filterDuplicatePlayers(players) {
        const filtered = []
        const used = new Set()
        for (let i = 0; i < players.length; ++i) {
            if (used.has(i))
                continue
            const p1 = players[i]
            const group = [i]
            for (let j = i + 1; j < players.length; ++j) {
                const p2 = players[j]
                if (p1.trackTitle && p2.trackTitle
                        && (p1.trackTitle.includes(p2.trackTitle) || p2.trackTitle.includes(p1.trackTitle))
                        || (Math.abs(p1.position - p2.position) <= 2 && Math.abs(p1.length - p2.length) <= 2))
                    group.push(j)
            }
            let chosenIdx = group.find(idx => players[idx].trackArtUrl?.length > 0)
            if (chosenIdx === undefined)
                chosenIdx = group[0]
            filtered.push(players[chosenIdx])
            group.forEach(idx => used.add(idx))
        }
        return filtered
    }

    readonly property var list: {
        const all = Mpris.players ? Mpris.players.values : []
        const raw = []
        for (let i = 0; i < all.length; i++)
            if (all[i] && !isProxy(all[i]))
                raw.push(all[i])
        return filterDuplicatePlayers(raw)
    }

    readonly property var activePlayer: {
        if (manualActive) {
            const l0 = list
            for (let i = 0; i < l0.length; i++)
                if (l0[i] === manualActive)
                    return manualActive
        }
        const l = list
        if (l.length === 0)
            return null
        for (let i = 0; i < l.length; i++)
            if (l[i].isPlaying)
                return l[i]
        for (let i = 0; i < l.length; i++) {
            const t = l[i].trackTitle
            if (t && String(t).length > 0)
                return l[i]
        }
        return l[0]
    }

    function getIdentity(player) {
        if (!player)
            return ""
        const dbus = player.dbusName ?? ""
        const shortName = dbus.replace(/^org\.mpris\.MediaPlayer2\./, "")
        return player.identity?.length ? player.identity : shortName
    }

    function normalizeArtUrl(raw) {
        const u = String(raw ?? "").trim()
        if (!u.length)
            return ""
        if (u.startsWith("file://") || u.startsWith("http://") || u.startsWith("https://"))
            return u
        if (u.startsWith("/"))
            return "file://" + u
        return u
    }

    function lengthFromMetadataValue(raw) {
        if (raw === undefined || raw === null)
            return 0
        let n = Number(raw)
        if ((!isFinite(n) || n <= 0) && typeof raw === "string")
            n = Number(raw.trim())
        if (!isFinite(n) || n <= 0)
            return 0
        // MPRIS / xesam often use microseconds; browsers may send ms or seconds.
        if (n >= 1e7)
            return n / 1e6
        if (n >= 1e4)
            return n / 1000
        return n
    }

    /** True when dbus exposes a readable position (Zen/Firefox sometimes lie about positionSupported). */
    function hasUsablePosition(player) {
        if (!player)
            return false
        if (player.positionSupported)
            return true
        const pos = Number(player.position)
        return isFinite(pos) && pos >= 0
    }

    function readPositionSec(player) {
        if (!player)
            return 0
        const pos = Number(player.position)
        if (!isFinite(pos) || pos < 0)
            return 0
        return pos
    }

        function metadataLengthSec(player) {
            const md = player?.metadata
            if (!md)
                return 0
            for (const key of ["mpris:length", "xesam:length", "mpris:duration"]) {
                const sec = lengthFromMetadataValue(md[key])
                if (sec > 0)
                    return sec
            }
            const keys = Object.keys(md)
            for (let i = 0; i < keys.length; i++) {
                const k = keys[i]
                if (k.indexOf("length") < 0 && k.indexOf("duration") < 0)
                    continue
                const sec = lengthFromMetadataValue(md[k])
                if (sec > 0)
                    return sec
            }
            return 0
        }

        function trackLengthFromQuickshellOnly(player) {
            if (!player)
                return 0
            const metaLen = metadataLengthSec(player)
            if (player.lengthSupported) {
                const propLen = Number(player.length)
                if (isFinite(propLen) && propLen > 0)
                    return propLen
            }
            return metaLen > 0 ? metaLen : 0
        }

        /**
         * Quickshell MprisPlayer::length() returns position() when lengthSupported is false.
         */
        function getTrackLengthSec(player) {
            if (!player)
                return 0
            const live = trackLengthFromQuickshellOnly(player)
            if (live > 0)
                return live
            if (player === activePlayer && activeTrackLengthSec > 0)
                return activeTrackLengthSec
            return 0
        }

        function refreshActiveTrackLength() {
            const p = activePlayer
            if (!p) {
                activeTrackLengthSec = 0
                timingRevision++
                return
            }
            const live = trackLengthFromQuickshellOnly(p)
            if (live > 0) {
                if (Math.abs(live - activeTrackLengthSec) > 0.5 || activeTrackLengthSec <= 0)
                    activeTrackLengthSec = live
            } else if (activeTrackLengthSec <= 0 && (p.trackTitle?.length || p.isPlaying)) {
                MprisLengthProbe.request(p, false)
            }
            timingRevision++
        }

    function getPositionSec(player, useClock) {
        if (!player)
            return 0
        if (useClock && MprisPlaybackClock.player === player)
            return MprisPlaybackClock.positionSec
        if (!hasUsablePosition(player))
            return 0
        return readPositionSec(player)
    }

    function getArtUrl(player) {
        if (!player)
            return ""
        if (player.trackArtUrl?.length)
            return normalizeArtUrl(player.trackArtUrl)
        const md = player.metadata
        if (md && md["mpris:artUrl"])
            return normalizeArtUrl(md["mpris:artUrl"])
        const url = player.metadata?.["xesam:url"] ?? ""
        if (typeof url === "string" && url.startsWith("https://www.youtube.com/watch")) {
            const id = url.match(/[?&]v=([\w-]{11})/)?.[1]
            return id ? `https://img.youtube.com/vi/${id}/hqdefault.jpg` : ""
        }
        return ""
    }
}