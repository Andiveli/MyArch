pragma Singleton
pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Extended Network service with speed monitoring
 */
Singleton {
    id: root

    // Propiedades básicas de Network
    property bool wifiEnabled: false
    property bool ethernet: false
    property string networkName: ""
    property int networkStrength: 0
    property string materialSymbol: "wifi"

    // Velocidades
    property real bandwidthUpBytes: 0
    property real bandwidthDownBytes: 0
    property string bandwidthUp: "0 B"
    property string bandwidthDown: "0 B"

    // IPs
    property string ipaddr: ""

    function formatBytes(bytes) {
        if (bytes < 1024) return bytes + " B"
        else if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " K"
        else if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1) + " M"
        else return (bytes / (1024 * 1024 * 1024)).toFixed(1) + " G"
    }

    function updateMaterialSymbol() {
        if (root.ethernet) {
            root.materialSymbol = "lan"
        } else if (root.wifiEnabled) {
            if (root.networkStrength > 83) root.materialSymbol = "signal_wifi_4_bar"
            else if (root.networkStrength > 67) root.materialSymbol = "network_wifi"
            else if (root.networkStrength > 50) root.materialSymbol = "network_wifi_3_bar"
            else if (root.networkStrength > 33) root.materialSymbol = "network_wifi_2_bar"
            else if (root.networkStrength > 17) root.materialSymbol = "network_wifi_1_bar"
            else root.materialSymbol = "signal_wifi_0_bar"
        } else {
            root.materialSymbol = "wifi_off"
        }
    }

    // Monitoreo de velocidad
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            speedCheckProc.running = true
        }
    }

    Process {
        id: speedCheckProc
        command: ["bash", "-c", "\
            read up1 </sys/class/net/wlan0/statistics/tx_bytes 2>/dev/null || echo 0; \
            read down1 </sys/class/net/wlan0/statistics/rx_bytes 2>/dev/null || echo 0; \
            sleep 1; \
            read up2 </sys/class/net/wlan0/statistics/tx_bytes 2>/dev/null || echo 0; \
            read down2 </sys/class/net/wlan0/statistics/rx_bytes 2>/dev/null || echo 0; \
            echo $((up2 - up1)) $((down2 - down1))"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split(" ")
                if (parts.length >= 2) {
                    root.bandwidthUpBytes = parseInt(parts[0]) || 0
                    root.bandwidthDownBytes = parseInt(parts[1]) || 0
                    root.bandwidthUp = root.formatBytes(root.bandwidthUpBytes)
                    root.bandwidthDown = root.formatBytes(root.bandwidthDownBytes)
                }
            }
        }
    }

    // IP address
    Process {
        id: ipCheckProc
        running: true
        command: ["bash", "-c", "hostname -I | awk '{print $1}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.ipaddr = this.text.trim()
            }
        }
    }
}
