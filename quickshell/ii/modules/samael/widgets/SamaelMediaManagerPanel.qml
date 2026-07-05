import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.samael.widgets

Scope {
    function closeOtherSamaelPanels() {
        GlobalStates.samaelWifiMenuOpen = false
        GlobalStates.samaelBluetoothMenuOpen = false
        GlobalStates.samaelNotificationsMenuOpen = false
        GlobalStates.samaelSystemSidebarOpen = false
        GlobalStates.samaelSuperMenuOpen = false
        GlobalStates.samaelClockDropOpen = false
        GlobalStates.wallpaperSelectorOpen = false
    }

    Connections {
        target: GlobalStates
        function onMediaControlsOpenChanged() {
            if (GlobalStates.mediaControlsOpen)
                closeOtherSamaelPanels()
        }
    }

    Connections {
        target: GlobalStates
        function onSamaelWifiMenuOpenChanged() {
            if (GlobalStates.samaelWifiMenuOpen)
                GlobalStates.mediaControlsOpen = false
        }
        function onSamaelBluetoothMenuOpenChanged() {
            if (GlobalStates.samaelBluetoothMenuOpen)
                GlobalStates.mediaControlsOpen = false
        }
        function onSamaelNotificationsMenuOpenChanged() {
            if (GlobalStates.samaelNotificationsMenuOpen)
                GlobalStates.mediaControlsOpen = false
        }
        function onSamaelSystemSidebarOpenChanged() {
            if (GlobalStates.samaelSystemSidebarOpen)
                GlobalStates.mediaControlsOpen = false
        }
        function onSamaelSuperMenuOpenChanged() {
            if (GlobalStates.samaelSuperMenuOpen)
                GlobalStates.mediaControlsOpen = false
        }
        function onSamaelClockDropOpenChanged() {
            if (GlobalStates.samaelClockDropOpen)
                GlobalStates.mediaControlsOpen = false
        }
    }
}