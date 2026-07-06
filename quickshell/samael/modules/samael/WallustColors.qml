pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string _css: ""
    property int paletteGeneration: 0

    /** Lock/bar copy — prefer wallust `foreground`; avoid dark `text` from merged latte CSS on dark surfaces. */
    readonly property color foreground: { const _b = paletteGeneration; return _color("foreground", "#C6DCF5") }
    readonly property color text: foreground
    readonly property color moduleText: foreground

    readonly property color borderColor: { const _b = paletteGeneration; return _color("color12", "#466494") }
    readonly property color buttonColor: { const _b = paletteGeneration; return _color("color11", "#375E8A") }
    readonly property color buttonHover: { const _b = paletteGeneration; return _color("color13", "#548CCC") }

    readonly property color sapphire: { const _b = paletteGeneration; return _color("sapphire", "#209fb5") }
    readonly property color mauve: { const _b = paletteGeneration; return _color("mauve", "#8839ef") }
    readonly property color sky: { const _b = paletteGeneration; return _color("sky", "#04a5e5") }
    readonly property color teal: { const _b = paletteGeneration; return _color("teal", "#179299") }
    readonly property color yellow: { const _b = paletteGeneration; return _color("yellow", "#df8e1d") }
    readonly property color red: { const _b = paletteGeneration; return _color("red", "#d20f39") }

    readonly property color workspaceInactive: "#6E6A86"
    readonly property color workspaceActive: "#ffd700"
    readonly property color workspaceUrgent: "#ff0000"

    readonly property color moduleBackground: {
        const _b = paletteGeneration
        return _rgbaFromCss("background-alt", 29, 30, 34, 0.55)
    }

    readonly property color clockText: sapphire

    readonly property color notificationIcon: Qt.color("#ffd700")
    readonly property color notificationBadge: red

    readonly property color idleInactive: teal
    readonly property color idleActive: Qt.color("#39FF14")

    readonly property color temperatureCritical: red

    function _resolve(name, depth) {
        if (depth > 8 || !_css.length)
            return ""
        const re = new RegExp("@define-color\\s+" + name + "\\s+([^;\\n]+);", "m")
        const m = _css.match(re)
        if (!m)
            return ""
        let v = m[1].trim()
        if (v.startsWith("@"))
            return _resolve(v.slice(1), depth + 1)
        return v
    }

    function _color(name, fallback) {
        const v = _resolve(name, 0)
        if (!v.length)
            return fallback
        if (v.charAt(0) === "#")
            return Qt.color(v)
        const rgba = _parseRgba(v)
        if (rgba)
            return Qt.rgba(rgba[0], rgba[1], rgba[2], rgba[3])
        return fallback
    }

    function _parseRgba(s) {
        const m = s.match(/rgba?\s*\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*(?:,\s*([\d.]+)\s*)?\)/i)
        if (!m)
            return null
        let r = parseFloat(m[1]), g = parseFloat(m[2]), b = parseFloat(m[3])
        let a = m[4] !== undefined ? parseFloat(m[4]) : 1
        if (r > 1) r /= 255
        if (g > 1) g /= 255
        if (b > 1) b /= 255
        return [r, g, b, a]
    }

    function _rgbaFromCss(name, dr, dg, db, da) {
        const v = _resolve(name, 0)
        const parsed = v.length ? _parseRgba(v) : null
        if (parsed) {
            const a = Math.max(parsed[3], da)
            return Qt.rgba(parsed[0], parsed[1], parsed[2], a)
        }
        return Qt.rgba(dr / 255, dg / 255, db / 255, da)
    }

    function reloadPaletteFromDisk() {
        wallustReadProc.readNow()
    }

    Process {
        id: wallustReadProc
        function readNow() {
            exec(["bash", "-c",
                "cat '/home/samael/.config/waybar/wallust/colors-waybar.css' 2>/dev/null"])
        }
        stdout: StdioCollector {
            onStreamFinished: {
                root._css = text
                root.paletteGeneration++
            }
        }
    }

    FileView {
        id: wallustFile
        path: "/home/samael/.config/waybar/wallust/colors-waybar.css"
        watchChanges: true
        onFileChanged: root.reloadPaletteFromDisk()
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: wallustMtimeProc.check()
    }

    Process {
        id: wallustMtimeProc
        property int lastMtime: 0
        function check() {
            exec(["stat", "-c", "%Y", "/home/samael/.config/waybar/wallust/colors-waybar.css"])
        }
        stdout: StdioCollector {
            onStreamFinished: {
                const m = parseInt(text.trim(), 10)
                if (!isNaN(m) && wallustMtimeProc.lastMtime > 0 && m > wallustMtimeProc.lastMtime)
                    root.reloadPaletteFromDisk()
                if (!isNaN(m))
                    wallustMtimeProc.lastMtime = m
            }
        }
        Component.onCompleted: check()
    }

    Component.onCompleted: reloadPaletteFromDisk()
}