import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Wifi Manager - scan and connect using nmcli
 */
Item {
    id: wifiRoot

    property bool wifiEnabled: false
    property var networks: []
    property string currentNetwork: ""
    property bool scanning: false

    // Scan networks process
    Process {
        id: scanProcess
        running: false
        command: ["bash", "-c", "nmcli -t device wifi list 2>/dev/null | head -20"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split('\n').filter(l => l)
                const newNetworks = []
                for (const line of lines) {
                    const parts = line.split(':')
                    if (parts.length >= 7) {
                        const ssid = parts[0]
                        const signal = parseInt(parts[6]) || 0
                        const secured = parts[2] === '--' ? false : true
                        const connected = parts[3] === '*'
                        if (connected) currentNetwork = ssid
                        newNetworks.push({
                            ssid: ssid,
                            signal: signal,
                            secured: secured,
                            connected: connected
                        })
                    }
                }
                newNetworks.sort((a, b) => b.signal - a.signal)
                networks = newNetworks
                scanning = false
            }
        }
    }

    // Check status process
    Process {
        id: statusProcess
        running: false
        command: ["bash", "-c", "nmcli radio wifi 2>/dev/null | grep -q 'enabled' && echo 'enabled' || echo 'disabled'"]
        stdout: StdioCollector {
            onStreamFinished: {
                wifiEnabled = this.text.trim() === 'enabled'
                if (wifiEnabled && networks.length === 0) {
                    scanProcess.running = true
                    scanning = true
                }
            }
        }
    }

    function scanNetworks() {
        if (!wifiEnabled || scanning) return
        scanning = true
        scanProcess.running = true
    }

    function connect(ssid) {
        if (!ssid) return
        Quickshell.execDetached(["bash", "-c", `nmcli device wifi connect "${ssid}" 2>/dev/null`])
        Qt.callLater(scanNetworks)
    }

    function toggle() {
        if (wifiEnabled) {
            Quickshell.execDetached(["bash", "-c", "nmcli radio wifi off"])
            wifiEnabled = false
        } else {
            Quickshell.execDetached(["bash", "-c", "nmcli radio wifi on"])
            wifiEnabled = true
            Qt.callLater(scanNetworks)
        }
    }

    function refreshStatus() {
        statusProcess.running = true
    }

    Component.onCompleted: {
        refreshStatus()
    }
}
