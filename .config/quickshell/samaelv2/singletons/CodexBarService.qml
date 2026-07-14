pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * CodexBar usage for bar chip + UsageSurface.
 * Fetches `codexbar usage --format json` only on demand (UsageSurface open / refresh).
 * No background timer — bar chip is static.
 */
Singleton {
    id: root

    /** [{ id, label, ok, usedPercent, remainingPercent, resetsAt, resetLabel, plan, email, error, source }] */
    property var providers: []
    property int selectedIndex: 0
    property bool loading: false
    property string lastError: ""
    property int revision: 0
    property string lastFetchedAt: ""

    readonly property int count: providers.length
    readonly property var selected: {
        const _r = revision
        if (selectedIndex < 0 || selectedIndex >= providers.length)
            return null
        return providers[selectedIndex]
    }



    function selectNext() {
        if (count <= 0)
            return
        selectedIndex = (selectedIndex + 1) % count
    }

    function selectPrev() {
        if (count <= 0)
            return
        selectedIndex = (selectedIndex - 1 + count) % count
    }

    function selectIndex(i) {
        if (count <= 0)
            return
        selectedIndex = Math.max(0, Math.min(count - 1, i))
    }

    function refresh() {
        if (fetchProc.running)
            return
        loading = true
        lastError = ""
        fetchProc.running = true
    }

    function formatReset(iso) {
        if (!iso || !String(iso).length)
            return ""
        const t = Date.parse(iso)
        if (isNaN(t))
            return String(iso)
        const ms = t - Date.now()
        if (ms <= 0)
            return "resets soon"
        const mins = Math.floor(ms / 60000)
        const days = Math.floor(mins / (60 * 24))
        const hours = Math.floor((mins % (60 * 24)) / 60)
        const m = mins % 60
        if (days > 0)
            return "resets in " + days + "d " + hours + "h"
        if (hours > 0)
            return "resets in " + hours + "h " + m + "m"
        return "resets in " + m + "m"
    }

    function windowLabel(primary) {
        if (!primary || !primary.resetsAt)
            return "Credits"
        const t = Date.parse(primary.resetsAt)
        if (isNaN(t))
            return "Credits"
        const days = (t - Date.now()) / (86400000)
        if (days > 20 && days < 40)
            return "Monthly"
        if (days > 4 && days < 10)
            return "Weekly"
        if (primary.windowMinutes === 300)
            return "5h"
        return "Credits"
    }

    function prettyName(id) {
        const map = {
            grok: "Grok",
            codex: "Codex",
            claude: "Claude",
            cursor: "Cursor",
            gemini: "Gemini",
            copilot: "Copilot",
            opencode: "OpenCode",
            opencodego: "OpenCode Go",
            openai: "OpenAI",
            minimax: "MiniMax",
            kimi: "Kimi",
            kilo: "Kilo",
            kiro: "Kiro",
            openrouter: "OpenRouter"
        }
        return map[id] || (id ? (id.charAt(0).toUpperCase() + id.slice(1)) : "?")
    }

    function parsePayload(text) {
        let arr
        try {
            arr = JSON.parse(text)
        } catch (e) {
            lastError = "Bad JSON from codexbar"
            providers = []
            revision++
            return
        }
        if (!Array.isArray(arr)) {
            lastError = "Unexpected codexbar shape"
            providers = []
            revision++
            return
        }

        const out = []
        for (let i = 0; i < arr.length; i++) {
            const row = arr[i]
            if (!row)
                continue
            const id = String(row.provider || "")
            const usage = row.usage
            const err = row.error
            if (usage && usage.primary) {
                const used = Number(usage.primary.usedPercent)
                const usedSafe = isFinite(used) ? Math.max(0, Math.min(100, used)) : 0
                const remaining = 100 - usedSafe
                const email = usage.accountEmail
                    || (usage.identity && usage.identity.accountEmail)
                    || ""
                const plan = usage.loginMethod
                    || (usage.identity && usage.identity.loginMethod)
                    || ""
                out.push({
                    id: id,
                    label: prettyName(id),
                    ok: true,
                    usedPercent: usedSafe,
                    remainingPercent: remaining,
                    resetsAt: usage.primary.resetsAt || "",
                    resetLabel: formatReset(usage.primary.resetsAt),
                    windowLabel: windowLabel(usage.primary),
                    plan: plan,
                    email: email,
                    error: "",
                    source: String(row.source || ""),
                    secondary: usage.secondary || null,
                    tertiary: usage.tertiary || null
                })
            } else {
                const msg = (err && err.message) ? String(err.message) : "No usage"
                out.push({
                    id: id,
                    label: prettyName(id),
                    ok: false,
                    usedPercent: 0,
                    remainingPercent: 0,
                    resetsAt: "",
                    resetLabel: "",
                    windowLabel: "",
                    plan: "",
                    email: "",
                    error: msg,
                    source: String(row.source || "auto"),
                    secondary: null,
                    tertiary: null
                })
            }
        }

        providers = out
        if (selectedIndex >= out.length)
            selectedIndex = Math.max(0, out.length - 1)
        // Prefer first OK provider if current selection is an error row
        if (out.length && (!out[selectedIndex] || !out[selectedIndex].ok)) {
            for (let j = 0; j < out.length; j++) {
                if (out[j].ok) {
                    selectedIndex = j
                    break
                }
            }
        }
        lastFetchedAt = new Date().toISOString()
        lastError = ""
        revision++
    }

    Process {
        id: fetchProc
        command: ["codexbar", "usage", "--format", "json"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false
                const text = this.text.trim()
                if (!text.length) {
                    root.lastError = "Empty codexbar output"
                    root.revision++
                    return
                }
                root.parsePayload(text)
            }
        }
        stderr: StdioCollector {}
        onExited: code => {
            root.loading = false
            if (code !== 0 && root.providers.length === 0 && !root.lastError.length)
                root.lastError = "codexbar exit " + code
        }
    }

}
