import QtQuick
import qs.modules.samael
import qs.modules.common
import qs.services

Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    function networkNerdIcon(): string {
        if (Network.ethernet)
            return "󰌘"
        if (!Network.wifiEnabled)
            return "󰤭"
        if (Network.wifiStatus === "connected") {
            const s = Network.active?.strength ?? 0
            if (s > 83) return "󰤨"
            if (s > 67) return "󰤥"
            if (s > 50) return "󰤢"
            if (s > 33) return "󰤟"
            if (s > 17) return "󰤯"
            return "󰤮"
        }
        if (Network.wifiStatus === "connecting")
            return "󰤫"
        return "󰌙"
    }

    function bluetoothNerdIcon(): string {
        if (!BluetoothStatus.available)
            return ""
        if (BluetoothStatus.connected)
            return "󰂱"
        if (BluetoothStatus.enabled)
            return "󰂯"
        return "󰂲"
    }

    Row {
        id: row
        spacing: 2

        SamaelBarButton {
            text: root.networkNerdIcon()
            onClicked: {
                GlobalStates.samaelBluetoothMenuOpen = false
                GlobalStates.samaelWifiMenuOpen = !GlobalStates.samaelWifiMenuOpen
            }
        }

        SamaelBarButton {
            visible: BluetoothStatus.available
            text: root.bluetoothNerdIcon()
            onClicked: {
                GlobalStates.samaelWifiMenuOpen = false
                GlobalStates.samaelBluetoothMenuOpen = !GlobalStates.samaelBluetoothMenuOpen
            }
        }
    }
}