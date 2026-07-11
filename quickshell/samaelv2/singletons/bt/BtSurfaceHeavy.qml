
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import ".."

/**
 * Bluetooth list + pair/connect for BluetoothSurface (ported from pill/LinkBt.qml).
 */
Item {
    id: root

    readonly property var adapter: (typeof Bluetooth !== "undefined" && Bluetooth)
        ? Bluetooth.defaultAdapter : null
    readonly property bool btOn: adapter ? adapter.enabled === true : false
    readonly property bool discovering: adapter ? adapter.discovering === true : false
    readonly property var devices: (typeof Bluetooth !== "undefined" && Bluetooth && Bluetooth.devices)
        ? Bluetooth.devices.values : []
    readonly property var devicesSorted: {
        const list = devices.slice()
        function rank(d) {
            if (!d) return 3
            if (d.connected) return 0
            if (d.paired) return 1
            return (d.name && d.name.length) ? 2 : 3
        }
        list.sort((a, b) => {
            const r = rank(a) - rank(b)
            if (r !== 0) return r
            return String(a?.name || "").localeCompare(String(b?.name || ""))
        })
        return list
    }

    readonly property var activeDevice: devices.find(d => d && d.connected) || null

    readonly property string statusText: {
        if (!adapter)
            return "No adapter"
        if (!btOn)
            return "Off"
        if (activeDevice)
            return deviceLabel(activeDevice)
        if (discovering)
            return "Scanning…"
        return devices.length ? "Ready" : "No devices"
    }

    property string expandedAddress: ""
    property string pairingAddress: ""
    property string failedAddress: ""
    property bool linkBusy: false
    property string toastMessage: ""
    property int listRevision: 0
    property bool surfaceOpen: false
    /** User was playing before we moved audio sinks (keep music going across BT connect/disconnect). */
    property bool playbackIntentBeforeRoute: false
    property var _lastRoutedBtDevice: null

    function bumpList() {
        listRevision++
    }

    function showToast(msg) {
        toastMessage = msg
        toastClear.restart()
    }

    function clearToast() {
        toastMessage = ""
    }

    function deviceLabel(d) {
        if (!d)
            return "Unknown"
        return d.deviceName || d.name || d.address || "Unknown"
    }

    function metaFor(d) {
        if (!d)
            return ""
        const parts = []
        if (d.connected)
            parts.push("connected")
        else if (d.paired)
            parts.push("paired")
        if (d.state !== undefined && typeof BluetoothDeviceState !== "undefined") {
            const st = BluetoothDeviceState.toString(d.state)
            if (st && parts.indexOf(st.toLowerCase()) === -1)
                parts.push(st.toLowerCase())
        }
        return parts.join(" · ")
    }

    function batteryLevel(d) {
        if (!d || d.battery === undefined || d.battery === null)
            return -1
        let b = d.battery
        if (b <= 0)
            return -1
        if (b <= 1)
            b = b * 100
        return Math.round(b)
    }

    function deviceBusy(d) {
        if (!d || typeof BluetoothDeviceState === "undefined")
            return false
        return d.state === BluetoothDeviceState.Connecting
            || d.state === BluetoothDeviceState.Disconnecting
    }

    function isPairing(d) {
        if (!d || !d.address)
            return false
        return pairingAddress === d.address
    }

    function isFailed(d) {
        if (!d || !d.address)
            return false
        return failedAddress === d.address
    }

    function activateDevice(d) {
        if (!d || !btOn)
            return
        const addr = d.address || ""
        if (d.connected || d.paired) {
            expandedAddress = (addr.length && expandedAddress === addr) ? "" : addr
            bumpList()
            return
        }
        pairDevice(d)
    }

    function connectDevice(d) {
        expandedAddress = ""
        if (!d)
            return
        linkBusy = true
        showToast("Connecting…")
        if (typeof d.connect === "function")
            d.connect()
        scheduleAudioRoute(d)
        linkClear.restart()
    }

    function disconnectDevice(d) {
        expandedAddress = ""
        if (!d)
            return
        linkBusy = true
        showToast("Disconnecting…")
        // route audio back to built-in BEFORE device disappears to keep music playing
        capturePlaybackIntent()
        scheduleBuiltInRoute()
        if (typeof d.disconnect === "function")
            d.disconnect()
        linkClear.restart()
    }

    function disconnectActive() {
        if (!btOn || linkBusy || pairProc.running)
            return
        const d = activeDevice
        if (d)
            disconnectDevice(d)
        else
            showToast("Not connected")
    }

    function forgetDevice(d) {
        if (!d || linkBusy)
            return
        expandedAddress = ""
        linkBusy = true
        showToast("Removing device…")
        if (typeof d.forget === "function")
            d.forget()
        linkClear.restart()
    }

    function pairDevice(d) {
        if (!d || !d.address || pairProc.running)
            return
        pairingAddress = d.address
        failedAddress = ""
        linkBusy = true
        showToast("Pairing " + deviceLabel(d) + "…")
        pairProc.command = ["sh", "-c",
            'timeout 30 bluetoothctl pair "$1" && bluetoothctl trust "$1" && timeout 30 bluetoothctl connect "$1"',
            "sh", d.address]
        pairProc.running = true
    }

    function toggleScan() {
        if (!adapter || !btOn)
            return
        adapter.discovering = !adapter.discovering
        if (adapter.discovering)
            scanTimer.restart()
        else
            scanTimer.stop()
    }

    /** Default sink + move open playback streams (Zen/MPRIS keeps playing on laptop speakers otherwise). */
    function routeAudioToDevice(d) {
        if (!d)
            return false
        capturePlaybackIntent()
        const label = deviceLabel(d)
        if (!label.length)
            return false
        const sink = pickBluetoothSink(label.trim().toLowerCase())
        if (sink) {
            Pipewire.preferredDefaultAudioSink = sink
            moveStreamsToSinkId(String(sink.id))
            showToast("Audio → " + label)
            return true
        }
        audioRouteProc.deviceLabel = label
        audioRouteProc.running = true
        return false
    }

    function capturePlaybackIntent() {
        const ap = MprisPlayers.activePlayer
        if (ap && ap.isPlaying) {
            playbackIntentBeforeRoute = true
            return
        }
        const list = MprisPlayers.list || []
        for (let i = 0; i < list.length; i++) {
            if (list[i] && list[i].isPlaying) {
                playbackIntentBeforeRoute = true
                return
            }
        }
    }

    function scheduleResumePlayback() {
        if (!playbackIntentBeforeRoute)
            return
        resumePlaybackTimer.restart()
    }

    function resumePlaybackIfNeeded() {
        if (!playbackIntentBeforeRoute)
            return
        playbackIntentBeforeRoute = false
        const p = MprisPlayers.activePlayer
        if (p && typeof p.play === "function") {
            p.play()
            return
        }
        Quickshell.execDetached(["playerctl", "-a", "play"])
    }

    function moveStreamsToSinkId(sinkId) {
        if (!sinkId || sinkId.length === 0)
            return
        Quickshell.execDetached(["bash", "-c",
            'sid="$1"; pactl list short sink-inputs 2>/dev/null | cut -f1 | while read -r in; do ' +
            '[ -n "$in" ] && pactl move-sink-input "$in" "$sid" 2>/dev/null && pactl suspend-sink-input "$in" 0 2>/dev/null; done; ' +
            'pactl suspend-sink "$sid" 0 2>/dev/null',
            "bash", sinkId])
        scheduleResumePlayback()
    }

    function pickBluetoothSink(labelLower) {
        if (typeof Pipewire === "undefined" || !Pipewire.nodes)
            return null
        const nodes = Pipewire.nodes.values || []
        let best = null
        let bestScore = 0
        for (let i = 0; i < nodes.length; i++) {
            const n = nodes[i]
            if (!n || !n.isSink || n.isStream || !n.audio)
                continue
            const desc = String(n.description || n.nickname || n.name || "").toLowerCase()
            if (!desc.length)
                continue
            const isBt = desc.indexOf("bluez") >= 0 || desc.indexOf("bluetooth") >= 0
                || String(n.name || "").toLowerCase().indexOf("bluez") >= 0
            if (!isBt && desc.indexOf(labelLower) < 0)
                continue
            let score = 0
            if (desc === labelLower)
                score = 100
            else if (desc.indexOf(labelLower) >= 0 || labelLower.indexOf(desc) >= 0)
                score = 80
            else if (isBt)
                score = 40
            if (score > bestScore) {
                bestScore = score
                best = n
            }
        }
        return best
    }

    function pickBuiltInSink() {
        if (typeof Pipewire === "undefined" || !Pipewire.nodes)
            return null
        const nodes = Pipewire.nodes.values || []
        let fallback = null
        for (let i = 0; i < nodes.length; i++) {
            const n = nodes[i]
            if (!n || !n.isSink || n.isStream || !n.audio)
                continue
            const name = String(n.name || "").toLowerCase()
            const desc = String(n.description || n.nickname || "").toLowerCase()
            if (name.indexOf("bluez") >= 0 || desc.indexOf("bluez") >= 0 || desc.indexOf("bluetooth") >= 0)
                continue
            if (!fallback)
                fallback = n
            if (desc.indexOf("analog") >= 0 || desc.indexOf("built-in") >= 0 || name.indexOf("analog") >= 0)
                return n
        }
        return fallback
    }

    function routeAudioToBuiltIn() {
        capturePlaybackIntent()
        const sink = pickBuiltInSink()
        if (sink) {
            Pipewire.preferredDefaultAudioSink = sink
            moveStreamsToSinkId(String(sink.id))
            showToast("Audio → speakers")
            return true
        }
        builtInRouteProc.running = true
        return false
    }

    function scheduleBuiltInRoute() {
        builtInRouteTry = 0
        builtInRouteTimer.restart()
    }

    property int builtInRouteTry: 0

    function scheduleAudioRoute(d) {
        if (!d)
            return
        capturePlaybackIntent()
        _lastRoutedBtDevice = d
        audioRouteDev = d
        audioRouteTry = 0
        audioRouteTimer.stop()
        audioRouteTimer.start()
    }

    property var audioRouteDev: null
    property int audioRouteTry: 0

    function toggleRadio() {
        if (!adapter)
            return
        adapter.enabled = !adapter.enabled
        if (!adapter.enabled && adapter.discovering)
            adapter.discovering = false
        if (!adapter.enabled) {
            // route audio back to built-in BEFORE BT disappears to keep music playing
            capturePlaybackIntent()
            scheduleBuiltInRoute()
        }
    }

    function onSurfaceOpenChanged(open) {
        surfaceOpen = open
        if (open) {
            bumpList()
            if (adapter && btOn && !adapter.discovering) {
                adapter.discovering = true
                scanTimer.restart()
            }
            if (activeDevice)
                Qt.callLater(() => scheduleAudioRoute(activeDevice))
        } else {
            scanTimer.stop()
            expandedAddress = ""
            pairingAddress = ""
            failedAddress = ""
            clearToast()
            linkBusy = false
            if (adapter && adapter.discovering)
                adapter.discovering = false
        }
    }

    onDevicesChanged: bumpList()

    onActiveDeviceChanged: {
        if (activeDevice)
            scheduleAudioRoute(activeDevice)
        else if (_lastRoutedBtDevice || playbackIntentBeforeRoute)
            scheduleBuiltInRoute()
    }

    Timer {
        id: toastClear
        interval: 2400
        onTriggered: root.clearToast()
    }

    Timer {
        id: linkClear
        interval: 1200
        onTriggered: {
            root.linkBusy = false
            root.bumpList()
        }
    }

    Timer {
        id: scanTimer
        interval: 25000
        onTriggered: {
            if (root.adapter)
                root.adapter.discovering = false
        }
    }

        Timer {
            id: failTimer
            interval: 4000
            onTriggered: root.failedAddress = ""
        }

        Timer {
            id: resumePlaybackTimer
            interval: 450
            onTriggered: root.resumePlaybackIfNeeded()
        }

        Timer {
            id: builtInRouteTimer
            interval: 400
            repeat: true
            onTriggered: {
                root.builtInRouteTry++
                if (root.routeAudioToBuiltIn() || root.builtInRouteTry >= 6)
                    stop()
            }
        }

        Timer {
            id: audioRouteTimer
            interval: 500
            repeat: true
            onTriggered: {
                const d = root.audioRouteDev
                if (!d) {
                    stop()
                    return
                }
                root.audioRouteTry++
                if (root.routeAudioToDevice(d) || root.audioRouteTry >= 8) {
                    root.audioRouteDev = null
                    stop()
                }
            }
        }

        Process {
            id: audioRouteProc
            property string deviceLabel: ""
            command: ["bash", "-c",
                "label=\"$1\"; "
                    + "sec=$(wpctl status 2>/dev/null | sed -n '/Sinks:/,/Sources:/p'); "
                    + "line=$(echo \"$sec\" | grep -Fi \"$label\" | head -1); "
                    + "test -n \"$line\" || line=$(echo \"$sec\" | grep -Fi samael | head -1); "
                    + "test -n \"$line\" || line=$(echo \"$sec\" | grep -i bluez | head -1); "
                    + "id=$(echo \"$line\" | sed -n 's/.*[^0-9]\\([0-9][0-9]*\\)\\. .*/\\1/p'); "
                    + "test -n \"$id\" || exit 1; "
                    + "wpctl set-default \"$id\"; wpctl set-mute \"$id\" 0; "
                    + "pactl list short sink-inputs 2>/dev/null | cut -f1 | while read -r in; do "
                    + "[ -n \"$in\" ] && pactl move-sink-input \"$in\" \"$id\" 2>/dev/null && pactl suspend-sink-input \"$in\" 0 2>/dev/null; done; "
                    + "pactl suspend-sink \"$id\" 0 2>/dev/null",
            "bash", deviceLabel]
            onExited: exitCode => {
                if (exitCode === 0 && audioRouteProc.deviceLabel.length) {
                    root.showToast("Audio → " + audioRouteProc.deviceLabel)
                    root.scheduleResumePlayback()
                } else if (audioRouteProc.deviceLabel.length)
                    root.showToast("Could not switch audio output")
            }
        }

        Process {
            id: builtInRouteProc
            command: ["bash", "-c",
                "sec=$(wpctl status 2>/dev/null | sed -n '/Sinks:/,/Sources:/p'); "
                    + "line=$(echo \"$sec\" | grep -Fi analog | head -1); "
                    + "test -n \"$line\" || line=$(echo \"$sec\" | grep -Fi 'built-in' | head -1); "
                    + "test -n \"$line\" || line=$(echo \"$sec\" | grep -v -i bluez | grep -E '^[[:space:]]*[0-9]+\\.' | head -1); "
                    + "id=$(echo \"$line\" | sed -n 's/.*[^0-9]\\([0-9][0-9]*\\)\\. .*/\\1/p'); "
                    + "test -n \"$id\" || exit 1; "
                    + "wpctl set-default \"$id\"; "
                    + "pactl list short sink-inputs 2>/dev/null | cut -f1 | while read -r in; do "
                    + "[ -n \"$in\" ] && pactl move-sink-input \"$in\" \"$id\" 2>/dev/null && pactl suspend-sink-input \"$in\" 0 2>/dev/null; done; "
                    + "pactl suspend-sink \"$id\" 0 2>/dev/null"]
            onExited: exitCode => {
                if (exitCode === 0) {
                    root.showToast("Audio → speakers")
                    root.scheduleResumePlayback()
                }
            }
        }

        Process {
            id: pairProc
            onExited: exitCode => {
                const addr = root.pairingAddress
                root.pairingAddress = ""
                root.linkBusy = false
                if (exitCode === 0) {
                    root.showToast("Paired")
                    root.bumpList()
                    const dev = root.devices.find(x => x && x.address === addr)
                    if (dev)
                        root.scheduleAudioRoute(dev)
                } else {
                    root.failedAddress = addr
                    root.showToast("Pairing failed")
                    failTimer.restart()
                }
            }
    }
}