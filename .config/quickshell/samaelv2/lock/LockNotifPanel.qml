pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import "../singletons"
import "./LockNotifGroupCard.qml"

/** Caelestia-style notif dock: full column height, grouped cards with icon + body */
Item {
    id: root

    readonly property real s: Math.max(0.85, Style.fontPixelSize / 11)
    readonly property int _rev: NotifsService.listRevision
    readonly property real iconBox: Math.round(48 * s)

    readonly property var groups: {
        const _r = _rev
        const tr = NotifsService.tracked || []
        const map = new Map()
        for (let i = tr.length - 1; i >= 0; i--) {
            const n = tr[i]
            if (!n)
                continue
            const key = n.appName || "Notification"
            if (!map.has(key))
                map.set(key, [])
            map.get(key).push(n)
        }
        const out = []
        for (const [app, list] of map)
            out.push({ app, list })
        return out
    }

    readonly property int notifCount: {
        const _r = _rev
        return (NotifsService.tracked || []).length
    }

    anchors.fill: parent

    ColumnLayout {
        anchors.fill: parent
        spacing: 10 * s

        Text {
            Layout.fillWidth: true
            text: notifCount > 0
                ? notifCount + " notification" + (notifCount === 1 ? "" : "s")
                : "Notifications"
            color: WallustColors.buttonHover
            opacity: 0.55
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize + 1
            font.bold: true
            elide: Text.ElideRight
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: notifList
                anchors.fill: parent
                visible: groups.length > 0
                spacing: 8 * s
                clip: true
                model: groups

                delegate: LockNotifGroupCard {
                    required property var modelData
                    width: notifList.width
                    appName: modelData.app
                    notifList: modelData.list
                    iconSize: root.iconBox
                }
            }

            Text {
                anchors.centerIn: parent
                width: parent.width
                visible: groups.length === 0
                text: "No notifications"
                color: WallustColors.buttonHover
                opacity: 0.4
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize
                font.italic: true
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}