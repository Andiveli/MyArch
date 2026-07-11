pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

/**
 * Bar Wi‑Fi state (always light). Full nmcli menu logic loads only while WifiSurface is open.
 */
Singleton {
    id: root

    readonly property var devices: (Networking && Networking.devices)
        ? Networking.devices.values : []
    readonly property var wifiDev: devices.find(d => d && d.type === DeviceType.Wifi) || null
    readonly property bool wifiOn: Networking ? Networking.wifiEnabled : false
    readonly property var nets: (wifiDev && wifiDev.networks && wifiDev.networks.values) ? wifiDev.networks.values : []

    property string nmcliActiveSsid: ""
    property bool surfaceOpen: false

    readonly property var activeNet: {
        const fromApi = nets.find(n => n && n.connected)
        if (fromApi)
            return fromApi
        if (!nmcliActiveSsid.length)
            return null
        return nets.find(n => String(n?.name || "").trim() === nmcliActiveSsid) || null
    }

    readonly property string statusText: {
        if (!wifiOn)
            return "Off"
        if (activeNet)
            return activeNet.name || "Connected"
        if (nmcliActiveSsid.length)
            return nmcliActiveSsid
        return "Not connected"
    }

    readonly property var _h: heavyLoader.item

        readonly property var netsSorted: {
            if (_h)
                return _h.netsSorted
            const n = nets.slice()
            n.sort((a, b) => ((b?.signalStrength) || 0) - ((a?.signalStrength) || 0))
            return n
        }
    readonly property int listRevision: _h ? _h.listRevision : 0
    readonly property var securityMap: _h ? _h.securityMap : ({})
    readonly property var knownProfiles: _h ? _h.knownProfiles : ({})
    readonly property string expandedSsid: _h ? _h.expandedSsid : ""
    readonly property bool connecting: _h ? _h.connecting : false
    readonly property bool linkBusy: _h ? _h.linkBusy : false
    readonly property string toastMessage: _h ? _h.toastMessage : ""
    readonly property bool connectFailed: _h ? _h.connectFailed : false
    readonly property bool scanning: _h ? _h.scanning : false
    readonly property string pwDraft: _h ? _h.pwDraft : ""
    readonly property string hiddenSsidDraft: _h ? _h.hiddenSsidDraft : ""

    function netConnected(net) {
        if (_h)
            return _h.netConnected(net)
        if (!net)
            return false
        if (net.connected === true)
            return true
        const name = String(net.name || "").trim()
        return name.length > 0 && name === nmcliActiveSsid
    }

    function isSecured(ssid) {
        if (_h)
            return _h.isSecured(ssid)
        return false
    }

    function onSurfaceOpenChanged(open) {
        surfaceOpen = open
        if (_h)
            _h.onSurfaceOpenChanged(open)
        else if (open)
            Qt.callLater(() => { if (heavyLoader.item) heavyLoader.item.onSurfaceOpenChanged(true) })
    }

    function activateNetwork(net) { if (_h) _h.activateNetwork(net) }
    function connectKnown(net) { if (_h) _h.connectKnown(net) }
    function connectWithPassword(ssid, pw) { return _h ? _h.connectWithPassword(ssid, pw) : false }
    function disconnectNetwork(net) { if (_h) _h.disconnectNetwork(net) }
    function disconnectActive() { if (_h) _h.disconnectActive() }
    function forgetNetwork(ssid) { if (_h) _h.forgetNetwork(ssid) }
    function startScan() { if (_h) _h.startScan() }
    function stopScan() { if (_h) _h.stopScan() }
    function showToast(msg) { if (_h) _h.showToast(msg) }

    // Setters for proxy-only properties (the heavy item owns the writable storage).
    function setPwDraft(val) { if (_h) _h.pwDraft = val }
    function setExpandedSsid(val) { if (_h) _h.expandedSsid = val }
    function setConnectFailed(val) { if (_h) _h.connectFailed = val }
    function setHiddenSsidDraft(val) { if (_h) _h.hiddenSsidDraft = val }

    Loader {
        id: heavyLoader
        active: root.surfaceOpen
        asynchronous: false
        source: "wifi/WifiSurfaceHeavy.qml"
        onLoaded: {
            if (item)
                item.onSurfaceOpenChanged(root.surfaceOpen)
        }
    }
}