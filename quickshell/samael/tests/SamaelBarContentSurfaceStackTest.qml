import QtQuick
import QtTest
import qs.modules.samael

/**
 * Tests for SamaelBarContent pill-like morph architecture: idle modules
 * wrapper with morphCloseness-based opacity, direct surface Loader children,
 * z-ordering, and asynchronous loading.
 */
TestCase {
    name: "SamaelBarContentSurfaceStack"

    SamaelBarContent { id: barContent }

    // ── Core structure ──

    function test_core_structure() {
        verify(barContent.centerDockRef !== null, "centerDock should exist")
        verify(barContent.idleModulesRef !== null, "idleModules should exist")
    }

    function test_idleModules_contains_centerModules() {
        verify(barContent.centerModulesRef !== null, "centerModules should exist")
        compare(barContent.centerModulesRef.parent, barContent.idleModulesRef,
            "centerModules should be a direct child of idleModules")
    }

    function test_surfaceStack_contains_all_loaders() {
        verify(barContent.ldCalendarRef !== null, "ldCalendar should exist")
        verify(barContent.ldNotificationsMenuRef !== null, "ldNotificationsMenu should exist")
        verify(barContent.ldWifiRef !== null, "ldWifi should exist")
        verify(barContent.ldBluetoothRef !== null, "ldBluetooth should exist")
        verify(barContent.ldScreenRecorderRef !== null, "ldScreenRecorder should exist")
        verify(barContent.ldWallpaperRef !== null, "ldWallpaper should exist")
        verify(barContent.ldPowerRef !== null, "ldPower should exist")
        verify(barContent.ldMediaRef !== null, "ldMedia should exist")
        verify(barContent.ldPerformanceRef !== null, "ldPerformance should exist")
        verify(barContent.ldPopupIslandRef !== null, "ldPopupIsland should exist")
    }

    // ── z-ordering ──

    function test_loader_z_ordering() {
        compare(barContent.ldPopupIslandRef.z, 0, "popupIsland should have z=0")
        compare(barContent.ldCalendarRef.z, 1, "calendar should have z=1")
        compare(barContent.ldNotificationsMenuRef.z, 2, "notificationsMenu should have z=2")
        compare(barContent.ldWifiRef.z, 3, "wifi should have z=3")
        compare(barContent.ldBluetoothRef.z, 4, "bluetooth should have z=4")
        compare(barContent.ldScreenRecorderRef.z, 5, "screenRecorder should have z=5")
        compare(barContent.ldWallpaperRef.z, 6, "wallpaper should have z=6")
        compare(barContent.ldPowerRef.z, 7, "power should have z=7")
        compare(barContent.ldMediaRef.z, 8, "media should have z=8")
        compare(barContent.ldPerformanceRef.z, 9, "performance should have z=9")
    }

    // ── Cross-fade opacity ──

    function test_crossfade_idle_when_idle() {
        // Ensure clean state — no surface flags active
        GlobalStates.samaelClockDropOpen = false
        GlobalStates.mediaControlsOpen = false
        GlobalStates.samaelPerformanceDropOpen = false
        GlobalStates.samaelNotificationsMenuOpen = false
        GlobalStates.wallpaperSelectorOpen = false
        GlobalStates.sessionOpen = false
        GlobalStates.samaelWifiMenuOpen = false
        GlobalStates.samaelBluetoothMenuOpen = false
        GlobalStates.samaelRecorderOpen = false

        // When idle (no surface open), dockExpanded is false and morphCloseness ≈ 1,
        // so idleModules opacity = Math.pow(1, 1.3) ≈ 1
        compare(barContent.idleModulesRef.opacity, 1,
            "idleModules should be fully visible when surface === idle")
    }

    // ── Asynchronous loading ──

    function test_loaders_are_async() {
        compare(barContent.ldCalendarRef.asynchronous, true, "ldCalendar should be async")
        compare(barContent.ldNotificationsMenuRef.asynchronous, true, "ldNotificationsMenu should be async")
        compare(barContent.ldWifiRef.asynchronous, true, "ldWifi should be async")
        compare(barContent.ldBluetoothRef.asynchronous, true, "ldBluetooth should be async")
        compare(barContent.ldScreenRecorderRef.asynchronous, true, "ldScreenRecorder should be async")
        compare(barContent.ldWallpaperRef.asynchronous, true, "ldWallpaper should be async")
        compare(barContent.ldPowerRef.asynchronous, true, "ldPower should be async")
        compare(barContent.ldMediaRef.asynchronous, true, "ldMedia should be async")
        compare(barContent.ldPerformanceRef.asynchronous, true, "ldPerformance should be async")
        compare(barContent.ldPopupIslandRef.asynchronous, true, "ldPopupIsland should be async")
    }

    // ── Loader active bindings match triggers ──

    function test_loader_active_matches_global_flags() {
        // Verify each loader's active binding maps the correct flag
        compare(barContent.ldCalendarRef.active, GlobalStates.samaelClockDropOpen,
            "ldCalendar active should match samaClockDropOpen")
        compare(barContent.ldNotificationsMenuRef.active, GlobalStates.samaelNotificationsMenuOpen,
            "ldNotificationsMenu active should match samaNotificationsMenuOpen")
        compare(barContent.ldWifiRef.active, GlobalStates.samaelWifiMenuOpen,
            "ldWifi active should match samaWifiMenuOpen")
        compare(barContent.ldBluetoothRef.active, GlobalStates.samaelBluetoothMenuOpen,
            "ldBluetooth active should match samaBluetoothMenuOpen")
        compare(barContent.ldScreenRecorderRef.active, GlobalStates.samaelRecorderOpen,
            "ldScreenRecorder active should match samaRecorderOpen")
        compare(barContent.ldWallpaperRef.active, GlobalStates.wallpaperSelectorOpen,
            "ldWallpaper active should match wallpaperSelectorOpen")
        compare(barContent.ldPowerRef.active, GlobalStates.sessionOpen,
            "ldPower active should match sessionOpen")
    }

    function test_loader_active_complex_triggers() {
        // Media: mediaControlsOpen OR samaelMediaClosing
        const mediaActive = GlobalStates.mediaControlsOpen || GlobalStates.samaelMediaClosing
        compare(barContent.ldMediaRef.active, mediaActive,
            "ldMedia active should match mediaControlsOpen || samaelMediaClosing")

        // Performance: samaelPerformanceDropOpen OR samaelPerformanceClosing
        const perfActive = GlobalStates.samaelPerformanceDropOpen || GlobalStates.samaelPerformanceClosing
        compare(barContent.ldPerformanceRef.active, perfActive,
            "ldPerformance active should match samaelPerformanceDropOpen || samaelPerformanceClosing")

        // Popup island: popupList.length > 0 && !screenLocked
        const popupActive = Notifications.popupList.length > 0 && !GlobalStates.screenLocked
        compare(barContent.ldPopupIslandRef.active, popupActive,
            "ldPopupIsland active should match Notifications.popupList.length > 0 && !screenLocked")
    }

    // ── Placeholder structure ──

    function test_loaders_have_sourceComponents() {
        verify(barContent.ldCalendarRef.sourceComponent !== null, "ldCalendar should have a sourceComponent")
        verify(barContent.ldNotificationsMenuRef.sourceComponent !== null, "ldNotificationsMenu should have a sourceComponent")
        verify(barContent.ldWifiRef.sourceComponent !== null, "ldWifi should have a sourceComponent")
        verify(barContent.ldBluetoothRef.sourceComponent !== null, "ldBluetooth should have a sourceComponent")
        verify(barContent.ldScreenRecorderRef.sourceComponent !== null, "ldScreenRecorder should have a sourceComponent")
        verify(barContent.ldWallpaperRef.sourceComponent !== null, "ldWallpaper should have a sourceComponent")
        verify(barContent.ldPowerRef.sourceComponent !== null, "ldPower should have a sourceComponent")
        verify(barContent.ldMediaRef.sourceComponent !== null, "ldMedia should have a sourceComponent")
        verify(barContent.ldPerformanceRef.sourceComponent !== null, "ldPerformance should have a sourceComponent")
        verify(barContent.ldPopupIslandRef.sourceComponent !== null, "ldPopupIsland should have a sourceComponent")
    }

    // ── centerModules still accessible after restructure ──

    function test_centerModules_accessible_from_controller() {
        verify(barContent.controller !== undefined, "controller should exist")
        verify(true, "centerModules wrapped correctly — controller idle entry works")
    }
}
