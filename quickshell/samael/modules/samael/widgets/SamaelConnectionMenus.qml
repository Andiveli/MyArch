import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.samael.widgets

Scope {
    Connections {
        target: GlobalStates
        function onSamaelWifiMenuOpenChanged() {
            if (GlobalStates.samaelWifiMenuOpen) {
                GlobalStates.samaelBluetoothMenuOpen = false
                GlobalStates.samaelNotificationsMenuOpen = false
                GlobalStates.samaelSystemSidebarOpen = false
                GlobalStates.samaelSuperMenuOpen = false
                GlobalStates.wallpaperSelectorOpen = false
                GlobalStates.mediaControlsOpen = false
            }
        }
        function onSamaelBluetoothMenuOpenChanged() {
            if (GlobalStates.samaelBluetoothMenuOpen) {
                GlobalStates.samaelWifiMenuOpen = false
                GlobalStates.samaelNotificationsMenuOpen = false
                GlobalStates.samaelSystemSidebarOpen = false
                GlobalStates.samaelSuperMenuOpen = false
                GlobalStates.wallpaperSelectorOpen = false
                GlobalStates.mediaControlsOpen = false
            }
        }
        function onSamaelNotificationsMenuOpenChanged() {
            if (GlobalStates.samaelNotificationsMenuOpen) {
                GlobalStates.samaelWifiMenuOpen = false
                GlobalStates.samaelBluetoothMenuOpen = false
                GlobalStates.samaelSystemSidebarOpen = false
                GlobalStates.samaelSuperMenuOpen = false
                GlobalStates.wallpaperSelectorOpen = false
                GlobalStates.mediaControlsOpen = false
            }
        }
    }

    Loader {
        active: GlobalStates.samaelWifiMenuOpen
        sourceComponent: wifiPanel
    }

    Loader {
        active: GlobalStates.samaelBluetoothMenuOpen
        sourceComponent: btPanel
    }

    Loader {
        active: GlobalStates.samaelNotificationsMenuOpen
        sourceComponent: notifPanel
    }

    Component {
        id: wifiPanel
        PanelWindow {
            id: win
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:samael:wifiMenu"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"
            anchors.top: true
            margins.top: Appearance.sizes.barHeight + Appearance.sizes.hyprlandGapsOut + 4

            onVisibleChanged: {
                if (visible)
                    GlobalFocusGrab.addDismissable(win)
                else
                    GlobalFocusGrab.removeDismissable(win)
            }
            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    GlobalStates.samaelWifiMenuOpen = false
                }
            }

                property real offsetScale: 1

                Behavior on offsetScale {
                    NumberAnimation {
                        duration: Appearance.animation.samaelMediaAttach.duration
                        easing.type: Appearance.animation.samaelMediaAttach.type
                        easing.bezierCurve: Appearance.animation.samaelMediaAttach.bezierCurve
                    }
                }

                Item {
                    id: clipHost
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: attach.implicitWidth
                    height: attach.implicitHeight
                    clip: true

                    SamaelCaelestiaAttach {
                        id: attach
                        offsetScale: win.offsetScale
                        edge: "top"
                        SamaelWifiMenu { id: menu }
                    }
                }

                Component.onCompleted: Qt.callLater(() => { win.offsetScale = 0 })

                implicitWidth: attach.implicitWidth
                implicitHeight: attach.implicitHeight
                mask: Region { item: clipHost }
        }
    }

    Component {
        id: btPanel
        PanelWindow {
            id: win
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:samael:bluetoothMenu"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"
            anchors.top: true
            margins.top: Appearance.sizes.barHeight + Appearance.sizes.hyprlandGapsOut + 4

            onVisibleChanged: {
                if (visible)
                    GlobalFocusGrab.addDismissable(win)
                else
                    GlobalFocusGrab.removeDismissable(win)
            }
            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    GlobalStates.samaelBluetoothMenuOpen = false
                }
            }

                property real offsetScale: 1

                Behavior on offsetScale {
                    NumberAnimation {
                        duration: Appearance.animation.samaelMediaAttach.duration
                        easing.type: Appearance.animation.samaelMediaAttach.type
                        easing.bezierCurve: Appearance.animation.samaelMediaAttach.bezierCurve
                    }
                }

                Item {
                    id: clipHost
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: attach.implicitWidth
                    height: attach.implicitHeight
                    clip: true

                    SamaelCaelestiaAttach {
                        id: attach
                        offsetScale: win.offsetScale
                        edge: "top"
                        SamaelBluetoothMenu { id: menu }
                    }
                }

                Component.onCompleted: Qt.callLater(() => { win.offsetScale = 0 })

                implicitWidth: attach.implicitWidth
                implicitHeight: attach.implicitHeight
                mask: Region { item: clipHost }
        }
    }

    Component {
        id: notifPanel
        PanelWindow {
            id: win
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:samael:notificationsMenu"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"
            anchors.top: true
            margins.top: Appearance.sizes.barHeight + Appearance.sizes.hyprlandGapsOut + 4

            onVisibleChanged: {
                if (visible)
                    GlobalFocusGrab.addDismissable(win)
                else
                    GlobalFocusGrab.removeDismissable(win)
            }
            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    GlobalStates.samaelNotificationsMenuOpen = false
                }
            }

                property real offsetScale: 1

                Behavior on offsetScale {
                    NumberAnimation {
                        duration: Appearance.animation.samaelMediaAttach.duration
                        easing.type: Appearance.animation.samaelMediaAttach.type
                        easing.bezierCurve: Appearance.animation.samaelMediaAttach.bezierCurve
                    }
                }

                Item {
                    id: clipHost
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: attach.implicitWidth
                    height: attach.implicitHeight
                    clip: true

                    SamaelCaelestiaAttach {
                        id: attach
                        offsetScale: win.offsetScale
                        edge: "top"
                        SamaelNotificationsMenu { id: menu }
                    }
                }

                Component.onCompleted: Qt.callLater(() => { win.offsetScale = 0 })

                implicitWidth: attach.implicitWidth
                implicitHeight: attach.implicitHeight
                mask: Region { item: clipHost }
        }
    }
}