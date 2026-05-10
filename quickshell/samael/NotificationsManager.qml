import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Notifications Manager - reads from swaync or similar
 */
Singleton {
    id: notifManager

    property list<NotificationItem> notifications: []
    property int unreadCount: 0

    Timer {
        id: pollTimer
        running: true
        interval: 2000
        repeat: true
        onTriggered: refresh()
    }

    function refresh() {
        // Try to read from swaync-client
        refreshProcess.running = true
    }

    Process {
        id: refreshProcess
        running: false
        command: ["bash", "-c", "swaync-client -l 2>/dev/null | head -10 || echo 'NO_NOTIFS'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text.trim()
                if (text === 'NO_NOTIFS' || !text) {
                    // Try mako
                    makoProcess.running = true
                    return
                }
                parseSwaync(text)
            }
        }
    }

    Process {
        id: makoProcess
        running: false
        command: ["bash", "-c", "makoctl list 2>/dev/null | head -10 || echo 'NO_NOTIFS'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text.trim()
                if (text === 'NO_NOTIFS') {
                    notifications = []
                    unreadCount = 0
                    return
                }
                // Parse mako format
                parseGeneric(text)
            }
        }
    }

    function parseSwaync(output) {
        // swaync-client output format varies, try to parse
        const lines = output.split('\n').filter(l => l && l.trim())
        const newNotifs = []
        for (let i = 0; i < Math.min(lines.length, 10); i++) {
            newNotifs.push({
                id: i,
                app: "App",
                summary: lines[i].substring(0, 50),
                body: "",
                time: new Date().toLocaleTimeString()
            })
        }
        notifications = newNotifs
        unreadCount = newNotifs.length
    }

    function parseGeneric(output) {
        const lines = output.split('\n').filter(l => l && l.trim())
        const newNotifs = []
        for (let i = 0; i < Math.min(lines.length, 10); i++) {
            newNotifs.push({
                id: i,
                app: "Notification",
                summary: lines[i].substring(0, 50),
                body: "",
                time: new Date().toLocaleTimeString()
            })
        }
        notifications = newNotifs
        unreadCount = newNotifs.length
    }

    function dismiss(index) {
        const newNotifs = notifications.slice()
        newNotifs.splice(index, 1)
        notifications = newNotifs
        unreadCount = newNotifs.length
    }

    function dismissAll() {
        notifications = []
        unreadCount = 0
        // Try to dismiss in swaync
        Process.execute("bash", ["swaync-client -d 2>/dev/null"])
    }
}

component NotificationItem {
    property int id
    property string app
    property string summary
    property string body
    property string time
}
