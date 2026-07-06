import QtQuick
import Quickshell
import qs
import qs.services

Scope {
    function closeOtherSamaelPanels() {
        GlobalStates.samaelWifiMenuOpen = false
        GlobalStates.samaelBluetoothMenuOpen = false
        GlobalStates.samaelNotificationsMenuOpen = false
        GlobalStates.samaelSystemSidebarOpen = false
        GlobalStates.samaelSuperMenuOpen = false
        GlobalStates.samaelClockDropOpen = false
        GlobalStates.wallpaperSelectorOpen = false
        GlobalStates.mediaControlsOpen = false
    }

    Connections {
        target: GlobalStates
        function onSamaelPerformanceDropOpenChanged() {
            if (GlobalStates.samaelPerformanceDropOpen)
                closeOtherSamaelPanels()
        }
    }

    Connections {
        target: GlobalStates
        function onMediaControlsOpenChanged() {
            if (GlobalStates.mediaControlsOpen)
                GlobalStates.samaelPerformanceDropOpen = false
        }
        function onSamaelSystemSidebarOpenChanged() {
            if (GlobalStates.samaelSystemSidebarOpen)
                GlobalStates.samaelPerformanceDropOpen = false
        }
        function onSamaelSuperMenuOpenChanged() {
            if (GlobalStates.samaelSuperMenuOpen)
                GlobalStates.samaelPerformanceDropOpen = false
        }
        function onSamaelWifiMenuOpenChanged() {
            if (GlobalStates.samaelWifiMenuOpen)
                GlobalStates.samaelPerformanceDropOpen = false
        }
        function onSamaelBluetoothMenuOpenChanged() {
            if (GlobalStates.samaelBluetoothMenuOpen)
                GlobalStates.samaelPerformanceDropOpen = false
        }
        function onSamaelNotificationsMenuOpenChanged() {
            if (GlobalStates.samaelNotificationsMenuOpen)
                GlobalStates.samaelPerformanceDropOpen = false
        }
        function onSamaelClockDropOpenChanged() {
            if (GlobalStates.samaelClockDropOpen)
                GlobalStates.samaelPerformanceDropOpen = false
        }
    }
}