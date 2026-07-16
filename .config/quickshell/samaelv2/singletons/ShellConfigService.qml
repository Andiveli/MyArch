pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Draft + save for config.json (settings surface). Live shell reads ShellConfig FileView.
 */
Singleton {
    id: root

    readonly property string configPath: Quickshell.shellPath("config.json")

    property var draft: ({})
    property bool dirty: false
    property bool saving: false
    property string saveError: ""
    property string statusMessage: ""
    property int revision: 0

    property var _saveDoneCallback: null

    readonly property var pages: [
        { id: "general", label: "General", icon: "\uf013", description: "Lock preview, bar on/off" },
        { id: "bar", label: "Bar", icon: "\uf0c9", description: "Widgets, margins" },
        { id: "surfaces", label: "Surfaces", icon: "\uf2d2", description: "Panel sizes" },
        { id: "lyrics", label: "Lyrics", icon: "\uf001", description: "Dir, backend, offset" },
        { id: "wallpaper", label: "Wallpaper", icon: "\uf03e", description: "Image folder" },
        { id: "videos", label: "Videos", icon: "\uf03d", description: "Screen record save folder" },
        { id: "audio", label: "Audio", icon: "\uf028", description: "Session mixer" },
        { id: "keybinds", label: "Keybinds", icon: "\uf11c", description: "Shortcuts reference (read-only)" }
    ]

    readonly property var barWidgetIds: [
        "workspaces", "launcher", "ai", "notifications", "separator", "clock",
        "cava", "media", "wifi", "bluetooth", "overview", "power"
    ]

    property var _afterDraftSync: null

    function reloadFromShell() {
        draft = ShellConfig.cloneConfig()
        dirty = false
        saveError = ""
        statusMessage = ""
        revision++
    }

    /** Read config.json from disk into draft (use when opening settings). */
    function refreshDraftFromDisk(done) {
        _afterDraftSync = typeof done === "function" ? done : null
        const py = Quickshell.shellPath("scripts/config-read.py")
        readDraftProc.command = ["python3", py, configPath]
        readDraftProc.running = true
    }

    Process {
        id: readDraftProc
        stdout: StdioCollector { id: draftReadOut }
        onExited: (exitCode) => {
            if (exitCode === 0 && (draftReadOut.text || "").trim().length) {
                try {
                    const parsed = JSON.parse(draftReadOut.text)
                    const merged = Object.assign(ShellConfig.defaultConfig(), parsed)
                    root.draft = merged
                    ShellConfig.applyConfigObject(merged)
                    root.dirty = false
                    root.saveError = ""
                    root.statusMessage = ""
                    root.revision++
                } catch (e) {
                    root.reloadFromShell()
                }
            } else {
                root.reloadFromShell()
            }
            if (root._afterDraftSync) {
                root._afterDraftSync()
                root._afterDraftSync = null
            }
        }
    }

    function markDirty() {
        dirty = true
        revision++
    }

    function setDraftPath(keys, value) {
        const d = JSON.parse(JSON.stringify(draft))
        let o = d
        for (let i = 0; i < keys.length - 1; i++) {
            const k = keys[i]
            if (typeof o[k] !== "object" || o[k] === null || Array.isArray(o[k]))
                o[k] = {}
            o = o[k]
        }
        o[keys[keys.length - 1]] = value
        draft = d
        markDirty()
    }

    function getDraftPath(keys, fallback) {
        let o = draft
        for (let i = 0; i < keys.length; i++) {
            if (!o || typeof o !== "object")
                return fallback
            o = o[keys[i]]
        }
        return o === undefined ? fallback : o
    }

    function barZoneList(zone) {
        const key = zone === "left" ? ["bar", "left"] : zone === "middle" ? ["bar", "middle"] : ["bar", "right"]
        const v = getDraftPath(key, null)
        if (Array.isArray(v))
            return v.slice()
        return ShellConfig._list(v, zone === "left" ? ["workspaces"] : zone === "middle"
            ? ["ai", "separator", "clock"] : ["notifications", "separator", "cava", "media"])
    }

    function setBarZoneList(zone, list) {
        const key = zone === "left" ? ["bar", "left"] : zone === "middle" ? ["bar", "middle"] : ["bar", "right"]
        setDraftPath(key, list)
    }

    function toggleBarWidget(zone, widgetId) {
        const list = barZoneList(zone)
        const i = list.indexOf(widgetId)
        if (i >= 0)
            list.splice(i, 1)
        else
            list.push(widgetId)
        setBarZoneList(zone, list)
    }

    function hasBarWidget(zone, widgetId) {
        return barZoneList(zone).indexOf(widgetId) >= 0
    }

    function save(done) {
        if (saving)
            return
        saveError = ""
        statusMessage = "Saving…"
        saving = true
        _saveDoneCallback = typeof done === "function" ? done : null
        const payload = JSON.stringify(draft)
        const py = Quickshell.shellPath("scripts/config-save.py")
        saveProc.command = ["python3", py, "--json", payload, configPath]
        saveProc.running = true
    }

    Process {
        id: saveProc
        stdout: StdioCollector { id: saveOut }
        onExited: (exitCode) => {
            root.saving = false
            let ok = false
            let err = ""
            try {
                const parsed = JSON.parse(saveOut.text || "{}")
                ok = parsed.ok === true
                err = parsed.error || ""
            } catch (e) {
                err = "Save failed"
            }
            if (exitCode !== 0 || !ok) {
                root.saveError = err || "Save failed"
                root.statusMessage = ""
                if (root._saveDoneCallback)
                    root._saveDoneCallback(false)
                root._saveDoneCallback = null
                return
            }
            root.dirty = false
            root.saveError = ""
            root.statusMessage = "Saved to config.json"
            root.revision++
            ShellConfig.applyConfigObject(root.draft)
            ShellConfig.reloadFromDisk()
            if (root._saveDoneCallback)
                root._saveDoneCallback(true)
            root._saveDoneCallback = null
        }
    }
}