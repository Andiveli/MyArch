pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * System overview metrics — polling runs only while the right-pill overview is open.
 * Heavy session lives in surfaces/SystemOverviewSession.qml (Loader).
 */
Singleton {
    id: root

    property bool panelOpen: false

    readonly property real cpuUsage: { const _r = _sessionRev; return _session ? _session.cpuUsage : 0 }
    readonly property int memTotalKb: _session ? _session.memTotalKb : 1
    readonly property int memUsedKb: _session ? _session.memUsedKb : 0
    readonly property real memUsedRatio: memTotalKb > 0 ? memUsedKb / memTotalKb : 0

    readonly property real gpuUsage: _session ? _session.gpuUsage : NaN
    readonly property bool gpuAvailable: _session ? _session.gpuAvailable : false
    readonly property string gpuKind: _session ? _session.gpuKind : ""
    readonly property string gpuLabel: _session ? _session.gpuLabel : ""
    readonly property real gpuPowerW: _session ? _session.gpuPowerW : NaN
    readonly property real gpuPowerMaxW: _session ? _session.gpuPowerMaxW : 28

    readonly property int diskPct: _session ? _session.diskPct : 0
    readonly property string diskUsed: _session ? _session.diskUsed : ""
    readonly property string diskTotal: _session ? _session.diskTotal : ""

    readonly property real temperatureC: _session ? _session.temperatureC : NaN

    readonly property real downloadBps: _session ? _session.downloadBps : 0
    readonly property real uploadBps: _session ? _session.uploadBps : 0
    readonly property var netHistoryDown: _session ? _session.netHistoryDown : []
    readonly property var netHistoryUp: _session ? _session.netHistoryUp : []

    readonly property bool batteryAvailable: _session ? _session.batteryAvailable : false
    readonly property real batteryPct: _session ? _session.batteryPct : 1
    readonly property bool batteryCharging: _session ? _session.batteryCharging : false

    readonly property var _session: sessionLoader.item
    readonly property int _sessionRev: sessionLoader.status

    function formatPowerW(w) {
        if (!isFinite(w) || w < 0)
            return "— W"
        if (w < 10)
            return w.toFixed(1) + " W"
        return Math.round(w) + " W"
    }

    function formatRate(bps) {
        if (!isFinite(bps) || bps < 1)
            return "0 B/s"
        if (bps < 1024)
            return Math.round(bps) + " B/s"
        if (bps < 1024 * 1024)
            return (bps / 1024).toFixed(1) + " KB/s"
        return (bps / (1024 * 1024)).toFixed(2) + " MB/s"
    }

        function formatMemShort() {
            const u = memUsedKb / (1024 * 1024)
            const t = memTotalKb / (1024 * 1024)
            return u.toFixed(1) + " / " + t.toFixed(0) + " GB"
        }

        /** Waybar Modules temperature format-icons: 󰈸; cool = snowflake Nerd. */
        function temperatureIcon(c) {
            if (!isFinite(c))
                return "\u{F0238}"
            return c < 48 ? "\u{F0F2A}" : "\u{F0238}"
        }

        /** Blue (cool) → yellow → orange → red (hot), ~28–100 °C. */
        function temperatureColor(c) {
            if (!isFinite(c))
                return Qt.rgba(WallustColors.moduleText.r, WallustColors.moduleText.g,
                    WallustColors.moduleText.b, 0.45)
            const t = Math.max(0, Math.min(1, (c - 28) / 72))
            const stops = [
                { p: 0, r: 0.32, g: 0.58, b: 0.95 },
                { p: 0.38, r: 0.92, g: 0.86, b: 0.18 },
                { p: 0.68, r: 0.98, g: 0.52, b: 0.10 },
                { p: 1, r: 0.93, g: 0.22, b: 0.20 }
            ]
            let i = 0
            while (i < stops.length - 2 && t > stops[i + 1].p)
                i++
            const a = stops[i]
            const b = stops[i + 1]
            const span = b.p - a.p
            const u = span > 0 ? (t - a.p) / span : 0
            return Qt.rgba(a.r + (b.r - a.r) * u, a.g + (b.g - a.g) * u, a.b + (b.b - a.b) * u, 0.92)
        }

    onPanelOpenChanged: syncSessionOpen()

    function syncSessionOpen() {
        if (sessionLoader.item)
            sessionLoader.item.panelOpen = root.panelOpen
    }

    Loader {
        id: sessionLoader
        active: root.panelOpen
        asynchronous: false
        source: "../surfaces/SystemOverviewSession.qml"
        onLoaded: root.syncSessionOpen()
        onActiveChanged: {
            if (!active && item)
                item.panelOpen = false
        }
    }
}