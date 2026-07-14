pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

/**
 * Bar Bluetooth state (light). Pairing / audio routing loads with BluetoothSurface or while connected.
 * Remembers last user power choice so restart does not leave the radio on against preference.
 */
Singleton {
    id: root

    readonly property var adapter: (typeof Bluetooth !== "undefined" && Bluetooth)
        ? Bluetooth.defaultAdapter : null
    readonly property bool btOn: adapter ? adapter.enabled === true : false
    readonly property bool discovering: adapter ? adapter.discovering === true : false
    readonly property var devices: (typeof Bluetooth !== "undefined" && Bluetooth && Bluetooth.devices)
        ? Bluetooth.devices.values : []
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

    property bool surfaceOpen: false
    /** null = no preference stored yet; true/false = last user toggle */
    property var preferredPowered: null
    property bool _appliedPreference: false

    readonly property string powerStatePath: Quickshell.shellPath("state/bt-power.json")

    function deviceLabel(d) {
        if (!d)
            return "Unknown"
        return d.deviceName || d.name || d.address || "Unknown"
    }

    readonly property var _h: heavyLoader.item

    readonly property var devicesSorted: {
        if (_h)
            return _h.devicesSorted
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
    readonly property int listRevision: _h ? _h.listRevision : 0
    readonly property string expandedAddress: _h ? _h.expandedAddress : ""
    readonly property string pairingAddress: _h ? _h.pairingAddress : ""
    readonly property bool linkBusy: _h ? _h.linkBusy : false
    readonly property string toastMessage: _h ? _h.toastMessage : ""

    function rememberPower(on) {
        preferredPowered = on === true
        powerWriteProc.writeJson(preferredPowered)
    }

    function applyPreferredPower() {
        if (_appliedPreference)
            return
        if (preferredPowered === null || preferredPowered === undefined)
            return
        if (!adapter)
            return
        _appliedPreference = true
        const want = preferredPowered === true
        if (adapter.enabled === want)
            return
        // Only force OFF against accidental power-on; never force ON without the user.
        if (!want && adapter.enabled === true) {
            adapter.enabled = false
            if (adapter.discovering)
                adapter.discovering = false
        }
    }

    function onSurfaceOpenChanged(open) {
        surfaceOpen = open
        if (_h)
            _h.onSurfaceOpenChanged(open)
        else if (open)
            Qt.callLater(() => { if (heavyLoader.item) heavyLoader.item.onSurfaceOpenChanged(true) })
    }

    function metaFor(d) { return _h ? _h.metaFor(d) : "" }
    function batteryLevel(d) { return _h ? _h.batteryLevel(d) : -1 }
    function deviceBusy(d) { return _h ? _h.deviceBusy(d) : false }
    function isPairing(d) { return _h ? _h.isPairing(d) : false }
    function isFailed(d) { return _h ? _h.isFailed(d) : false }
    function activateDevice(d) { if (_h) _h.activateDevice(d) }
    function connectDevice(d) { if (_h) _h.connectDevice(d) }
    function disconnectDevice(d) { if (_h) _h.disconnectDevice(d) }
    function disconnectActive() { if (_h) _h.disconnectActive() }
    function forgetDevice(d) { if (_h) _h.forgetDevice(d) }
    function pairDevice(d) { if (_h) _h.pairDevice(d) }
    function toggleScan() { if (_h) _h.toggleScan() }
    function toggleRadio() {
        if (_h) {
            _h.toggleRadio()
            return
        }
        if (!adapter)
            return
        adapter.enabled = !adapter.enabled
        rememberPower(adapter.enabled === true)
        if (!adapter.enabled && adapter.discovering)
            adapter.discovering = false
    }
    function routeAudioToDevice(d) { return _h ? _h.routeAudioToDevice(d) : false }
    function showToast(msg) { if (_h) _h.showToast(msg) }
    function setExpandedAddress(val) { if (_h) _h.expandedAddress = val }

    // Load preference ASAP; re-apply a few times in case adapter appears late.
    FileView {
        id: powerFile
        path: root.powerStatePath
        watchChanges: false
        onLoaded: {
            try {
                const j = JSON.parse(text)
                if (typeof j.powered === "boolean") {
                    root.preferredPowered = j.powered
                    Qt.callLater(root.applyPreferredPower)
                }
            } catch (e) { /* empty / first run */ }
        }
        Component.onCompleted: reload()
    }

    Process {
        id: powerWriteProc
        function writeJson(powered) {
            const dir = Quickshell.shellPath("state")
            const path = root.powerStatePath
            const flag = powered === true ? "true" : "false"
            // Avoid nested QML quote hell — one shell string only.
            command = ["sh", "-c",
                "mkdir -p '" + dir + "' && echo '{\"powered\": " + flag + "}' > '" + path + "'"]
            running = true
        }
    }

    Timer {
        id: powerApplyRetry
        interval: 400
        repeat: true
        property int n: 0
        running: false
        onTriggered: {
            n++
            root.applyPreferredPower()
            if (root._appliedPreference || n >= 8)
                stop()
        }
    }

    Component.onCompleted: {
        powerApplyRetry.n = 0
        powerApplyRetry.start()
    }

    onAdapterChanged: Qt.callLater(root.applyPreferredPower)

    Loader {
        id: heavyLoader
        active: root.surfaceOpen || root.activeDevice !== null
        asynchronous: false
        source: "bt/BtSurfaceHeavy.qml"
        onLoaded: {
            if (!item)
                return
            item.onSurfaceOpenChanged(root.surfaceOpen)
            if (root.activeDevice && !root.surfaceOpen)
                Qt.callLater(() => item.scheduleAudioRoute(root.activeDevice))
        }
        onActiveChanged: {
            if (active && item)
                item.onSurfaceOpenChanged(root.surfaceOpen)
        }
    }
}
