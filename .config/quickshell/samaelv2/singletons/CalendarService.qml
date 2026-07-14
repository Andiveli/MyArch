pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Google Calendar: gitignored calendar-secrets.json and/or SAMAELV2_CALENDAR_ICAL_URLS.
 */
Singleton {
    id: root

    property var events: []
    property bool loading: false
    property string lastError: ""
    property int revision: 0
    property string lastFetchedAt: ""
    property bool configured: false
    property var fetchErrors: []

    property var savedIcalUrls: []
    property int secretsRevision: 0
    property string secretsSaveError: ""
    property var _saveDoneCallback: null

    readonly property string cachePath: (Quickshell.env("HOME") || "") + "/.cache/samaelv2/calendar/events.json"
    readonly property string configPath: Quickshell.shellPath("config.json")
    readonly property string secretsPath: Quickshell.shellPath("calendar-secrets.json")

    function hasEvents(dateKey) {
        const _r = revision
        if (!dateKey || !dateKey.length)
            return false
        for (let i = 0; i < events.length; i++) {
            const e = events[i]
            if (!e)
                continue
            const lo = e.date || ""
            const hi = (e.endDate && e.endDate.length) ? e.endDate : lo
            if (lo.length && dateKey >= lo && dateKey <= hi)
                return true
        }
        return false
    }

    function forDate(dateKey) {
        const _r = revision
        const out = []
        if (!dateKey || !dateKey.length)
            return out
        for (let i = 0; i < events.length; i++) {
            const e = events[i]
            if (!e)
                continue
            const lo = e.date || ""
            const hi = (e.endDate && e.endDate.length) ? e.endDate : lo
            if (lo.length && dateKey >= lo && dateKey <= hi)
                out.push(e)
        }
        out.sort((a, b) => {
            const ta = a.allDay ? "00:00" : (a.time || "00:00")
            const tb = b.allDay ? "00:00" : (b.time || "00:00")
            return ta < tb ? -1 : ta > tb ? 1 : 0
        })
        return out
    }

    function reloadSecrets() {
        secretsFile.reload()
        try {
            const t = secretsFile.text
            if (!t || !t.trim().length) {
                savedIcalUrls = []
                secretsRevision++
                return
            }
            const parsed = JSON.parse(t)
            const raw = parsed.icalUrls
            savedIcalUrls = Array.isArray(raw)
                ? raw.map(u => String(u).trim()).filter(u => u.length > 0)
                : []
            secretsRevision++
        } catch (e) {
            savedIcalUrls = []
            secretsRevision++
        }
    }

    function saveSecrets(urlList, done) {
        secretsSaveError = ""
        _saveDoneCallback = typeof done === "function" ? done : null
        const urls = Array.isArray(urlList) ? urlList : []
        const payload = JSON.stringify({ icalUrls: urls })
        const py = Quickshell.shellPath("scripts/calendar-secrets-save.py")
        saveProc.command = ["python3", py, "--json", payload, secretsPath]
        saveProc.running = true
    }

    function loadCache() {
        cacheFile.reload()
        try {
            const t = cacheFile.text
            if (!t || !t.trim().length) {
                events = []
                revision++
                return
            }
            const parsed = JSON.parse(t)
            events = Array.isArray(parsed.events) ? parsed.events : []
            lastFetchedAt = parsed.fetchedAt || ""
            configured = !!parsed.configured
            fetchErrors = Array.isArray(parsed.errors) ? parsed.errors : []
            lastError = fetchErrors.length ? String(fetchErrors[0]) : ""
            revision++
        } catch (e) {
            events = []
            lastError = "Bad calendar cache"
            revision++
        }
    }

    function refresh() {
        if (fetchProc.running)
            return
        loading = true
        lastError = ""
        fetchProc.running = true
    }

    function parseStdout(text) {
        loading = false
        const trimmed = (text || "").trim()
        if (!trimmed.length) {
            loadCache()
            return
        }
        try {
            const parsed = JSON.parse(trimmed)
            events = Array.isArray(parsed.events) ? parsed.events : []
            lastFetchedAt = parsed.fetchedAt || ""
            configured = !!parsed.configured
            fetchErrors = Array.isArray(parsed.errors) ? parsed.errors : []
            lastError = fetchErrors.length ? String(fetchErrors[0]) : ""
            revision++
        } catch (e) {
            loadCache()
        }
    }

    FileView {
        id: secretsFile
        path: root.secretsPath
        watchChanges: false
    }

    FileView {
        id: cacheFile
        path: root.cachePath
    }

    Process {
        id: saveProc
        stdout: StdioCollector {
            onStreamFinished: {
                let ok = false
                try {
                    const r = JSON.parse(this.text.trim())
                    ok = !!r.ok
                    if (!ok)
                        root.secretsSaveError = r.error || "Save failed"
                } catch (e) {
                    root.secretsSaveError = "Bad save response"
                }
                if (ok)
                    root.reloadSecrets()
                const cb = root._saveDoneCallback
                root._saveDoneCallback = null
                if (cb)
                    cb(ok)
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length)
                    root.secretsSaveError = this.text.trim().slice(-240)
            }
        }
        onExited: code => {
            if (code !== 0 && !root.secretsSaveError.length)
                root.secretsSaveError = "save exit " + code
            if (code !== 0 && root._saveDoneCallback) {
                const cb = root._saveDoneCallback
                root._saveDoneCallback = null
                cb(false)
            }
        }
    }

    Process {
        id: fetchProc
        command: ["python3", Quickshell.shellPath("scripts/calendar-fetch-ical.py"), root.configPath]
        stdout: StdioCollector {
            onStreamFinished: root.parseStdout(this.text)
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (!root.lastError.length && this.text.trim().length)
                    root.lastError = this.text.trim().slice(-200)
            }
        }
        onExited: code => {
            root.loading = false
            if (code !== 0 && !root.events.length && !root.lastError.length)
                root.lastError = "calendar fetch exit " + code
        }
    }

    Component.onCompleted: {
        reloadSecrets()
        loadCache()
    }
}