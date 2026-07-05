import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.samael

Item {
    id: root
    focus: true
    property int selectedIndex: 0
    property bool vimPendingG: false
    property var expandedGroups: ({})

    function sourceKey(notif) {
        if (!notif)
            return "?"
        if (SamaelNotificationFormat.hideAppName(notif)) {
            const t = SamaelNotificationFormat.title(notif)
            return "title:" + (t.length ? t : "?")
        }
        return "app:" + (notif.appName || "?")
    }

    function sourceLabel(notif) {
        if (!notif)
            return "?"
        if (SamaelNotificationFormat.hideAppName(notif))
            return SamaelNotificationFormat.title(notif) || "?"
        return notif.appName || "?"
    }

    readonly property var groups: {
        const list = Notifications.list
        const map = {}
        const order = []
        for (let i = list.length - 1; i >= 0; i--) {
            const n = list[i]
            const k = sourceKey(n)
            if (!map[k]) {
                map[k] = {
                    key: k,
                    label: sourceLabel(n),
                    notifs: [],
                }
                order.push(k)
            }
            map[k].notifs.push(n)
        }
        return order.map(k => map[k])
    }

    readonly property var rows: {
        const out = []
        const gs = groups
        for (let g = 0; g < gs.length; g++) {
            const group = gs[g]
            const expanded = !!expandedGroups[group.key]
            out.push({
                type: "header",
                groupKey: group.key,
                group: group,
                expanded: expanded,
            })
            if (expanded) {
                for (let c = 0; c < group.notifs.length; c++) {
                    out.push({
                        type: "child",
                        groupKey: group.key,
                        group: group,
                        notif: group.notifs[c],
                        childIndex: c,
                    })
                }
            }
        }
        return out
    }

    function rowAt(i) { return rows[i] ?? null }

    function rebuildSelection() {
        const n = rows.length
        if (n === 0)
            selectedIndex = 0
        else if (selectedIndex >= n)
            selectedIndex = n - 1
    }

    function moveToIndex(index) {
        const n = rows.length
        if (n === 0)
            return
        selectedIndex = Math.max(0, Math.min(index, n - 1))
        list.positionViewAtIndex(selectedIndex, ListView.Contain)
    }

    function moveSelection(delta) {
        const n = rows.length
        if (n === 0)
            return
        let next = selectedIndex + delta
        if (next < 0)
            next = n - 1
        if (next >= n)
            next = 0
        moveToIndex(next)
    }

    function toggleExpandedAt(index) {
        const row = rowAt(index)
        if (!row || row.type !== "header")
            return
        const key = row.groupKey
        const next = Object.assign({}, expandedGroups)
        next[key] = !next[key]
        expandedGroups = next
        Qt.callLater(() => rebuildSelection())
    }

    function dismissRowAt(index) {
        const row = rowAt(index)
        if (!row)
            return
        if (row.type === "child" && row.notif)
            Notifications.discardNotification(row.notif.notificationId)
        else if (row.type === "header" && row.group) {
            const ids = row.group.notifs.map(n => n.notificationId)
            for (let i = 0; i < ids.length; i++)
                Notifications.discardNotification(ids[i])
            const next = Object.assign({}, expandedGroups)
            delete next[row.groupKey]
            expandedGroups = next
        }
        Qt.callLater(() => rebuildSelection())
    }

    function closeMenu() { GlobalStates.samaelNotificationsMenuOpen = false }

    Connections {
        target: Notifications
        function onListChanged() { root.rebuildSelection() }
    }

    Timer {
        id: vimGChordTimer
        interval: 450
        onTriggered: {
            if (root.vimPendingG) {
                root.moveToIndex(0)
                root.vimPendingG = false
            }
        }
    }

    implicitWidth: 360
    implicitHeight: Math.min(480, Math.max(160, 88 + rows.length * 46))

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: SamaelStyle.menuPanelFill
        border.width: 2
        border.color: WallustColors.borderColor

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Notifications"
                    color: WallustColors.moduleText
                    font.family: SamaelStyle.fontFamily
                    font.pixelSize: SamaelStyle.fontPixelSize + 1
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: Notifications.silent
                        ? "silent"
                        : (groups.length + " · " + Notifications.list.length)
                    color: WallustColors.sapphire
                    font.family: SamaelStyle.fontFamily
                    font.pixelSize: SamaelStyle.fontPixelSize - 1
                }
            }

            Text {
                text: "Enter/l expand · j/k · d dismiss · D all · t silent · Esc"
                color: WallustColors.buttonHover
                font.family: SamaelStyle.fontFamily
                font.pixelSize: 8
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 2
                model: root.rows
                currentIndex: root.selectedIndex
                onCurrentIndexChanged: if (currentIndex >= 0)
                    root.selectedIndex = currentIndex

                delegate: Rectangle {
                    required property int index
                    required property var modelData
                    width: list.width
                    height: rowRoot.implicitHeight + 10
                    radius: 8
                    color: index === root.selectedIndex
                        ? WallustColors.buttonHover
                        : Qt.rgba(0, 0, 0, modelData.type === "child" ? 0.12 : 0.2)
                    border.width: index === root.selectedIndex ? 1 : 0
                    border.color: WallustColors.workspaceActive

                    property var row: modelData
                    property var notif: modelData.notif
                    property var group: modelData.group

                    ColumnLayout {
                        id: rowRoot
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            visible: row.type === "header"
                            spacing: 6
                            Text {
                                text: modelData.expanded ? "▾" : "▸"
                                color: WallustColors.workspaceActive
                                font.family: SamaelStyle.fontFamily
                                font.pixelSize: SamaelStyle.fontPixelSize
                            }
                            Text {
                                Layout.fillWidth: true
                                text: group.label
                                elide: Text.ElideRight
                                color: WallustColors.moduleText
                                font.family: SamaelStyle.fontFamily
                                font.pixelSize: SamaelStyle.fontPixelSize
                                font.bold: false
                            }
                            Text {
                                text: String(group.notifs.length)
                                color: WallustColors.sapphire
                                font.family: SamaelStyle.fontFamily
                                font.pixelSize: SamaelStyle.fontPixelSize - 1
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: row.type === "header" && !modelData.expanded
                            text: {
                                const latest = group.notifs[0]
                                if (!latest)
                                    return ""
                                const line = SamaelNotificationFormat.line(latest)
                                return line.length ? line : SamaelNotificationFormat.content(latest)
                            }
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            color: WallustColors.sapphire
                            font.family: SamaelStyle.fontFamily
                            font.pixelSize: Math.max(8, SamaelStyle.fontPixelSize - 2)
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: row.type === "child"
                            Layout.leftMargin: 14
                            text: SamaelNotificationFormat.title(notif)
                            elide: Text.ElideRight
                            color: WallustColors.moduleText
                            font.family: SamaelStyle.fontFamily
                            font.pixelSize: SamaelStyle.fontPixelSize - 1
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: row.type === "child"
                                && SamaelNotificationFormat.content(notif).length > 0
                            Layout.leftMargin: 14
                            text: SamaelNotificationFormat.content(notif)
                            elide: Text.ElideRight
                            maximumLineCount: 2
                            wrapMode: Text.Wrap
                            color: WallustColors.sapphire
                            font.family: SamaelStyle.fontFamily
                            font.pixelSize: Math.max(8, SamaelStyle.fontPixelSize - 2)
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.selectedIndex = index
                            if (row.type === "header")
                                root.toggleExpandedAt(index)
                        }
                    }
                }
            }

            Text {
                visible: root.rows.length === 0
                Layout.alignment: Qt.AlignHCenter
                text: "Nothing"
                color: WallustColors.buttonHover
                font.family: SamaelStyle.fontFamily
                font.pixelSize: SamaelStyle.fontPixelSize
            }
        }
    }

    Keys.onPressed: event => {
        const text = event.text
        const key = event.key
        if (key === Qt.Key_Escape) {
            closeMenu()
            event.accepted = true
            return
        }
        if (text === "j" || key === Qt.Key_Down) {
            moveSelection(1)
            event.accepted = true
            return
        }
        if (text === "k" || key === Qt.Key_Up) {
            moveSelection(-1)
            event.accepted = true
            return
        }
        if (key === Qt.Key_Return || key === Qt.Key_Enter || text === "l") {
            const row = rowAt(selectedIndex)
            if (row?.type === "header")
                toggleExpandedAt(selectedIndex)
            event.accepted = true
            return
        }
        if (text === "d") {
            dismissRowAt(selectedIndex)
            event.accepted = true
            return
        }
        if (text === "D") {
            Notifications.discardAllNotifications()
            expandedGroups = {}
            selectedIndex = 0
            event.accepted = true
            return
        }
        if (text === "t" || key === Qt.Key_T) {
            Notifications.silent = !Notifications.silent
            event.accepted = true
            return
        }
        if (text === "g" && !(event.modifiers & Qt.ShiftModifier)) {
            if (vimPendingG) {
                moveToIndex(0)
                vimPendingG = false
            } else {
                vimPendingG = true
                vimGChordTimer.restart()
            }
            event.accepted = true
            return
        }
        if (text === "G" || (text === "g" && (event.modifiers & Qt.ShiftModifier))) {
            vimPendingG = false
            moveToIndex(rows.length - 1)
            event.accepted = true
        }
    }

    Connections {
        target: GlobalStates
        function onSamaelNotificationsMenuOpenChanged() {
            if (GlobalStates.samaelNotificationsMenuOpen) {
                Notifications.timeoutAll()
                Notifications.markAllRead()
                rebuildSelection()
                Qt.callLater(() => root.forceActiveFocus())
            }
        }
    }
}