pragma Singleton
import QtQuick

QtObject {
    function trim(s) {
        return (s ?? "").toString().replace(/^\s+|\s+$/g, "")
    }

    function hideAppName(notif) {
        const app = trim(notif?.appName).toLowerCase()
        return app === "notify-send" || app === "notify_send"
    }

    function hintValue(notif) {
        const n = notif?.notification
        if (!n?.hints)
            return null
        const h = n.hints
        if (h.value !== undefined && h.value !== null)
            return h.value
        return null
    }

    function isVolumeStyle(summary) {
        const s = trim(summary).toLowerCase()
        return s.includes("volume") || s.includes("mic level") || s === "mute"
            || s.includes("microphone")
    }

    function title(notif) {
        if (!notif)
            return ""
        let summary = trim(notif.summary)
        if (!summary.length)
            return hideAppName(notif) ? "" : (trim(notif.appName) || "")
        if (summary.endsWith(":"))
            summary = trim(summary.slice(0, -1))
        return summary
    }

    function content(notif) {
        if (!notif)
            return ""
        let body = trim(notif.body)
        const summary = trim(notif.summary)
        const hint = hintValue(notif)
        if (hint !== null && !isNaN(Number(hint)) && isVolumeStyle(summary)) {
            const pct = Number(hint)
            return pct === 0 ? "Muted" : (Math.round(pct) + "%")
        }
        if (body.length && body.includes("%"))
            return body.replace(/\s+/g, " ").trim()
        return body
    }

    function line(notif) {
        const t = title(notif)
        const c = content(notif)
        if (t.length && c.length)
            return t + ": " + c
        if (t.length)
            return t
        if (c.length)
            return c
        if (!hideAppName(notif))
            return trim(notif.appName) || "?"
        return "?"
    }
}