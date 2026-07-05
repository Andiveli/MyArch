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
        function onSamaelSystemSidebarOpenChanged() {
            if (GlobalStates.samaelSystemSidebarOpen) {
                GlobalStates.samaelWifiMenuOpen = false
                GlobalStates.samaelBluetoothMenuOpen = false
                GlobalStates.samaelNotificationsMenuOpen = false
                GlobalStates.samaelSuperMenuOpen = false
                GlobalStates.wallpaperSelectorOpen = false
                GlobalStates.mediaControlsOpen = false
            }
        }
        function onSamaelSuperMenuOpenChanged() {
            if (GlobalStates.samaelSuperMenuOpen) {
                GlobalStates.samaelWifiMenuOpen = false
                GlobalStates.samaelBluetoothMenuOpen = false
                GlobalStates.samaelNotificationsMenuOpen = false
                GlobalStates.samaelSystemSidebarOpen = false
                GlobalStates.wallpaperSelectorOpen = false
                GlobalStates.mediaControlsOpen = false
            }
        }
        function onSamaelWifiMenuOpenChanged() {
            if (GlobalStates.samaelWifiMenuOpen)
                GlobalStates.samaelSystemSidebarOpen = false
        }
        function onSamaelBluetoothMenuOpenChanged() {
            if (GlobalStates.samaelBluetoothMenuOpen)
                GlobalStates.samaelSystemSidebarOpen = false
        }
        function onSamaelNotificationsMenuOpenChanged() {
            if (GlobalStates.samaelNotificationsMenuOpen)
                GlobalStates.samaelSystemSidebarOpen = false
        }
    }

    Loader {
        active: GlobalStates.samaelSystemSidebarOpen
        sourceComponent: sidebarPanel
    }

    Component {
        id: sidebarPanel
        PanelWindow {
            id: win
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:samael:systemSidebar"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"
            anchors.top: true
            anchors.right: true
            margins.top: Appearance.sizes.barHeight + Appearance.sizes.hyprlandGapsOut + 8
            margins.right: Appearance.sizes.hyprlandGapsOut + 8

            onVisibleChanged: {
                if (visible)
                    GlobalFocusGrab.addDismissable(win)
                else
                    GlobalFocusGrab.removeDismissable(win)
            }
            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    GlobalStates.samaelSystemSidebarOpen = false
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
                    anchors.right: parent.right
                    width: attach.implicitWidth
                    height: attach.implicitHeight
                    clip: true

                    SamaelCaelestiaAttach {
                        id: attach
                        offsetScale: win.offsetScale
                        edge: "right"
                        SamaelSystemSidebar { id: sidebar }
                    }
                }

                Component.onCompleted: Qt.callLater(() => { win.offsetScale = 0 })

                implicitWidth: attach.implicitWidth
                implicitHeight: attach.implicitHeight
                mask: Region { item: clipHost }
        }
    }
}