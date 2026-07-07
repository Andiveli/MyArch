pragma Singleton

import QtQuick
import qs.services

/**
 * Center pill morph surface controller — precedence, default surface sizes,
 * and keyboard routing dispatch.
 *
 * Order: wallpaper > power > notificationsMenu > media > performance >
 *        wifi > bluetooth > calendar > screenRecorder > notificationPopup > idle
 *
 * Popup island vs notifications menu: user-opened menu (samaelNotificationsMenuOpen) wins over
 * auto notificationPopup while the menu is open; when the menu closes, popups can show again.
 *
 * The surfaces table with per-bar Loader-aware size thunks is defined in each
 * SamaelBarContent instance (since Loaders are per-monitor). The singleton provides
 * the precedence string, default sizes, and dispatch helpers.
 */
QtObject {
    id: root

    // ── Precedence ──────────────────────────────────────────────────────

    /** Effective surface ID based on precedence (highest wins). */
    readonly property string effectiveSurface: {
        if (GlobalStates.wallpaperSelectorOpen)
            return "wallpaper"
        if (GlobalStates.sessionOpen)
            return "power"
        if (GlobalStates.samaelNotificationsMenuOpen)
            return "notificationsMenu"
        const mediaActive = GlobalStates.mediaControlsOpen || GlobalStates.samaelMediaClosing
        const perfActive = GlobalStates.samaelPerformanceDropOpen || GlobalStates.samaelPerformanceClosing
        if (mediaActive)
            return "media"
        if (perfActive)
            return "performance"
        if (GlobalStates.samaelWifiMenuOpen)
            return "wifi"
        if (GlobalStates.samaelBluetoothMenuOpen)
            return "bluetooth"
        if (GlobalStates.samaelClockDropOpen)
            return "calendar"
        if (GlobalStates.samaelRecorderOpen)
            return "screenRecorder"
        if (Notifications.popupList.length > 0 && !GlobalStates.screenLocked)
            return "popupIsland"
        return "idle"
    }

    function isIdleSurface(surfaceId) {
        return surfaceId === "idle"
    }

    // ── Default Surface Dimensions (override per-bar with actual Loader sizes) ──

    /**
     * Default surface size table.  Per-bar controllers (SamaelBarContent) override
     * entries with actual Loader-aware thunks via registerSurfaceSizes().
     *
     * Widths are fixed spec values; heights use implicitHeight fallbacks.
     */
    readonly property var defaultSurfaceSizes: ({
        idle:             { size: () => Qt.size(0, 0) },     // overridden by bar
        calendar:         { size: () => Qt.size(300, 360) },
        notificationsMenu:{ size: () => Qt.size(540, 480) },
        wifi:             { size: () => Qt.size(400, 420) },
        bluetooth:        { size: () => Qt.size(400, 420) },
        screenRecorder:   { size: () => Qt.size(520, 340) },
        wallpaper:        { size: () => Qt.size(960, 520) },
        power:            { size: () => Qt.size(480, 240) },
        media:            { size: () => Qt.size(728, 400) },
        performance:      { size: () => Qt.size(840, 480) },
        popupIsland:      { size: () => Qt.size(380, 300) }
    })

    // ── Per-bar surface size overrides ──────────────────────────────────

    /**
     * Registered per-bar surface size overrides.
     * Keyed by barScreenName → { surfaceId → { size: thunk } }.
     * Each SamaelBarContent instance registers its Loader-aware overrides
     * in Component.onCompleted.
     */
    property var _barOverrides: ({})

    /** Register surface sizes for a specific bar instance. */
    function registerSurfaceSizes(barName, overrides) {
        _barOverrides[barName] = overrides
    }

    /** Unregister surface sizes when a bar is destroyed. */
    function unregisterSurfaceSizes(barName) {
        delete _barOverrides[barName]
    }

    /**
     * Resolve a surface entry (merging bar overrides over defaults).
     * If barName is empty or unregistered, returns the default entry.
     */
    function surfaceEntry(surfaceId, barName) {
        const barOverrides = _barOverrides[barName]
        if (barOverrides && barOverrides[surfaceId])
            return barOverrides[surfaceId]
        return defaultSurfaceSizes[surfaceId] || defaultSurfaceSizes.idle
    }

    /**
     * Compute target size for a surface in a specific bar.
     * Returns Qt.size(width, height).
     */
    function targetSizeFor(surfaceId, barName) {
        const entry = surfaceEntry(surfaceId, barName)
        return entry ? entry.size() : Qt.size(0, 0)
    }

    // ── Morph Closeness ────────────────────────────────────────────────

    /**
     * Compute morph closeness given current and target dimensions.
     * Returns a value in [0, 1] where 1 = fully morphed to target.
     * Formula: 1 - clamp(|distance| / (110 * s), 0, 1)
     * where distance is max of abs(width diff) and abs(height diff).
     */
    function computeMorphCloseness(currentW, currentH, targetW, targetH, s) {
        const d = Math.max(
            Math.abs(currentW - targetW),
            Math.abs(currentH - targetH)
        )
        const denom = 110 * (s || 1)
        return 1 - Math.min(1, d / denom)
    }

    // ── Keyboard Dispatch ──────────────────────────────────────────────

    /**
     * Dispatch a named key to a surface's item.
     * Returns true if the key was handled, false otherwise.
     */
    function dispatchToSurface(surfaceItem, key) {
        if (!surfaceItem || typeof surfaceItem !== "object")
            return false

        switch (key) {
            case "h":       surfaceItem.moveH(-1); return true
            case "l":       surfaceItem.moveH(1);  return true
            case "j":       surfaceItem.moveV(1);  return true
            case "k":       surfaceItem.moveV(-1); return true
            case "enter":   surfaceItem.activate(); return true
            case "esc":     return surfaceItem.back() === true
        }
        return false
    }

    /** Convenience: dispatch all direction/move keys by delta. */
    function surfaceMoveH(surfaceItem, delta) {
        return dispatchToSurface(surfaceItem, delta < 0 ? "h" : "l")
    }

    function surfaceMoveV(surfaceItem, delta) {
        return dispatchToSurface(surfaceItem, delta < 0 ? "k" : "j")
    }

    function surfaceActivate(surfaceItem) {
        return dispatchToSurface(surfaceItem, "enter")
    }

    function surfaceBackOrClose(surfaceItem) {
        return dispatchToSurface(surfaceItem, "esc")
    }
}
