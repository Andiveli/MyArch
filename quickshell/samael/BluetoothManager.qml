import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Bluetooth Manager
 */
Item {
    id: btRoot

    property bool enabled: false
    property var devices: []

    // List devices process
    Process {
        id: devicesListProcess
        running: false
        command: ["bash", "-c", "bluetoothctl devices 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split('\n').filter(l => l)
                const newDevices = []
                for (const line of lines) {
                    const parts = line.split(' ')
                    if (parts.length >= 3) {
                        const mac = parts[1]
                        const name = parts.slice(2).join(' ')
                        newDevices.push({ mac: mac, name: name })
                    }
                }
                devices = newDevices
            }
        }
    }

    // Check status process
    Process {
        id: statusProcess
        running: false
        command: ["bash", "-c", "bluetoothctl show 2>/dev/null | grep 'Powered:' | awk '{print $2}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                enabled = this.text.trim() === 'yes'
                if (enabled && devices.length === 0) {
                    devicesListProcess.running = true
                }
            }
        }
    }

    function getDevices() {
        devicesListProcess.running = true
    }

    function connect(mac) {
        if (!mac) return
        Quickshell.execDetached(["bash", `-c", "bluetoothctl connect ${mac} 2>/dev/null`])
        Qt.callLater(getDevices)
    }

    function disconnect(mac) {
        if (!mac) return
        Quickshell.execDetached(["bash", `-c", "bluetoothctl disconnect ${mac} 2>/dev/null`])
        Qt.callLater(getDevices)
    }

    function toggle() {
        if (enabled) {
            Quickshell.execDetached(["bash", "-c", "bluetoothctl power off 2>/dev/null"])
            enabled = false
        } else {
            Quickshell.execDetached(["bash", "-c", "bluetoothctl power on 2>/dev/null"])
            enabled = true
            Qt.callLater(getDevices)
        }
    }

    function refreshStatus() {
        statusProcess.running = true
    }

    Component.onCompleted: {
        refreshStatus()
    }
}
