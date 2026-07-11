pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Firefox/Zen: Quickshell metadata often omits mpris:length until a seek;
 * playerctl sees it immediately — same source as manual debugging.
 */
Singleton {
    id: root

    property string probeTarget: ""
    property int lastProbeMs: 0
    property int probeCooldownMs: 450

    function playerShortName(player) {
        if (!player)
            return ""
        const dbus = String(player.dbusName ?? "")
        return dbus.replace(/^org\.mpris\.MediaPlayer2\./, "")
    }

    function request(player, force) {
        const short = playerShortName(player)
        if (!short.length)
            return
        const now = Date.now()
        if (!force && now - lastProbeMs < probeCooldownMs)
            return
        lastProbeMs = now
        probeTarget = short
        lengthProc.running = true
    }

    function forceRequest(player) {
        request(player, true)
    }

    function ingestRawLength(raw) {
        const sec = MprisPlayers.lengthFromMetadataValue(raw)
        if (sec > 0) {
            MprisPlayers.activeTrackLengthSec = sec
            MprisPlayers.timingRevision++
        }
    }

    Process {
        id: lengthProc
        running: false
        command: ["bash", "-c",
            "p=\"$1\"; " +
            "v=$(playerctl -p \"$p\" metadata --format '{{mpris:length}}' 2>/dev/null | head -n1); " +
            "if [ -z \"$v\" ] || [ \"$v\" = \"\" ]; then " +
            "  v=$(playerctl -p \"$p\" metadata 2>/dev/null | grep -m1 'mpris:length' | awk '{print $NF}'); " +
            "fi; " +
            "echo -n \"$v\"",
            "_", root.probeTarget]
        stdout: StdioCollector {
            onStreamFinished: {
                root.ingestRawLength(text)
                lengthProc.running = false
            }
        }
        onExited: lengthProc.running = false
    }
}