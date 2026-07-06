import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.services.network
import qs.modules.samael

Rectangle {
    id: root
    color: "transparent"
    implicitWidth: 480
    implicitHeight: 340

    property int selectedIndex: 0
    property var networks: []

    function rebuildNetworks() {
        networks = Network.friendlyWifiNetworks
        if (selectedIndex >= networks.length)
            selectedIndex = Math.max(0, networks.length - 1)
    }

    function tryConnect() {
        const ap = networks[selectedIndex]
        if (!ap || ap.active)
            return
        if (ap.isSecure)
            Network.connectToWifiNetwork(ap)
        else
            Network.connectToWifiNetwork(ap)
    }

    function handleKey(event): bool {
        const n = networks.length
        if (n === 0)
            return false
        if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
            selectedIndex = (selectedIndex + 1) % n
            event.accepted = true
            return true
        }
        if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
            selectedIndex = (selectedIndex - 1 + n) % n
            event.accepted = true
            return true
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            tryConnect()
            event.accepted = true
            return true
        }
        if (event.key === Qt.Key_R) {
            Network.rescanWifi()
            event.accepted = true
            return true
        }
        if (event.key === Qt.Key_T) {
            Network.toggleWifi()
            event.accepted = true
            return true
        }
        return false
    }

    Component.onCompleted: {
        Network.rescanWifi()
        rebuildNetworks()
    }

    Connections {
        target: Network
        function onFriendlyWifiNetworksChanged() { root.rebuildNetworks() }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "WI-FI"
                font.family: SamaelStyle.fontFamily
                font.pixelSize: 11
                font.bold: true
                color: "#1a8cff"
            }
            Item { Layout.fillWidth: true }
            Text {
                text: Network.networkName || Network.wifiStatus
                font.family: SamaelStyle.fontFamily
                font.pixelSize: 9
                color: Qt.rgba(1, 1, 1, 0.55)
                elide: Text.ElideLeft
                Layout.maximumWidth: 120
            }
        }

        Text {
            text: "j/k · Enter connect · t wifi · r scan"
            font.family: SamaelStyle.fontFamily
            font.pixelSize: 8
            color: "#475569"
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            model: root.networks
            currentIndex: root.selectedIndex
            onCurrentIndexChanged: if (currentIndex >= 0)
                root.selectedIndex = currentIndex

            delegate: Rectangle {
                required property int index
                required property var modelData
                width: list.width
                height: 30
                radius: 4
                color: index === root.selectedIndex ? Qt.rgba(0.1, 0.45, 1, 0.15) : Qt.rgba(0, 0, 0, 0.2)
                border.width: index === root.selectedIndex ? 1 : 0
                border.color: "#1a8cff"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 6
                    Text {
                        text: modelData?.active ? "✓" : ""
                        color: "#10b981"
                        font.family: SamaelStyle.fontFamily
                        font.pixelSize: 10
                    }
                    Text {
                        Layout.fillWidth: true
                        text: modelData?.ssid ?? "?"
                        elide: Text.ElideRight
                        font.family: SamaelStyle.fontFamily
                        font.pixelSize: 10
                        color: "#e0e6f0"
                    }
                    Text {
                        text: modelData?.isSecure ? "󰌾" : ""
                        font.family: SamaelStyle.fontFamily
                        font.pixelSize: 10
                        color: "#94a3b8"
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.selectedIndex = index
                        root.tryConnect()
                    }
                }
            }
        }
    }
}