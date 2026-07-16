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
    property var costByProvider: ({})

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
        if (fetchProc.running || costProc.running)
            return
        loading = true
        lastError = ""
        fetchProc.running = true
        costProc.running = true
    }

    function syncLoading() {
        loading = fetchProc.running || costProc.running
    }

    function compactNumber(value) {
        const n = Number(value)
        if (!isFinite(n))
            return "—"
        if (n >= 1000000000)
            return (n / 1000000000).toFixed(n >= 10000000000 ? 0 : 1) + "B"
        if (n >= 1000000)
            return (n / 1000000).toFixed(n >= 10000000 ? 0 : 1) + "M"
        if (n >= 1000)
            return (n / 1000).toFixed(n >= 10000 ? 0 : 1) + "K"
        return String(Math.round(n))
    }

    function money(value, currency) {
        const n = Number(value)
        if (!isFinite(n))
            return "—"
        return (currency === "USD" || !currency ? "$" : currency + " ") + n.toFixed(2)
    }

    function parseCostPayload(text) {
        let arr
        try {
            arr = JSON.parse(text)
        } catch (e) {
            return
        }
        if (!Array.isArray(arr))
            arr = [arr]
        const costs = {}
        for (let i = 0; i < arr.length; i++) {
            const row = arr[i]
            if (!row || !row.provider)
                continue
            const daily = row.daily || []
            const today = daily.length ? daily[daily.length - 1] : null
            const models = today && today.modelBreakdowns ? today.modelBreakdowns : []
            let topModel = ""
            if (models.length) {
                let best = models[0]
                for (let j = 1; j < models.length; j++) {
                    if (Number(models[j].totalTokens || 0) > Number(best.totalTokens || 0))
                        best = models[j]
                }
                topModel = String(best.modelName || "")
            }
            costs[String(row.provider)] = {
                available: true,
                currency: String(row.currencyCode || "USD"),
                sessionCost: Number(row.sessionCostUSD || 0),
                sessionTokens: Number(row.sessionTokens || 0),
                last30DaysCost: Number(row.last30DaysCostUSD || 0),
                last30DaysTokens: Number(row.last30DaysTokens || 0),
                inputTokens: Number(row.totals && row.totals.inputTokens || 0),
                outputTokens: Number(row.totals && row.totals.outputTokens || 0),
                cacheReadTokens: Number(row.totals && row.totals.cacheReadTokens || 0),
                topModel: topModel,
                updatedAt: String(row.updatedAt || "")
            }
        }
        costByProvider = costs
        applyCosts()
    }

    function applyCosts() {
        if (!providers || !providers.length)
            return
        const next = []
        for (let i = 0; i < providers.length; i++) {
            const p = providers[i]
            const copy = Object.assign({}, p)
            copy.cost = costByProvider[p.id] || { available: false }
            next.push(copy)
        }
        providers = next
        revision++
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

    function meterTitle(m, slot) {
        if (!m)
            return slot
        const wm = Number(m.windowMinutes)
        if (wm === 10080)
            return "Weekly"
        if (wm === 43200)
            return "Monthly"
        if (wm === 300)
            return "Session"
        if (m.resetDescription && String(m.resetDescription).length)
            return slot === "primary" ? "Session" : (slot === "secondary" ? "Weekly" : "Usage")
        if (wm > 0 && wm < 120)
            return wm + " min window"
        if (slot === "primary")
            return "Primary"
        if (slot === "secondary")
            return "Secondary"
        if (slot === "tertiary")
            return "Tertiary"
        return "Usage"
    }

    function windowLabel(meter) {
        return meterTitle(meter, "Credits")
    }

    function buildWindows(usage) {
        const slots = [
            { key: "primary", m: usage && usage.primary },
            { key: "secondary", m: usage && usage.secondary },
            { key: "tertiary", m: usage && usage.tertiary }
        ]
        const out = []
        for (let i = 0; i < slots.length; i++) {
            const m = slots[i].m
            if (!m)
                continue
            const used = Number(m.usedPercent)
            const usedSafe = isFinite(used) ? Math.max(0, Math.min(100, used)) : 0
            const resetsAt = m.resetsAt ? String(m.resetsAt) : ""
            out.push({
                slot: slots[i].key,
                label: meterTitle(m, slots[i].key),
                usedPercent: usedSafe,
                remainingPercent: 100 - usedSafe,
                resetsAt: resetsAt,
                resetLabel: formatReset(resetsAt),
                resetDescription: m.resetDescription ? String(m.resetDescription) : "",
                windowMinutes: m.windowMinutes !== undefined ? m.windowMinutes : -1
            })
        }
        return out
    }

    function formatCredits(credits) {
        if (!credits)
            return { remaining: -1, events: [], summary: "" }
        const rem = Number(credits.remaining)
        const events = credits.events || []
        let summary = ""
        if (isFinite(rem) && rem >= 0)
            summary = "Credits remaining: " + rem
        if (events.length > 0)
            summary += (summary.length ? " · " : "") + events.length + " credit event(s)"
        return { remaining: isFinite(rem) ? rem : -1, events: events, summary: summary }
    }

    function formatCodexResetCredits(crc) {
        if (!crc)
            return ""
        const n = Number(crc.availableCount)
        if (isFinite(n) && n > 0)
            return "Reset credits available: " + n
        const list = crc.credits || []
        if (list.length)
            return "Reset credits: " + list.length + " pack(s)"
        return ""
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

        function pickMeter(usage) {
            if (!usage)
                return null
            const order = [usage.primary, usage.secondary, usage.tertiary]
            for (let k = 0; k < order.length; k++) {
                const m = order[k]
                if (!m)
                    continue
                if (m.usedPercent !== undefined && m.usedPercent !== null)
                    return m
                if (m.resetsAt)
                    return m
            }
            return usage.secondary || usage.primary || usage.tertiary || null
        }

        const out = []
        for (let i = 0; i < arr.length; i++) {
            const row = arr[i]
            if (!row)
                continue
            const id = String(row.provider || "")
            const usage = row.usage
            const err = row.error
            if (err && err.message) {
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
                    error: String(err.message),
                    source: String(row.source || "auto"),
                    secondary: null,
                    tertiary: null
                })
                continue
            }
            const meter = pickMeter(usage)
            const hasIdentity = usage && (usage.accountEmail
                || (usage.identity && usage.identity.accountEmail)
                || usage.loginMethod
                || (usage.identity && usage.identity.loginMethod))
            if (usage && (meter || hasIdentity)) {
                const windows = buildWindows(usage)
                const lead = windows.length ? windows[0] : null
                const usedSafe = lead ? lead.usedPercent : (meter ? Math.max(0, Math.min(100, Number(meter.usedPercent) || 0)) : 0)
                const email = usage.accountEmail
                    || (usage.identity && usage.identity.accountEmail)
                    || ""
                const plan = usage.loginMethod
                    || (usage.identity && usage.identity.loginMethod)
                    || ""
                const org = usage.accountOrganization
                    || (usage.identity && usage.identity.accountOrganization)
                    || ""
                const cred = formatCredits(row.credits)
                const crcLine = formatCodexResetCredits(usage.codexResetCredits)
                out.push({
                    id: id,
                    label: prettyName(id),
                    ok: true,
                    usedPercent: usedSafe,
                    remainingPercent: 100 - usedSafe,
                    resetsAt: lead ? lead.resetsAt : "",
                    resetLabel: lead ? lead.resetLabel : "",
                    resetDescription: lead ? lead.resetDescription : "",
                    windowLabel: lead ? lead.label : windowLabel(meter),
                    plan: plan,
                    email: email,
                    organization: org,
                    error: "",
                    source: String(row.source || ""),
                    version: String(row.version || ""),
                    updatedAt: String(usage.updatedAt || (row.credits && row.credits.updatedAt) || ""),
                    dataConfidence: usage.dataConfidence ? String(usage.dataConfidence) : "",
                    windows: windows,
                    cost: costByProvider[id] || { available: false },
                    creditsRemaining: cred.remaining,
                    creditsSummary: cred.summary,
                    codexResetCreditsLine: crcLine,
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
        applyCosts()
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
            root.syncLoading()
            if (code !== 0 && root.providers.length === 0 && !root.lastError.length)
                root.lastError = "codexbar exit " + code
        }
    }

    Process {
        id: costProc
        command: ["codexbar", "cost", "--format", "json"]
        stdout: StdioCollector { id: costOut }
        stderr: StdioCollector {}
        onExited: code => {
            if (code === 0 && costOut.text && costOut.text.trim().length)
                root.parseCostPayload(costOut.text.trim())
            root.syncLoading()
        }
    }

}
