pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Startup + save path: FileView can lag; disk read keeps bar.enabled in sync.

Item {
    id: root

    /** true = lock IPC/shortcut open UI overlay only (no WlSessionLock). Set false for real lock. */
    /** false = real WlSessionLock; true = overlay preview only (Esc closes, no PAM). */
    readonly property bool lockPreviewUi: _cfg.lock?.previewUi === true
    readonly property bool barEnabled: _cfg.bar?.enabled !== false
    readonly property int barMarginTop: _cfg.bar?.marginTop ?? 8
    readonly property int barMarginLeft: _cfg.bar?.marginLeft ?? 12
    readonly property int barMarginRight: _cfg.bar?.marginRight ?? 12
    readonly property var barLeft: _list(_cfg.bar?.left, ["workspaces"])
    readonly property var barMiddle: _list(_cfg.bar?.middle, ["ai", "separator", "clock"])
    readonly property var barRight: _list(_cfg.bar?.right, ["notifications", "separator", "cava", "media"])
    readonly property int cornerRadius: _cfg.style?.cornerRadius ?? 14
    readonly property int sectionBottomMargin: _cfg.style?.sectionBottomMargin ?? 3
    readonly property int sectionPadH: _cfg.style?.sectionPadH ?? 10
    readonly property int sectionPadTop: _cfg.style?.sectionPadTop ?? 6
    readonly property int sectionPadBottom: _cfg.style?.sectionPadBottom ?? 4
    readonly property int sectionPadHCompact: _cfg.style?.sectionPadHCompact ?? 8
    readonly property int sectionPadTopCompact: _cfg.style?.sectionPadTopCompact ?? 4
    readonly property int sectionPadBottomCompact: _cfg.style?.sectionPadBottomCompact ?? 4
    /** Inset between zone border and widgets (px). */
    readonly property int innerMarginLeftAll: _cfg.style?.innerMarginLeftAll ?? 10
    readonly property int innerMarginMiddleSides: _cfg.style?.innerMarginMiddleSides ?? 11
    readonly property int innerMarginRightBeforeContent: _cfg.style?.innerMarginRightBeforeContent ?? 8
    readonly property int mediaBarTitleMaxWidth: _cfg.style?.mediaBarTitleMaxWidth ?? 120
    readonly property int middleRestHeight: _cfg.middle?.restHeight ?? 30
    readonly property var middleSurfaces: _cfg.middle?.surfaces ?? ({})
    readonly property var leftSurfaces: _cfg.left?.surfaces ?? ({})
    readonly property var rightSurfaces: _cfg.right?.surfaces ?? ({})
        readonly property string wallpaperDir: _cfg.wallpaper?.dir ?? ((Quickshell.env("HOME") || "") + "/Pictures/wallpapers")
        /** Empty = Caelestia default (~/Music/Lyrics). Set in config.json lyrics.dir */
        readonly property string lyricsDir: _cfg.lyrics?.dir ?? ""
        readonly property string lyricsBackend: _cfg.lyrics?.backend ?? "Auto"
        readonly property int lyricsPanelWidth: _cfg.lyrics?.panelWidth ?? 220
        readonly property real lyricsTimeOffsetSec: _cfg.lyrics?.timeOffsetSec ?? 0
        readonly property var launcherPinned: _list(_cfg.launcher?.pinned, [])
        readonly property string lyricsDirExpanded: {
            const d = lyricsDir.trim()
            if (!d.length)
                return ""
            const home = Quickshell.env("HOME") || ""
            if (d === "~")
                return home
            if (d.startsWith("~/"))
                return home + d.slice(1)
            return d
        }

        function hasWidget(zone, id) {
        const z = zone === "left" ? barLeft : zone === "middle" ? barMiddle : barRight
        return z.indexOf(id) >= 0
    }

    function hasWidgetAnywhere(id) {
        return hasWidget("left", id) || hasWidget("middle", id) || hasWidget("right", id)
    }

    function surfaceSize(name) {
        const s = middleSurfaces[name]
        if (!s) {
            if (name === "launcher")
                return Qt.size(540, 400)
            if (name === "calendar")
                return Qt.size(500, 320)
            if (name === "settings")
                return Qt.size(720, 440)
            return Qt.size(320, root.middleRestHeight)
        }
        return Qt.size(s.width ?? 320, s.height ?? 200)
    }

        function leftSurfaceSize(name) {
            const s = leftSurfaces[name]
            if (!s)
                return Qt.size(360, 280)
            return Qt.size(s.width ?? 360, s.height ?? 280)
        }

    function rightSurfaceSize(name) {
        const s = rightSurfaces[name]
        if (!s)
            return Qt.size(392, 230)
        return Qt.size(s.width ?? 392, s.height ?? 230)
    }

    property var _cfg: defaultConfig()

    function defaultConfig() {
        return {
            lock: { previewUi: false },
            bar: {
                enabled: true,
                marginTop: 8,
                marginLeft: 12,
                marginRight: 12,
                left: ["workspaces"],
                middle: ["ai", "separator", "clock"],
                right: ["notifications", "separator", "cava", "media"]
            },
            left: { surfaces: { notifications: { width: 360, height: 280 } } },
            right: { surfaces: { power: { width: 72, height: 232 } } },
                middle: {
                    restHeight: 30,
                    surfaces: {
                        media: { width: 520, height: 200 },
                        wallpaper: { width: 920, height: 132 },
                        wifi: { width: 360, height: 340 },
                        notifications: { width: 360, height: 340 },
                        launcher: { width: 540, height: 400 },
                        calendar: { width: 500, height: 300 }
                    }
                },

            style: { cornerRadius: 14, sectionBottomMargin: 3 }
        }
    }

    function _list(v, fallback) {
        if (Array.isArray(v))
            return v
        return fallback
    }

    /** Deep clone of merged config for settings editor draft. */
    function cloneConfig() {
        try {
            return JSON.parse(JSON.stringify(_cfg))
        } catch (e) {
            return defaultConfig()
        }
    }

    FileView {
        id: configFile
        path: Quickshell.shellPath("config.json")
        watchChanges: true
        onLoaded: {
            try {
                root._cfg = Object.assign(defaultConfig(), JSON.parse(text))
            } catch (e) {
                root._cfg = defaultConfig()
            }
        }
        onFileChanged: reload()
    }

    function reloadFromDisk() {
        configFile.reload()
    }

    /** Apply saved/parsed config immediately (FileView reload alone can lag). */
    function applyConfigObject(obj) {
        if (!obj || typeof obj !== "object")
            return
        try {
            root._cfg = Object.assign(defaultConfig(), JSON.parse(JSON.stringify(obj)))
        } catch (e) {
            console.warn("ShellConfig.applyConfigObject failed", e)
        }
    }

    Process {
        id: bootReadProc
        stdout: StdioCollector { id: bootReadOut }
        onExited: (exitCode) => {
            if (exitCode !== 0 || !(bootReadOut.text || "").trim().length)
                return
            try {
                root.applyConfigObject(JSON.parse(bootReadOut.text))
            } catch (e) { }
        }
    }

    Component.onCompleted: {
        configFile.reload()
        const py = Quickshell.shellPath("scripts/config-read.py")
        const path = Quickshell.shellPath("config.json")
        bootReadProc.command = ["python3", py, path]
        bootReadProc.running = true
    }
}