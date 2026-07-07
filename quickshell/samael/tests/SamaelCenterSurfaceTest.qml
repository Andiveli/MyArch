import QtQuick
import QtTest
import qs.modules.samael

/**
 * Tests for SamaelCenterSurface controller logic.
 * Covers precedence, default surface sizes, computeMorphCloseness,
 * and keyboard dispatch helpers.
 *
 * These are pure-logic tests — no UI rendering dependency.
 */
TestCase {
    name: "SamaelCenterSurface"

    function test_precedence_wallpaper_wins() {
        // wallpaper > power > notificationsMenu > media > performance >
        // wifi > bluetooth > calendar > screenRecorder > popupIsland > idle
        GlobalStates.wallpaperSelectorOpen = true
        GlobalStates.sessionOpen = true
        compare(SamaelCenterSurface.effectiveSurface, "wallpaper",
            "wallpaper should beat power")
        GlobalStates.wallpaperSelectorOpen = false
        GlobalStates.sessionOpen = false
    }

    function test_precedence_power_wins() {
        GlobalStates.sessionOpen = true
        GlobalStates.samaelNotificationsMenuOpen = true
        compare(SamaelCenterSurface.effectiveSurface, "power",
            "power should beat notifications")
        GlobalStates.sessionOpen = false
        GlobalStates.samaelNotificationsMenuOpen = false
    }

    function test_precedence_notifications_over_media() {
        GlobalStates.samaelNotificationsMenuOpen = true
        GlobalStates.mediaControlsOpen = true
        compare(SamaelCenterSurface.effectiveSurface, "notificationsMenu",
            "notifications should beat media")
        GlobalStates.samaelNotificationsMenuOpen = false
        GlobalStates.mediaControlsOpen = false
    }

    function test_precedence_media_over_performance() {
        GlobalStates.mediaControlsOpen = true
        GlobalStates.samaelPerformanceDropOpen = true
        compare(SamaelCenterSurface.effectiveSurface, "media",
            "media should beat performance")
        GlobalStates.mediaControlsOpen = false
        GlobalStates.samaelPerformanceDropOpen = false
    }

    function test_precedence_wifi_after_performance() {
        GlobalStates.samaelWifiMenuOpen = true
        GlobalStates.mediaControlsOpen = true
        compare(SamaelCenterSurface.effectiveSurface, "media",
            "media should beat wifi")
        GlobalStates.mediaControlsOpen = false
        compare(SamaelCenterSurface.effectiveSurface, "wifi",
            "wifi should show when media is closed")
        GlobalStates.samaelWifiMenuOpen = false
    }

    function test_precedence_calendar_after_bluetooth() {
        GlobalStates.samaelClockDropOpen = true
        GlobalStates.samaelBluetoothMenuOpen = true
        compare(SamaelCenterSurface.effectiveSurface, "bluetooth",
            "bluetooth should beat calendar")
        GlobalStates.samaelClockDropOpen = false
        GlobalStates.samaelBluetoothMenuOpen = false
    }

    function test_precedence_recorder_lowest_after_popup() {
        GlobalStates.samaelRecorderOpen = true
        GlobalStates.wallpaperSelectorOpen = false
        GlobalStates.sessionOpen = false
        GlobalStates.samaelNotificationsMenuOpen = false
        GlobalStates.mediaControlsOpen = false
        GlobalStates.samaelPerformanceDropOpen = false
        GlobalStates.samaelWifiMenuOpen = false
        GlobalStates.samaelBluetoothMenuOpen = false
        GlobalStates.samaelClockDropOpen = false
        compare(SamaelCenterSurface.effectiveSurface, "screenRecorder",
            "recorder should show when nothing higher wins")
        GlobalStates.samaelRecorderOpen = false
    }

    function test_idle_when_nothing_open() {
        GlobalStates.wallpaperSelectorOpen = false
        GlobalStates.sessionOpen = false
        GlobalStates.samaelNotificationsMenuOpen = false
        GlobalStates.mediaControlsOpen = false
        GlobalStates.samaelMediaClosing = false
        GlobalStates.samaelPerformanceDropOpen = false
        GlobalStates.samaelPerformanceClosing = false
        GlobalStates.samaelWifiMenuOpen = false
        GlobalStates.samaelBluetoothMenuOpen = false
        GlobalStates.samaelClockDropOpen = false
        GlobalStates.samaelRecorderOpen = false
        compare(SamaelCenterSurface.effectiveSurface, "idle",
            "should be idle when nothing is open")
    }

    function test_computeMorphCloseness_at_target() {
        const result = SamaelCenterSurface.computeMorphCloseness(400, 300, 400, 300, 1)
        compare(result, 1, "closeness should be 1 when dimensions match")
    }

    function test_computeMorphCloseness_far() {
        const result = SamaelCenterSurface.computeMorphCloseness(100, 50, 500, 300, 1)
        fuzzyCompare(result, 0, 0.01,
            "closeness should be ~0 when dimensions are far apart")
    }

    function test_computeMorphCloseness_halfway() {
        // target: 400x300, current: 250x175 -> max diff = 150
        // denom = 110 * 1 = 110, clamped distance = min(1, 150/110) ≈ 1
        // closeness = 1 - 1 = 0
        const result = SamaelCenterSurface.computeMorphCloseness(250, 175, 400, 300, 1)
        verify(result >= 0 && result < 0.5,
            "closeness should be < 0.5 when >110px from target")
    }

    function test_computeMorphCloseness_with_scale() {
        // target: 400x300, current: 350x250, max diff = 50, denom = 110*2 = 220
        // distance = min(1, 50/220) ≈ 0.227
        // closeness = 1 - 0.227 ≈ 0.773
        const result = SamaelCenterSurface.computeMorphCloseness(350, 250, 400, 300, 2)
        verify(result > 0.5 && result < 1,
            "with s=2, 50px diff should give closeness between 0.5 and 1")
    }

    function test_surfaceEntry_returns_default() {
        const entry = SamaelCenterSurface.surfaceEntry("media", "")
        verify(entry !== undefined, "surfaceEntry should return an entry")
        const size = entry.size()
        compare(size.width, 728, "default media width should be 728")
    }

    function test_surfaceEntry_returns_custom() {
        // Register a per-bar override
        SamaelCenterSurface.registerSurfaceSizes("test-bar", {
            media: { size: () => Qt.size(800, 500) }
        })
        const entry = SamaelCenterSurface.surfaceEntry("media", "test-bar")
        const size = entry.size()
        compare(size.width, 800, "overridden media width should be 800")
        compare(size.height, 500, "overridden media height should be 500")
        SamaelCenterSurface.unregisterSurfaceSizes("test-bar")
    }

    function test_isIdleSurface() {
        compare(SamaelCenterSurface.isIdleSurface("idle"), true)
        compare(SamaelCenterSurface.isIdleSurface("media"), false)
    }

    function test_dispatchToSurface_calls_moveH() {
        var calls = []
        var surface = {
            moveH: function(dir) { calls.push("moveH:" + dir) },
            moveV: function(dir) {},
            activate: function() {},
            back: function() { return false }
        }
        SamaelCenterSurface.dispatchToSurface(surface, "h")
        compare(calls.length, 1, "should call moveH once")
        compare(calls[0], "moveH:-1", "h should map to moveH(-1)")

        SamaelCenterSurface.dispatchToSurface(surface, "l")
        compare(calls.length, 2, "should call moveH again")
        compare(calls[1], "moveH:1", "l should map to moveH(1)")
    }

    function test_dispatchToSurface_back_returned() {
        var calls = []
        var consumedSurface = {
            moveH: function(dir) {},
            moveV: function(dir) {},
            activate: function() {},
            back: function() { return true }
        }
        var unhandled = SamaelCenterSurface.dispatchToSurface(consumedSurface, "esc")
        compare(unhandled, true, "back() returning true should propagate")

        var notConsumedSurface = {
            moveH: function(dir) {},
            moveV: function(dir) {},
            activate: function() {},
            back: function() { return false }
        }
        unhandled = SamaelCenterSurface.dispatchToSurface(notConsumedSurface, "esc")
        compare(unhandled, false, "back() returning false should propagate")
    }

    function test_dispatchToSurface_null_safe() {
        compare(SamaelCenterSurface.dispatchToSurface(null, "h"), false,
            "null surface should return false")
        compare(SamaelCenterSurface.dispatchToSurface(undefined, "h"), false,
            "undefined surface should return false")
    }

    function test_surfaceMoveH_surfaceMoveV_helpers() {
        var calls = []
        var surface = {
            moveH: function(dir) { calls.push("h:" + dir) },
            moveV: function(dir) { calls.push("v:" + dir) },
            activate: function() {},
            back: function() { return false }
        }
        SamaelCenterSurface.surfaceMoveH(surface, -1)
        compare(calls[0], "h:-1")
        SamaelCenterSurface.surfaceMoveH(surface, 1)
        compare(calls[1], "h:1")
        SamaelCenterSurface.surfaceMoveV(surface, -1)
        compare(calls[2], "v:-1")
        SamaelCenterSurface.surfaceMoveV(surface, 1)
        compare(calls[3], "v:1")
    }

    function test_surfaceActivate() {
        var activated = false
        var surface = {
            moveH: function(dir) {},
            moveV: function(dir) {},
            activate: function() { activated = true },
            back: function() { return false }
        }
        SamaelCenterSurface.surfaceActivate(surface)
        compare(activated, true, "activate should be called")
    }
}
