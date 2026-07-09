import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.samael
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

    // All overlays removed: wifi, bluetooth, and notifications now render
    // inside the centerDock via SamaelCenterSurface.effectiveSurface matching.
}