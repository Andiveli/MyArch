pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs
import qs.services

QtObject {
    property var motherboard: null
    property var clock: null
    property var audio: null
    /// The currently active surface item (from the focused bar's surface stack).
    /// Set by SamaelBarContent when effectiveSurface changes.
    /// Used by keyboard routing to dispatch h/l/j/k/Enter/Esc to the surface.
    property var currentSurfaceItem: null

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
        if (except !== "performance")
        GlobalStates.samaelPerformanceDropOpen = false
        if (except !== "clock")
        GlobalStates.samaelClockDropOpen = false
        if (except !== "wallpaper")
        GlobalStates.wallpaperSelectorOpen = false
    }

    function toggleMediaManager() {
        const opening = !GlobalStates.mediaControlsOpen
        if (opening) {
            saveCurrentHyprClient()
        }
        closeSamaelOverlaysExcept("media")
        GlobalStates.mediaControlsOpen = opening
        if (!opening) {
            Qt.callLater(restoreHyprClientIfNeeded)
        }
    }

    function openNotificationsMenu() {
        closeSamaelOverlaysExcept("notifications")
        GlobalStates.samaelNotificationsMenuOpen = true
    }

    function toggleSystemSidebar() {
        const opening = !GlobalStates.samaelSystemSidebarOpen
        if (opening) {
            saveCurrentHyprClient()
        }
        closeSamaelOverlaysExcept("systemSidebar")
        GlobalStates.samaelSystemSidebarOpen = opening
        if (!opening) {
            Qt.callLater(restoreHyprClientIfNeeded)
        }
    }

    function togglePerformanceDrop() {
        const opening = !GlobalStates.samaelPerformanceDropOpen
        if (opening) {
            saveCurrentHyprClient()
        }
        closeSamaelOverlaysExcept("performance")
        GlobalStates.samaelPerformanceDropOpen = opening
        if (!opening) {
            Qt.callLater(restoreHyprClientIfNeeded)
        }
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

    // ── Mapeo simple de foco Hyprland ──
    // Guardás el cliente activo ANTES de abrir cualquier cosa que robe el foco (media, sidebars, etc.).
    // Al cerrar, restaurás con los dos dispatch (patrón que funciona confiable en Hyprland).
    function saveCurrentHyprClient() {
        if (GlobalStates.hyprLastClientBeforeOverlay && GlobalStates.hyprLastClientBeforeOverlay.length > 0)
            return
        const addr = Hyprland.activeToplevel?.lastIpcObject?.address
        if (addr)
            GlobalStates.hyprLastClientBeforeOverlay = String(addr)
    }

    function restoreHyprClient() {
        const addr = GlobalStates.hyprLastClientBeforeOverlay
        if (!addr || addr.length === 0)
            return
        GlobalStates.hyprLastClientBeforeOverlay = ""
        Hyprland.dispatch("focuswindow", "address:" + addr)
        Qt.callLater(() => Hyprland.dispatch("focuswindow", "address:" + addr))
    }
}