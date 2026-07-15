pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

/**
 * Live PipeWire streams + sinks; per-stream control and optional MPRIS.
 */
Singleton {
    id: root

    property var sinks: []
    property var streams: []
    property bool loading: false
    property string lastError: ""
    property int revision: 0

    readonly property string configPath: Quickshell.shellPath("config.json")

    function bump() {
        revision++
    }

    function patchStreamLocal(streamId, patch) {
        const sid = String(streamId)
        const arr = streams.slice()
        let hit = false
        for (let i = 0; i < arr.length; i++) {
            if (String(arr[i].id) === sid) {
                arr[i] = Object.assign({}, arr[i], patch)
                hit = true
                break
            }
        }
        if (hit) {
            streams = arr
            bump()
        }
    }

    function streamById(id) {
        const sid = String(id)
        for (let i = 0; i < streams.length; i++)
            if (String(streams[i].id) === sid)
                return streams[i]
        return null
    }

    function sinkDescription(sinkId) {
        const sid = String(sinkId || "")
        for (let i = 0; i < sinks.length; i++) {
            if (String(sinks[i].id) === sid)
                return sinks[i].description || sinks[i].name
        }
        return sid.length ? ("Output " + sid) : "—"
    }

    function findMprisForStream(stream) {
        if (!stream)
            return null
        const bin = String(stream.binary || "").toLowerCase()
        const app = String(stream.label || "").toLowerCase()
        const list = MprisPlayers.list || []
        for (let i = 0; i < list.length; i++) {
            const p = list[i]
            const id = String(MprisPlayers.getIdentity(p) || "").toLowerCase()
            const dbus = String(p.dbusName || "").toLowerCase()
            if (bin.length && (id.indexOf(bin) >= 0 || dbus.indexOf(bin) >= 0))
                return p
            if (app.length && (id.indexOf(app) >= 0 || app.indexOf(id) >= 0))
                return p
        }
        if (bin === "spotify" || app === "spotify") {
            for (let j = 0; j < list.length; j++) {
                const d = String(list[j].dbusName || "").toLowerCase()
                if (d.indexOf("spotify") >= 0)
                    return list[j]
            }
        }
        return null
    }

    function refresh() {
        loading = true
        lastError = ""
        listProc.running = true
    }

    function applyFromConfigFile() {
        applyProc.running = true
    }

    function runJsonScript(scriptName, payload, onDone) {
        const json = JSON.stringify(payload)
        jsonProc._onDone = onDone || null
        jsonProc.command = [
            "python3",
            Quickshell.shellPath("scripts/" + scriptName),
            json
        ]
        jsonProc.running = false
        jsonProc.running = true
    }

    function moveStream(streamId, sinkId) {
        runJsonScript("audio-stream-ctl.py", { op: "move", streamId: String(streamId), sinkId: String(sinkId) },
            () => Qt.callLater(refresh))
    }

    function setStreamVolume(streamId, volume) {
        const v = Math.max(0, Math.min(100, parseInt(volume, 10)))
        patchStreamLocal(streamId, { volume: v })
        runJsonScript("audio-stream-ctl.py", { op: "volume", streamId: String(streamId), volume: v },
            () => { })
    }

    function toggleStreamMute(streamId) {
        const s = streamById(streamId)
        const wantMute = !(s && s.muted)
        patchStreamLocal(streamId, { muted: wantMute })
        runJsonScript("audio-stream-ctl.py",
            { op: "mute", streamId: String(streamId), mute: wantMute },
            () => { })
    }

    function mprisShortName(player) {
        if (!player || !player.dbusName)
            return ""
        return String(player.dbusName).replace(/^org\.mpris\.MediaPlayer2\./, "")
    }

    function mprisOp(player, op) {
        if (!player)
            return
        if (op === "playpause") {
            player.togglePlaying()
            bump()
            return
        }
        if (op === "previous" && player.canGoPrevious) {
            player.previous()
            Qt.callLater(refresh)
            return
        }
        if (op === "next" && player.canGoNext) {
            player.next()
            Qt.callLater(refresh)
            return
        }
        const short = mprisShortName(player)
        if (!short.length)
            return
        const flag = ({
            play: "play",
            pause: "pause",
            stop: "stop",
            next: "next",
            previous: "previous"
        })[op] || "play-pause"
        mprisProc._onDone = () => Qt.callLater(refresh)
        mprisProc.command = ["playerctl", "-p", short, flag]
        mprisProc.running = false
        mprisProc.running = true
    }

    Process {
        id: listProc
        command: ["python3", Quickshell.shellPath("scripts/audio-list.py")]
        stdout: StdioCollector { id: listOut }
        onExited: (code) => {
            root.loading = false
            if (code !== 0) {
                root.lastError = "pactl unavailable"
                root.bump()
                return
            }
            try {
                const o = JSON.parse(listOut.text || "{}")
                root.sinks = o.sinks || []
                root.streams = o.streams || []
                root.lastError = ""
            } catch (e) {
                root.lastError = "Parse error"
            }
            root.bump()
        }
    }

    Process {
        id: applyProc
        command: ["python3", Quickshell.shellPath("scripts/audio-apply-rules.py"), root.configPath]
        stdout: StdioCollector { id: applyOut }
        onExited: (code) => {
            if (code !== 0) {
                root.lastError = "Apply failed"
                root.bump()
                return
            }
            try {
                const o = JSON.parse(applyOut.text || "{}")
                root.lastError = o.ok ? "" : "Apply failed"
            } catch (e) {
                root.lastError = "Apply failed"
            }
            Qt.callLater(root.refresh)
        }
    }

    Process {
        id: mprisProc
        property var _onDone: null
        onExited: () => {
            const cb = mprisProc._onDone
            mprisProc._onDone = null
            if (cb)
                cb()
        }
    }

    Process {
        id: jsonProc
        property var _onDone: null
        stdout: StdioCollector { id: jsonOut }
        stderr: StdioCollector { id: jsonErr }
        onExited: (code) => {
            if (code !== 0) {
                const err = String(jsonErr.text || "").trim()
                root.lastError = err.length ? err.slice(0, 80) : "audio control failed"
                root.bump()
            } else {
                try {
                    const o = JSON.parse(jsonOut.text || "{}")
                    if (o.ok === false)
                        root.lastError = "audio control failed"
                } catch (e) { }
            }
            const cb = jsonProc._onDone
            jsonProc._onDone = null
            if (cb)
                cb()
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: ShellConfig.audioRoutingEnabled
        onTriggered: {
            if (!root.loading)
                root.applyFromConfigFile()
        }
    }

    Component.onCompleted: Qt.callLater(refresh)
}