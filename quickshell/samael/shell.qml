//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1

import "ResourceUsage.qml"
import "PowerProfiles.qml"
import "ThermalZone.qml"
import "DiskUsage.qml"
import "Weather.qml"
import "NotificationIndicator.qml"
import "ClockWidget.qml"
import "WorkspacesKanji.qml"
import "Separator.qml"
import "CpuModule.qml"
import "RamModule.qml"
import "DiskModule.qml"
import "NetworkModule.qml"
import "BluetoothModule.qml"
import "TrayModule.qml"
import "MprisModule.qml"
import "AudioModule.qml"
import "PowerModule.qml"
import "KeyboardModule.qml"
import "SidebarRight.qml"
import "WifiManager.qml"
import "BluetoothManager.qml"

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

ShellRoot {
    id: root

    PanelWindow {
        id: panel
        screen: Quickshell.screens[0]
        WlrLayershell.namespace: "quickshell:bar"
        exclusiveZone: 32
        color: "transparent"

        anchors {
            top: true
            left: true
            right: true
        }

        margins {
            top: 1
            left: 8
            right: 8
            bottom: 2
        }

        implicitHeight: 40

        Row {
            id: leftSection
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                leftMargin: 4
                topMargin: 6
                bottomMargin: 6
            }
            spacing: 6

            // Distro icon
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: "#1793d1"

                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.pixelSize: 14
                    color: "#000000"
                }
            }

            CpuModule {}
            RamModule {}

            // Temperature
            Rectangle {
                width: 40
                height: 28
                radius: 15
                color: "#000000"
                border.width: 2
                border.color: "#f700ff"

                Text {
                    anchors.centerIn: parent
                    text: `${Math.round(ThermalZone.cpuTemperature / 1000)}°`
                    font.pixelSize: 12
                    font.family: "DejaVu Sans, sans-serif"
                    color: "#ff5349"
                }
            }

            DiskModule {}

            // Weather
            Rectangle {
                width: 50
                height: 28
                radius: 15
                color: "#000000"
                border.width: 2
                border.color: "#f700ff"

                Text {
                    anchors.centerIn: parent
                    text: Weather.icon
                    font.pixelSize: 14
                    font.family: "Twemoji, Noto Color Emoji, sans-serif"
                    color: "#df8e1d"
                }
            }
        }

        Row {
            id: centerSection
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                bottom: parent.bottom
                topMargin: 6
                bottomMargin: 6
            }
            spacing: 6
            NotificationIndicator {}
            Separator {}
            ClockWidget {}
            Separator {}
            WorkspacesKanji {}
        }

        Row {
            id: rightSection
            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                rightMargin: 4
                topMargin: 6
                bottomMargin: 6
            }
            spacing: 6
            NetworkSpeedModule {}
            NetworkModule {}
            BluetoothModule {}
            Separator {}
            KeyboardModule {}
            MprisModule {}
            AudioModule {}
            PowerModule {}
        }
    }

    SidebarRight {}
}
