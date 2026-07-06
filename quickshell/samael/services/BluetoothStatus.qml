pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property bool available: Bluetooth.adapters.values.length > 0
    readonly property bool enabled: Bluetooth.defaultAdapter?.enabled ?? false
    readonly property BluetoothDevice firstActiveDevice: Bluetooth.defaultAdapter?.devices.values.find(device => device.connected) ?? null
    readonly property int activeDeviceCount: Bluetooth.defaultAdapter?.devices.values.filter(device => device.connected).length ?? 0
        readonly property bool connected: Bluetooth.devices.values.some(d => d.connected)
        property bool rfkillBlocked: false
        property bool pendingEnableAfterUnblock: false

        function refreshRfkillState(): void {
            rfkillCheckProc.running = false
            rfkillCheckProc.running = true
        }

        function sortFunction(a, b) {
        // Ones with meaningful names before MAC addresses
        const macRegex = /^([0-9A-Fa-f]{2}-){5}[0-9A-Fa-f]{2}$/;
        const aIsMac = macRegex.test(a.name);
        const bIsMac = macRegex.test(b.name);
        if (aIsMac !== bIsMac)
            return aIsMac ? 1 : -1;

        // Alphabetical by name
        return a.name.localeCompare(b.name);
    }
    property list<var> connectedDevices: Bluetooth.devices.values.filter(d => d.connected).sort(sortFunction)
    property list<var> pairedButNotConnectedDevices: Bluetooth.devices.values.filter(d => d.paired && !d.connected).sort(sortFunction)
    property list<var> unpairedDevices: Bluetooth.devices.values.filter(d => !d.paired && !d.connected).sort(sortFunction)
    property list<var> friendlyDeviceList: [
        ...connectedDevices,
        ...pairedButNotConnectedDevices,
        ...unpairedDevices
    ]

    function toggleAdapter(): void {
        const ad = Bluetooth.defaultAdapter

        if (rfkillBlocked) {
pendingEnableAfterUnblock = true
rfkillUnblockProc.running = true
return
        }

        if (!ad) {
btPowerProc.command = ["bluetoothctl", "power", "on"]
btPowerProc.running = true
return
        }

        ad.enabled = !ad.enabled
        if (ad.enabled)
ad.discovering = true
    }

    function applyAdapterOnAfterUnblock(): void {
        pendingEnableAfterUnblock = false
        const ad = Bluetooth.defaultAdapter
        if (ad) {
ad.enabled = true
ad.discovering = true
        } else {
btPowerProc.command = ["bluetoothctl", "power", "on"]
btPowerProc.running = true
        }
        refreshRfkillState()
    }

    Timer {
        interval: 4000
        running: true
        repeat: true
        onTriggered: root.refreshRfkillState()
    }

    Component.onCompleted: refreshRfkillState()

    Process {
        id: rfkillCheckProc
        command: ["sh", "-c", "rfkill list bluetooth 2>/dev/null | grep -q 'Soft blocked: yes' && echo blocked || echo ok"]
        stdout: SplitParser {
onRead: line => {
root.rfkillBlocked = line.trim() === "blocked"
}
        }
    }

    Process {
        id: rfkillUnblockProc
        command: ["rfkill", "unblock", "bluetooth"]
        onExited: () => {
if (root.pendingEnableAfterUnblock)
Qt.callLater(() => root.applyAdapterOnAfterUnblock())
else
root.refreshRfkillState()
        }
    }

    Process {
        id: btPowerProc
    }
}
