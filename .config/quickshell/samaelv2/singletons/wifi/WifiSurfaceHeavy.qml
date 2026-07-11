
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

/**
 * WiFi list + nmcli helpers for WifiSurface (ported from pill/LinkWifi.qml).
 */
Item {
    id: root

    readonly property var devices: (Networking && Networking.devices)
        ? Networking.devices.values : []
    readonly property var wifiDev: devices.find(d => d && d.type === DeviceType.Wifi) || null
    readonly property bool wifiOn: Networking ? Networking.wifiEnabled : false
    readonly property var nets: (wifiDev && wifiDev.networks && wifiDev.networks.values) ? wifiDev.networks.values : []
    readonly property var netsSorted: {
        const n = nets.slice()
        n.sort((a, b) => ((b?.signalStrength) || 0) - ((a?.signalStrength) || 0))
        return n
    }
    property string nmcliActiveSsid: ""

    function netConnected(net) {
        if (!net)
            return false
        if (net.connected === true)
            return true
        const name = String(net.name || "").trim()
        return name.length > 0 && name === nmcliActiveSsid
    }

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

    property var securityMap: ({})
    property var knownProfiles: ({})
    /** SSID → NetworkManager connection name (for delete) */
    property var profileIdBySsid: ({})
    property string expandedSsid: ""
    property bool connecting: false
    property bool linkBusy: false
    property string toastMessage: ""
    property bool connectFailed: false
    property bool scanning: false
    property string pwDraft: ""
    property string pendingPw: ""
    property string attemptSsid: ""
    property bool attemptWasKnown: false
    property int listRevision: 0
    property bool surfaceOpen: false
    property string hiddenSsidDraft: ""

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

    function isSecured(ssid) {
        const sec = securityMap[ssid]
        return sec !== undefined && sec !== "" && sec !== "--"
    }

    function splitTerse(line) {
        for (let k = line.length - 1; k >= 0; k--) {
            if (line[k] === ":" && (k === 0 || line[k - 1] !== "\\"))
                return {
                    head: line.slice(0, k).replace(/\\:/g, ":"),
                    tail: line.slice(k + 1)
                }
        }
        return null
    }

    function refresh() {
        secProc.running = true
        profProc.running = true
        bumpList()
    }

    function activateNetwork(net) {
        if (!net)
            return
        const ssid = net.name || ""
        if (expandedSsid === ssid && ssid.length) {
            expandedSsid = ""
            return
        }
        if (netConnected(net) || knownProfiles[ssid] === true) {
            connectFailed = false
            pwDraft = ""
            expandedSsid = ssid
            return
        }
        if (!isSecured(ssid)) {
            expandedSsid = ""
            if (typeof net.connect === "function")
                net.connect()
            refresh()
            return
        }
        connectFailed = false
        pwDraft = ""
        expandedSsid = ssid
    }

    function connectKnown(net) {
        if (!net)
            return
        expandedSsid = ""
        if (typeof net.connect === "function")
            net.connect()
        refresh()
    }

    function disconnectNetwork(net) {
        if (!net)
            return
        expandedSsid = ""
        linkBusy = true
        showToast("Disconnecting…")
        if (typeof net.disconnect === "function")
            net.disconnect()
        refresh()
        Qt.callLater(() => {
            activeProc.running = true
            linkBusy = false
            showToast("Disconnected")
        })
    }

    function disconnectActive() {
        if (!wifiOn || linkBusy || connecting)
            return
        expandedSsid = ""
        // Does not clear pwDraft or delete saved profiles — only drops the live session.
        const net = activeNet
        const label = net?.name || nmcliActiveSsid || "network"
        if (net) {
            disconnectNetwork(net)
            return
        }
        if (!nmcliActiveSsid.length)
            return
        linkBusy = true
        showToast("Disconnecting from " + label + "…")
        discProc.running = true
    }

    function profileIdForSsid(ssid) {
        const key = String(ssid || "").trim()
        if (!key.length)
            return ""
        if (profileIdBySsid[key])
            return profileIdBySsid[key]
        if (knownProfiles[key] === true)
            return key
        return ""
    }

    function forgetNetwork(ssid) {
        if (forgetProc.running || linkBusy)
            return
        const key = String(ssid || "").trim()
        const connId = profileIdForSsid(key)
        if (!connId.length) {
            showToast("No saved profile for this network")
            return
        }
        expandedSsid = ""
        linkBusy = true
        showToast("Removing saved profile " + key + "…")
        forgetProc.lastSsid = key
        forgetProc.command = ["nmcli", "connection", "delete", "id", connId]
        forgetProc.running = true
    }

    function pruneKnownAfterForget(ssid) {
        const key = String(ssid || "").trim()
        const kn = Object.assign({}, knownProfiles)
        const map = Object.assign({}, profileIdBySsid)
        delete kn[key]
        delete map[key]
        knownProfiles = kn
        profileIdBySsid = map
        bumpList()
    }

    function connectWithPassword(ssid, pw) {
        const secret = String(pw || "").trim()
        if (connProc.running || !ssid.length || !secret.length)
            return false
        connecting = true
        connectFailed = false
        attemptSsid = ssid
        attemptWasKnown = knownProfiles[ssid] === true
        connProc.command = ["nmcli", "-w", "45", "dev", "wifi", "connect", ssid, "password", secret]
        connProc.running = true
        return true
    }

    function startScan() {
        if (!wifiOn)
            return
        scanning = true
        rescanProc.running = true
        scanTimer.restart()
    }

    function stopScan() {
        scanning = false
        scanTimer.stop()
    }

    function onSurfaceOpenChanged(open) {
        surfaceOpen = open
        syncScanner()
        if (open) {
            refresh()
            activePoll.restart()
            activeProc.running = true
        } else {
            activePoll.stop()
            stopScan()
            expandedSsid = ""
            connectFailed = false
            pwDraft = ""
            hiddenSsidDraft = ""
            clearToast()
            linkBusy = false
        }
    }

    function syncScanner() {
        if (!wifiDev)
            return
        wifiDev.scannerEnabled = surfaceOpen && wifiOn
    }

    onWifiOnChanged: syncScanner()

    Timer {
        id: toastClear
        interval: 2400
        onTriggered: root.clearToast()
    }

    Timer {
        id: scanTimer
        interval: 10000
        onTriggered: root.stopScan()
    }

    Timer {
        id: secRefresh
        interval: 1200
        onTriggered: if (secProc && !secProc.running) secProc.running = true
    }

        onNetsChanged: secRefresh.restart()

        Timer {
            id: activePoll
            interval: 2500
            repeat: true
            running: root.surfaceOpen && root.wifiOn
            onTriggered: activeProc.running = true
        }

        Process {
            id: activeProc
            command: ["nmcli", "-t", "-f", "ACTIVE,SSID", "dev", "wifi"]
            stdout: StdioCollector {
                onStreamFinished: {
                    let found = ""
                    const lines = this.text.split("\n")
                    for (let i = 0; i < lines.length; i++) {
                        const parts = root.splitTerse(lines[i])
                        if (!parts || !parts.head.length)
                            continue
                        const active = parts.head.toLowerCase()
                        if (active === "yes" || active === "*") {
                            found = parts.tail.replace(/\\:/g, ":")
                            break
                        }
                    }
                    if (root.nmcliActiveSsid !== found) {
                        root.nmcliActiveSsid = found
                        root.bumpList()
                    }
                }
            }
        }

        Process { id: rescanProc; command: ["nmcli", "dev", "wifi", "rescan"] }
        Process {
            id: discProc
            command: ["nmcli", "dev", "disconnect"]
            onExited: exitCode => {
                root.linkBusy = false
                root.nmcliActiveSsid = ""
                root.refresh()
                activeProc.running = true
                if (exitCode === 0)
                root.showToast("Disconnected")
                else
                root.showToast("Could not disconnect")
            }
        }

    Process {
        id: secProc
        command: ["nmcli", "-t", "-f", "SSID,SECURITY", "dev", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const map = {}
                const lines = this.text.split("\n")
                for (let i = 0; i < lines.length; i++) {
                    if (!lines[i].length)
                        continue
                    const parts = root.splitTerse(lines[i])
                    if (parts && parts.head.length)
                        map[parts.head] = parts.tail
                }
                root.securityMap = map
                root.bumpList()
            }
        }
    }

    Process {
        id: profProc
        command: ["nmcli", "-t", "-f", "NAME,802-11-wireless.ssid", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const set = {}
                const map = {}
                const lines = this.text.split("\n")
                for (let i = 0; i < lines.length; i++) {
                    if (!lines[i].length)
                        continue
                    const parts = root.splitTerse(lines[i])
                    if (!parts || !parts.head.length)
                        continue
                    const connName = parts.head.replace(/\\:/g, ":")
                    const ssid = (parts.tail || "").replace(/\\:/g, ":").trim()
                    if (!ssid.length)
                        continue
                    set[ssid] = true
                    map[ssid] = connName
                }
                root.knownProfiles = set
                root.profileIdBySsid = map
                root.bumpList()
            }
        }
    }

    Process {
        id: connProc
        onExited: exitCode => {
            if (exitCode === 0) {
                root.expandedSsid = ""
                root.pwDraft = ""
                root.connectFailed = false
                root.connecting = false
                root.refresh()
                activeProc.running = true
            } else {
                root.connectFailed = true
                root.connecting = false
                if (!root.attemptWasKnown && root.attemptSsid.length) {
                    const cid = root.profileIdForSsid(root.attemptSsid) || root.attemptSsid
                    cleanupProc.command = ["nmcli", "connection", "delete", "id", cid]
                    cleanupProc.running = true
                }
            }
        }
    }

        Process { id: cleanupProc; onExited: root.refresh() }
        Process {
            id: forgetProc
            property string lastSsid: ""
            onExited: exitCode => {
                root.linkBusy = false
                if (exitCode === 0) {
                    root.pruneKnownAfterForget(forgetProc.lastSsid)
                    root.showToast("Saved profile removed")
                } else {
                    root.showToast("Could not remove profile")
                }
                root.refresh()
            }
        }
}