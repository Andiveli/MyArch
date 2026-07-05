pragma Singleton
import QtQuick
import Quickshell
import qs
import qs.services

QtObject {
    property var motherboard: null
    property var clock: null
    property var audio: null

    function cyclePowerProfile() {
        if (motherboard)
            motherboard.cyclePowerProfile()
    }

    function stepPowerProfile(delta: int) {
        if (motherboard)
            motherboard.stepPowerProfile(delta)
    }

    function toggleMemDisplay() {
        if (motherboard)
            motherboard.toggleMemDisplay()
    }

    function toggleDiskDisplay() {
        if (motherboard)
            motherboard.toggleDiskDisplay()
    }

    function toggleClockExpanded() {
        if (clock)
            clock.toggleExpanded()
    }

    function openClockCalendar() {
        if (clock)
            clock.setExpanded(true)
    }

    function collapseClock() {
        if (clock)
            clock.setExpanded(false)
        GlobalStates.samaelClockDropOpen = false
        GlobalStates.samaelClockAnchorValid = false
    }

    function toggleAudioDrawer() {
        if (audio)
            audio.toggleDrawer()
    }

    function adjustVolume(delta: int) {
        if (delta > 0)
            Audio.incrementVolume()
        else if (delta < 0)
            Audio.decrementVolume()
    }

    function closeSamaelOverlaysExcept(except) {
        if (except !== "wifi")
        GlobalStates.samaelWifiMenuOpen = false
        if (except !== "bluetooth")
        GlobalStates.samaelBluetoothMenuOpen = false
        if (except !== "notifications")
        GlobalStates.samaelNotificationsMenuOpen = false
        if (except !== "systemSidebar")
        GlobalStates.samaelSystemSidebarOpen = false
        if (except !== "superMenu")
        GlobalStates.samaelSuperMenuOpen = false
        if (except !== "media")
        GlobalStates.mediaControlsOpen = false
        if (except !== "clock")
        GlobalStates.samaelClockDropOpen = false
        if (except !== "wallpaper")
        GlobalStates.wallpaperSelectorOpen = false
    }

    function toggleMediaManager() {
        const opening = !GlobalStates.mediaControlsOpen
        closeSamaelOverlaysExcept("media")
        GlobalStates.mediaControlsOpen = opening
    }

    function openNotificationsMenu() {
        closeSamaelOverlaysExcept("notifications")
        GlobalStates.samaelNotificationsMenuOpen = true
    }

    function toggleSystemSidebar() {
        const opening = !GlobalStates.samaelSystemSidebarOpen
        closeSamaelOverlaysExcept("systemSidebar")
        GlobalStates.samaelSystemSidebarOpen = opening
    }

    function toggleSuperMenu() {
        const opening = !GlobalStates.samaelSuperMenuOpen
        closeSamaelOverlaysExcept("superMenu")
        GlobalStates.samaelSuperMenuOpen = opening
    }

    // Hypr: Super+Shift+M → quickshell:samaelSuperMenuToggle

    function openSuperMenu() {
        closeSamaelOverlaysExcept("superMenu")
        GlobalStates.samaelSuperMenuOpen = true
    }

    function closeSuperMenu() {
        GlobalStates.samaelSuperMenuOpen = false
    }

    function openSystemSidebarFromSuperMenu() {
        closeSamaelOverlaysExcept("systemSidebar")
        GlobalStates.samaelSuperMenuOpen = false
        GlobalStates.samaelSystemSidebarOpen = true
    }

    function openSession() {
        GlobalStates.sessionOpen = true
    }

    function openAppDrawer() {
        Quickshell.execDetached("rofi -show drun -modi run,drun,filebrowser,window")
    }
}