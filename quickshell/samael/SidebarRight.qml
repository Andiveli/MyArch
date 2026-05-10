import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.Mpris

/**
 * Sidebar Right completo con menus funcionales
 */
Scope {
    id: root

    property int sidebarWidth: 380
    property bool sidebarOpen: false
    property int activeSection: 0

    readonly property color bgColor: "#000000"
    readonly property color borderColor: "#f700ff"
    readonly property color textColor: "#e5d9f5"
    readonly property color accentColor: "#cba6f7"
    readonly property color magentaColor: "#f700ff"
    readonly property color cyanColor: "#89b4fa"
    readonly property color redColor: "#ff5349"
    readonly property color orangeColor: "#fe640b"
    readonly property color greenColor: "#a6e3a1"
    readonly property color layer1Color: "#1a1a1a"

    property bool wifiEnabled: false
    property int volumeLevel: 0
    property bool volumeMuted: false
    property real brightnessLevel: 0.8

    // Managers
    WifiManager { id: wifiManager }
    BluetoothManager { id: btManager }

    readonly property string mediaTitle: Mpris.players.values[0]?.trackTitle ?? ""
    readonly property string mediaArtist: Mpris.players.values[0]?.trackArtist ?? ""
    readonly property bool mediaPlaying: Mpris.players.values[0]?.isPlaying ?? false
    readonly property real mediaProgress: Mpris.players.values[0]?.progress ?? 0

    Timer {
        running: sidebarOpen
        interval: 500
        repeat: true
        onTriggered: {
            volumeLevel = AudioModule.sinkVolume
            volumeMuted = AudioModule.sinkMuted
        }
    }

    PanelWindow {
        id: panelWindow
        visible: root.sidebarOpen
        function hide() { root.sidebarOpen = false; activeSection = 0 }

        exclusiveZone: 0
        implicitWidth: sidebarWidth
        WlrLayershell.namespace: "quickshell:samael:sidebarRight"
        color: "transparent"

        anchors { top: true; right: true; bottom: true }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 8
            color: bgColor
            border.width: 2
            border.color: borderColor
            radius: 15

            Flickable {
                anchors.fill: parent
                anchors.margins: 15
                contentHeight: mainContent.implicitHeight
                clip: true

                Column {
                    id: mainContent
                    width: parent.width
                    spacing: 12

                    // BACK BUTTON
                    Row {
                        width: parent.width
                        visible: activeSection > 0
                        spacing: 8
                        Rectangle {
                            width: 28; height: 28; radius: 14; color: layer1Color; border.width: 1; border.color: borderColor
                            Text { anchors.centerIn: parent; text: "←"; font.pixelSize: 14; color: cyanColor }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: activeSection = 0 }
                        }
                        Text {
                            text: activeSection === 1 ? "WiFi" : (activeSection === 2 ? "Bluetooth" : "Notificaciones")
                            font.pixelSize: 14; font.bold: true; color: textColor
                        }
                    }

                    // HEADER
                    RowLayout {
                        width: parent.width
                        spacing: 10
                        visible: activeSection === 0
                        Rectangle { width: 40; height: 40; radius: 20; color: accentColor
                            Text { anchors.centerIn: parent; text: "🐧"; font.pixelSize: 20; color: "#000000" }
                        }
                        Column {
                            Text { text: "Samael"; font.pixelSize: 15; font.bold: true; color: textColor }
                            Text { text: "Panel de Control"; font.pixelSize: 11; color: "#686868" }
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle { width: 28; height: 28; radius: 14; color: layer1Color; border.width: 1; border.color: borderColor
                            Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 12; color: redColor }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.sidebarOpen = false }
                        }
                    }

                    // MAIN MENU
                    Column {
                        width: parent.width
                        spacing: 12
                        visible: activeSection === 0

                        Rectangle { width: parent.width; height: 100; color: layer1Color; radius: 12; border.width: 1; border.color: borderColor
                            ColumnLayout { anchors.fill: parent; anchors.margins: 10; spacing: 10
                                RowLayout {
                                    Text { text: volumeMuted ? "🔇" : "🔊"; font.pixelSize: 16; color: magentaColor }
                                    ColumnLayout { Layout.fillWidth: true; spacing: 2
                                        Text { text: "Volumen " + volumeLevel + "%"; font.pixelSize: 10; color: textColor }
                                        Rectangle { Layout.fillWidth: true; height: 4; radius: 2; color: "#252525"
                                            Rectangle { width: volumeLevel * parent.width; height: parent.height; radius: 2; color: magentaColor }
                                        }
                                    }
                                }
                                RowLayout {
                                    Text { text: "☀️"; font.pixelSize: 16; color: orangeColor }
                                    ColumnLayout { Layout.fillWidth: true; spacing: 2
                                        Text { text: "Brillo " + Math.round(brightnessLevel * 100) + "%"; font.pixelSize: 10; color: textColor }
                                        Rectangle { Layout.fillWidth: true; height: 4; radius: 2; color: "#252525"
                                            Rectangle { width: brightnessLevel * parent.width; height: parent.height; radius: 2; color: orangeColor }
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout { width: parent.width; spacing: 8
                            Rectangle {
                                width: 85; height: 55; color: wifiManager.wifiEnabled ? cyanColor : layer1Color; radius: 10; border.width: 2; border.color: wifiManager.wifiEnabled ? cyanColor : borderColor
                                Column { anchors.centerIn: parent; spacing: 3
                                    Text { text: ""; font.pixelSize: 18; color: wifiManager.wifiEnabled ? "#000000" : cyanColor; anchors.horizontalCenter: parent.horizontalCenter }
                                    Text { text: "WiFi"; font.pixelSize: 10; color: wifiManager.wifiEnabled ? "#000000" : textColor; anchors.horizontalCenter: parent.horizontalCenter }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: activeSection = 1 }
                            }
                            Rectangle {
                                width: 85; height: 55; color: btManager.enabled ? cyanColor : layer1Color; radius: 10; border.width: 2; border.color: btManager.enabled ? cyanColor : borderColor
                                Column { anchors.centerIn: parent; spacing: 3
                                    Text { text: ""; font.pixelSize: 18; color: btManager.enabled ? "#000000" : cyanColor; anchors.horizontalCenter: parent.horizontalCenter }
                                    Text { text: "BT"; font.pixelSize: 10; color: btManager.enabled ? "#000000" : textColor; anchors.horizontalCenter: parent.horizontalCenter }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: activeSection = 2 }
                            }
                            Rectangle {
                                width: 85; height: 55; color: layer1Color; radius: 10; border.width: 2; border.color: borderColor
                                Column { anchors.centerIn: parent; spacing: 3
                                    Text { text: "🔔"; font.pixelSize: 18; color: orangeColor; anchors.horizontalCenter: parent.horizontalCenter }
                                    Text { text: "Notifs"; font.pixelSize: 9; color: textColor; anchors.horizontalCenter: parent.horizontalCenter }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: activeSection = 3 }
                            }
                            Rectangle { width: 55; height: 55; color: layer1Color; radius: 10; border.width: 2; border.color: borderColor
                                Column { anchors.centerIn: parent; spacing: 3
                                    Text { text: "🌙"; font.pixelSize: 18; color: orangeColor; anchors.horizontalCenter: parent.horizontalCenter }
                                    Text { text: "Luz"; font.pixelSize: 9; color: textColor; anchors.horizontalCenter: parent.horizontalCenter }
                                }
                            }
                        }

                        Rectangle { width: parent.width; height: mediaTitle ? 75 : 50; color: layer1Color; radius: 12; border.width: 1; border.color: borderColor
                            RowLayout { anchors.fill: parent; anchors.margins: 10; spacing: 10
                                Rectangle { width: 40; height: 40; radius: 20; color: mediaPlaying ? greenColor : "#353535"
                                    Text { anchors.centerIn: parent; text: mediaPlaying ? "⏸" : "▶"; font.pixelSize: 14; color: "#000000" }
                                }
                                ColumnLayout { Layout.fillWidth: true; spacing: 1
                                    Text { text: mediaTitle || "Sin reproduccion"; font.pixelSize: 12; font.bold: true; color: textColor; elide: Text.ElideRight }
                                    Text { text: mediaArtist || ""; font.pixelSize: 10; color: cyanColor; elide: Text.ElideRight }
                                    Rectangle { Layout.fillWidth: true; height: 3; radius: 1; color: "#252525"
                                        Rectangle { width: mediaProgress * parent.width; height: parent.height; radius: 1; color: greenColor }
                                    }
                                }
                            }
                        }

                        Column { width: parent.width; spacing: 8
                            Text { text: "Sistema"; font.pixelSize: 11; font.bold: true; color: textColor }
                            RowLayout { width: parent.width; spacing: 8
                                Rectangle { width: 65; height: 45; color: layer1Color; radius: 8; border.width: 1; border.color: borderColor
                                    Column { anchors.centerIn: parent; spacing: 1
                                        Text { text: "CPU"; font.pixelSize: 9; color: "#686868"; anchors.horizontalCenter: parent.horizontalCenter }
                                        Text { text: Math.round(ResourceUsage.cpuUsage * 100) + "%"; font.pixelSize: 12; font.bold: true; color: accentColor; anchors.horizontalCenter: parent.horizontalCenter }
                                    }
                                }
                                Rectangle { width: 65; height: 45; color: layer1Color; radius: 8; border.width: 1; border.color: borderColor
                                    Column { anchors.centerIn: parent; spacing: 1
                                        Text { text: "RAM"; font.pixelSize: 9; color: "#686868"; anchors.horizontalCenter: parent.horizontalCenter }
                                        Text { text: Math.round(ResourceUsage.memoryUsedPercentage * 100) + "%"; font.pixelSize: 12; font.bold: true; color: magentaColor; anchors.horizontalCenter: parent.horizontalCenter }
                                    }
                                }
                                Rectangle { width: 65; height: 45; color: layer1Color; radius: 8; border.width: 1; border.color: borderColor
                                    Column { anchors.centerIn: parent; spacing: 1
                                        Text { text: "TEMP"; font.pixelSize: 9; color: "#686868"; anchors.horizontalCenter: parent.horizontalCenter }
                                        Text { text: Math.round(ThermalZone.cpuTemperature / 1000) + "°"; font.pixelSize: 12; font.bold: true; color: redColor; anchors.horizontalCenter: parent.horizontalCenter }
                                    }
                                }
                                Rectangle { width: 65; height: 45; color: layer1Color; radius: 8; border.width: 1; border.color: borderColor
                                    Column { anchors.centerIn: parent; spacing: 1
                                        Text { text: "DISK"; font.pixelSize: 9; color: "#686868"; anchors.horizontalCenter: parent.horizontalCenter }
                                        Text { text: Math.round(DiskUsage.diskUsedPercentage * 100) + "%"; font.pixelSize: 12; font.bold: true; color: cyanColor; anchors.horizontalCenter: parent.horizontalCenter }
                                    }
                                }
                            }
                        }

                        RowLayout { width: parent.width; spacing: 8
                            Rectangle { width: 85; height: 36; color: layer1Color; radius: 8; border.width: 1; border.color: borderColor
                                Row { anchors.centerIn: parent; spacing: 5
                                    Text { text: "🔒"; font.pixelSize: 12; color: textColor }
                                    Text { text: "Bloquear"; font.pixelSize: 10; font.bold: true; color: textColor }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["hyprlock"]) }
                            }
                            Rectangle { width: 85; height: 36; color: layer1Color; radius: 8; border.width: 1; border.color: borderColor
                                Row { anchors.centerIn: parent; spacing: 5
                                    Text { text: "🔄"; font.pixelSize: 12; color: orangeColor }
                                    Text { text: "Recargar"; font.pixelSize: 10; font.bold: true; color: orangeColor }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Hyprland.dispatch("reload"); Quickshell.reload(true) } }
                            }
                            Rectangle { width: 85; height: 36; color: layer1Color; radius: 8; border.width: 1; border.color: borderColor
                                Row { anchors.centerIn: parent; spacing: 5
                                    Text { text: "⏻"; font.pixelSize: 12; color: redColor }
                                    Text { text: "Apagar"; font.pixelSize: 10; font.bold: true; color: redColor }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["wlogout"]) }
                            }
                        }
                    }

                    // WIFI MENU
                    Column { width: parent.width; spacing: 8; visible: activeSection === 1
                        RowLayout {
                            width: parent.width
                            Text { text: "WiFi"; font.pixelSize: 11; font.bold: true; color: textColor }
                            Item { Layout.fillWidth: true }
                            Rectangle { width: 50; height: 24; radius: 12; color: wifiManager.wifiEnabled ? cyanColor : layer1Color; border.width: 1; border.color: borderColor
                                Text { anchors.centerIn: parent; text: wifiManager.wifiEnabled ? "ON" : "OFF"; font.pixelSize: 9; color: wifiManager.wifiEnabled ? "#000000" : "#686868" }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: wifiManager.toggle() }
                            }
                        }
                        Rectangle { width: parent.width; height: 30; radius: 8; color: layer1Color; border.width: 1; border.color: borderColor
                            Text { anchors.centerIn: parent; text: wifiManager.scanning ? "Escaneando..." : "Actualizar redes"; font.pixelSize: 11; color: cyanColor }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: wifiManager.scanNetworks() }
                        }
                        Column { width: parent.width; spacing: 4
                            Repeater {
                                model: wifiManager.networks.slice(0, 8)
                                delegate: Rectangle {
                                    width: parent.width; height: 40; radius: 8; color: modelData.connected ? cyanColor : layer1Color; border.width: 1; border.color: modelData.connected ? cyanColor : borderColor
                                    RowLayout { anchors.fill: parent; anchors.margins: 8; spacing: 8
                                        Text { text: "📶"; font.pixelSize: 14; color: modelData.connected ? "#000000" : textColor }
                                        Text { text: modelData.ssid; font.pixelSize: 11; color: modelData.connected ? "#000000" : textColor; elide: Text.ElideRight }
                                        Item { Layout.fillWidth: true }
                                        Text { text: modelData.connected ? "✓" : (modelData.signal + "%"); font.pixelSize: 10; color: modelData.connected ? "#000000" : "#686868" }
                                        Text { text: "🔒"; font.pixelSize: 10; color: modelData.connected ? "#000000" : "#686868"; visible: modelData.secured }
                                    }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: wifiManager.connect(modelData.ssid) }
                                }
                            }
                        }
                        Text { text: wifiManager.networks.length === 0 ? "No hay redes. Activa WiFi y actualiza." : ""; font.pixelSize: 10; color: "#686868"; width: parent.width; wrapMode: Text.WordWrap }
                    }

                    // BLUETOOTH MENU
                    Column { width: parent.width; spacing: 8; visible: activeSection === 2
                        RowLayout {
                            width: parent.width
                            Text { text: "Bluetooth"; font.pixelSize: 11; font.bold: true; color: textColor }
                            Item { Layout.fillWidth: true }
                            Rectangle { width: 50; height: 24; radius: 12; color: btManager.enabled ? cyanColor : layer1Color; border.width: 1; border.color: borderColor
                                Text { anchors.centerIn: parent; text: btManager.enabled ? "ON" : "OFF"; font.pixelSize: 9; color: btManager.enabled ? "#000000" : "#686868" }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: btManager.toggle() }
                            }
                        }
                        Rectangle { width: parent.width; height: 30; radius: 8; color: layer1Color; border.width: 1; border.color: borderColor
                            Text { anchors.centerIn: parent; text: "Escanear dispositivos"; font.pixelSize: 11; color: cyanColor }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: btManager.getDevices() }
                        }
                        Column { width: parent.width; spacing: 4
                            Repeater {
                                model: btManager.devices.slice(0, 10)
                                delegate: Rectangle {
                                    width: parent.width; height: 36; radius: 8; color: layer1Color; border.width: 1; border.color: borderColor
                                    RowLayout { anchors.fill: parent; anchors.margins: 8; spacing: 8
                                        Text { text: "🎧"; font.pixelSize: 14; color: textColor }
                                        Text { text: modelData.name || modelData.mac; font.pixelSize: 11; color: textColor; elide: Text.ElideRight; Layout.maximumWidth: 180 }
                                        Item { Layout.fillWidth: true }
                                    }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: btManager.connect(modelData.mac) }
                                }
                            }
                        }
                    }

                    // NOTIFICATIONS MENU
                    Column { width: parent.width; spacing: 8; visible: activeSection === 3
                        Text { text: "Notificaciones"; font.pixelSize: 11; font.bold: true; color: textColor }
                        Rectangle { width: parent.width; height: 30; radius: 8; color: layer1Color; border.width: 1; border.color: borderColor
                            Text { anchors.centerIn: parent; text: "Abrir notificaciones (swaync)"; font.pixelSize: 11; color: cyanColor }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["swaync-client", "-t"]) }
                        }
                        Text { text: "Las notificaciones requieren swaync o mako"; font.pixelSize: 10; color: "#686868"; width: parent.width; wrapMode: Text.WordWrap }
                    }

                    Item { height: 20 }
                }
            }
        }
    }

    IpcHandler {
        target: "sidebarRight"
        function toggle() {
            if (root.sidebarOpen) {
                root.sidebarOpen = false
                activeSection = 0
            } else {
                root.sidebarOpen = true
            }
        }
        function open() { root.sidebarOpen = true; activeSection = 0 }
        function close() { root.sidebarOpen = false; activeSection = 0 }
    }

    GlobalShortcut {
        name: "sidebarRightToggle"
        description: "Toggle right sidebar"
        onPressed: {
            if (root.sidebarOpen) {
                root.sidebarOpen = false
                activeSection = 0
            } else {
                root.sidebarOpen = true
            }
        }
    }
}
