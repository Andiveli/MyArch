pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.modules.common
import qs.services

/**
 * Samael media layer (Caelestia Players.qml ideas): art fallback, persisted pick.
 */
QtObject {
    id: root

    readonly property var rawPlayers: MprisController.players ?? []
    readonly property var list: filterDuplicatePlayers(rawPlayers)
    readonly property string selectedPlayerKey: Persistent.states.samaelMedia.selectedPlayerKey ?? ""

    readonly property MprisPlayer active: {
        const players = list
        if (!players.length)
            return null
        if (selectedPlayerKey.length) {
            for (let i = 0; i < players.length; ++i) {
                if (playerKey(players[i]) === selectedPlayerKey)
                    return players[i]
            }
        }
        const tracked = MprisController.activePlayer
        if (tracked && players.indexOf(tracked) >= 0)
            return tracked
        return players[0]
    }

    function playerKey(player) {
        if (!player)
            return ""
        if (player.uniqueId !== undefined && player.uniqueId !== null && String(player.uniqueId).length)
            return String(player.uniqueId)
        return player.dbusName ?? ""
    }

    function setActivePlayer(player) {
        if (!player) {
            Persistent.states.samaelMedia.selectedPlayerKey = ""
            MprisController.setActivePlayer(null)
            return
        }
        const key = playerKey(player)
        if (key === selectedPlayerKey && MprisController.trackedPlayer === player)
            return
        Persistent.states.samaelMedia.selectedPlayerKey = key
        MprisController.setActivePlayer(player)
    }

    function getIdentity(player) {
        if (!player)
            return ""
        const dbus = player.dbusName ?? ""
        const shortName = dbus.replace(/^org\.mpris\.MediaPlayer2\./, "")
        return player.identity?.length ? player.identity : shortName
    }

    function getArtUrl(player) {
        if (!player)
            return ""
        if (player.trackArtUrl?.length)
            return player.trackArtUrl
        const url = player.metadata?.["xesam:url"] ?? ""
        if (typeof url === "string" && url.startsWith("https://www.youtube.com/watch")) {
            const id = url.match(/[?&]v=([\w-]{11})/)?.[1]
            return id ? `https://img.youtube.com/vi/${id}/hqdefault.jpg` : ""
        }
        return ""
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
                        || (Math.abs(p1.position - p2.position) <= 2 && Math.abs(p1.length - p2.length) <= 2)) {
                    group.push(j)
                }
            }
            let chosenIdx = group.find(idx => players[idx].trackArtUrl?.length > 0)
            if (chosenIdx === undefined)
                chosenIdx = group[0]
            filtered.push(players[chosenIdx])
            group.forEach(idx => used.add(idx))
        }
        return filtered
    }

    /** Call when MPRIS player list changes (QtObject cannot host Connections). */
    function reconcileSelection() {
        const key = selectedPlayerKey
        if (!key.length)
            return
        if (!list.some(p => playerKey(p) === key) && active)
            Persistent.states.samaelMedia.selectedPlayerKey = playerKey(active)
    }
}