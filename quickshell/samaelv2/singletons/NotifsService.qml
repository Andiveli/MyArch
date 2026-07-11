pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property var popups: []
    property var seenIds: ({})
    property var arrivalMs: ({})
    property var expireAt: ({})
    property var hookedIds: ({})
        property bool dnd: false
        property int listRevision: 0

        readonly property var tracked: server.trackedNotifications.values

        function bumpList() {
            root.listRevision++
        }

    function iconFor(n) {
        if (!n)
            return ""
        const img = n.image || ""
        const names = []
        if (img.indexOf("image://icon/") === 0)
            names.push(img.substring(13))
        else if (img.length && !/\.svg$/i.test(img))
            return img
        names.push(n.appIcon, n.desktopEntry, (n.appName || n.app || "").toLowerCase())
        for (let i = 0; i < names.length; i++) {
            const nm = names[i]
            if (!nm || !nm.length)
                continue
            if (nm.indexOf("/") === 0 || nm.indexOf("file://") === 0)
                return nm
            const p = Quickshell.iconPath(nm, true)
            if (p.length)
                return p
        }
        return ""
    }

    function removePopup(n) {
        root.popups = root.popups.filter(p => p !== n)
    }

    /** Hypr Volume.sh / swaync duplicates — OSD owns volume/brightness feedback. */
    function isHardwareFeedback(n) {
        if (!n)
        return false
        const app = String(n.appName || n.app || "").toLowerCase()
        const sum = String(n.summary || "").toLowerCase()
        const body = String(n.body || "").toLowerCase()
        const blob = app + " " + sum + " " + body
        if (blob.indexOf("volume level") >= 0 || blob.indexOf("volume:") >= 0)
        return true
        if (blob.indexOf("brightness") >= 0 && (blob.indexOf("%") >= 0 || body.match(/\d/)))
        return true
        if (app === "swaync" || app.indexOf("volume") >= 0)
        return sum.indexOf("volume") >= 0
        return false
    }

    function raiseWindow(n) {
        if (!n)
            return
        const token = String(n.desktopEntry?.length ? n.desktopEntry : (n.appName || "")).toLowerCase()
        if (!token.length)
            return
        Quickshell.execDetached(["sh", "-c",
            "addr=$(hyprctl clients -j | jq -r --arg q \"$1\" 'first(.[] | select(((.class | if . then ascii_downcase else \"\" end) | contains($q)) or ((.initialClass | if . then ascii_downcase else \"\" end) | contains($q))) | .address)'); [ -n \"$addr\" ] && hyprctl dispatch \"hl.dsp.focus({ window = \\\"address:$addr\\\" })\"",
            "sh", token])
    }

    function activateNotif(n) {
        if (!n)
            return
        const acts = n.actions || []
        for (let i = 0; i < acts.length; i++) {
            if (acts[i].identifier === "default") {
                acts[i].invoke()
                break
            }
        }
        raiseWindow(n)
    }

        function trimText(s) {
            return String(s ?? "").replace(/^\s+|\s+$/g, "")
        }

        function normalizeTitle(s) {
            let t = trimText(s)
            if (t.endsWith(":"))
                t = trimText(t.slice(0, -1))
            return t.toLowerCase()
        }

        /** "Hyprsunset: Enabled" / "Hyprsunset: Disabled" → one service key hyprsunset. */
        function serviceBaseKey(summary) {
            let raw = trimText(summary)
            if (!raw.length)
                return ""
            if (raw.indexOf(":") >= 0)
                raw = trimText(raw.split(":")[0])
            else if (raw.endsWith(":"))
                raw = trimText(raw.slice(0, -1))
            return raw.toLowerCase()
        }

        function serviceDisplayFromBase(base) {
            if (!base.length)
                return "Notification"
            return base.charAt(0).toUpperCase() + base.slice(1)
        }

        /** notify-send / scripts often share one app_name — group by summary (service/topic). */
        function isGenericNotifier(n) {
            const app = trimText(n.appName || n.app).toLowerCase()
            if (!app.length)
                return true
            return app === "notify-send" || app === "notify_send" || app === "notification"
        }

        function serviceKeyFor(n) {
            if (!n)
                return ""
            if (isGenericNotifier(n)) {
                let base = serviceBaseKey(n.summary)
                if (!base.length)
                    base = serviceBaseKey(n.body)
                if (!base.length)
                    base = normalizeTitle(n.summary) || normalizeTitle(n.body).slice(0, 80)
                if (!base.length)
                    return "svc:unknown"
                return "svc:" + base
            }
            const de = trimText(n.desktopEntry)
            if (de.length)
                return "app:" + de.toLowerCase()
            const app = trimText(n.appName || n.app)
            return app.length ? "app:" + app.toLowerCase() : "app:unknown"
        }

        function serviceLabelFor(n, key) {
            if (!n)
                return "?"
            if (key.indexOf("svc:") === 0)
                return serviceDisplayFromBase(key.slice(4))
            return trimText(n.appName || n.app || n.desktopEntry || "App")
        }

    function sortedTracked() {
        const l = root.tracked || []
        return l.slice().sort((a, b) => (root.arrivalMs[b.id] || 0) - (root.arrivalMs[a.id] || 0))
    }

    /** Newest-first groups by service (summary for generic notify-send, else app/desktop). */
    function groupsForTracked() {
        const list = sortedTracked()
        const map = {}
        const order = []
        for (let i = 0; i < list.length; i++) {
            const n = list[i]
            const key = serviceKeyFor(n)
            if (!map[key]) {
                map[key] = {
                    key,
                    label: serviceLabelFor(n, key),
                    appName: serviceLabelFor(n, key),
                    appIcon: n.appIcon || "",
                    notifications: [],
                    latestMs: 0
                }
                order.push(key)
            }
            const g = map[key]
            g.notifications.push(n)
            const t = root.arrivalMs[n.id] || 0
            if (t > g.latestMs)
                g.latestMs = t
            if (!g.appIcon && n.appIcon)
                g.appIcon = n.appIcon
        }
        order.sort((a, b) => map[b].latestMs - map[a].latestMs)
        return order.map(k => map[k])
    }

    function dismissNotif(n) {
        if (!n)
            return
        root.removePopup(n)
        if (typeof n.dismiss === "function")
            n.dismiss()
    }

    function dismissAllTracked() {
        const l = root.tracked || []
        for (let i = 0; i < l.length; i++)
            root.dismissNotif(l[i])
    }

    function hookClosed(n) {
        if (root.hookedIds[n.id])
            return
        const hooked = Object.assign({}, root.hookedIds)
        hooked[n.id] = true
        root.hookedIds = hooked
        n.closed.connect(() => {
            root.removePopup(n)
            const b = Object.assign({}, root.arrivalMs)
            delete b[n.id]
            root.arrivalMs = b
            const c = Object.assign({}, root.expireAt)
            delete c[n.id]
            root.expireAt = c
            const h = Object.assign({}, root.hookedIds)
            delete h[n.id]
            root.hookedIds = h
            root.bumpList()
        })
    }

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        actionsSupported: true
        imageSupported: true

        Component.onCompleted: {
            const l = trackedNotifications.values
            const a = Object.assign({}, root.arrivalMs)
            for (let i = 0; i < l.length; i++) {
                if (!a[l[i].id])
                    a[l[i].id] = Date.now()
                root.hookClosed(l[i])
            }
            root.arrivalMs = a
            root.bumpList()
        }

        onNotification: n => {
            if (root.isHardwareFeedback(n))
                return
            const a = Object.assign({}, root.arrivalMs)
            a[n.id] = Date.now()
            root.arrivalMs = a
            const e = Object.assign({}, root.expireAt)
            e[n.id] = Date.now() + (n.urgency === NotificationUrgency.Low ? 4000 : 6000)
            root.expireAt = e
            n.tracked = true
            root.hookClosed(n)
            const critical = n.urgency === NotificationUrgency.Critical
            if (!root.dnd || critical)
                root.popups = root.popups.concat([n]).slice(-3)
            root.bumpList()
        }
    }
}