import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import "../singletons"

/**
 * Middle pill notifications — vim nav; groups by service (summary for notify-send).
 */
FocusScope {
    id: root

    property bool open: false
    property real morphCloseness: 1

    readonly property int _listTick: NotifsService.listRevision
    readonly property var groups: {
        const _t = _listTick
        return NotifsService.groupsForTracked()
    }
    readonly property int groupCount: groups.length

    property int groupIndex: 0
    property string expandedKey: ""
    property int itemIndex: 0

    implicitWidth: 360
    implicitHeight: Math.min(340, header.height + list.contentHeight + 12)

    opacity: open ? Math.pow(morphCloseness, 1.2) : 0
    visible: opacity > 0.02
    enabled: open
    focus: open

    function currentGroup() {
        if (groupIndex < 0 || groupIndex >= groupCount)
            return null
        return groups[groupIndex]
    }

    function clampIndices() {
        if (groupCount === 0) {
            groupIndex = 0
            itemIndex = 0
            expandedKey = ""
            return
        }
        groupIndex = Math.max(0, Math.min(groupCount - 1, groupIndex))
        const g = currentGroup()
        if (!g)
            return
        if (expandedKey !== g.key) {
            itemIndex = 0
            return
        }
        const n = g.notifications.length
        itemIndex = Math.max(0, Math.min(Math.max(0, n - 1), itemIndex))
    }

    function toggleExpand() {
        const g = currentGroup()
        if (!g)
            return
        if (expandedKey === g.key) {
            expandedKey = ""
            itemIndex = 0
        } else {
            expandedKey = g.key
            itemIndex = 0
        }
    }

    function focusedNotif() {
        const g = currentGroup()
        if (!g || expandedKey !== g.key || !g.notifications.length)
            return null
        return g.notifications[itemIndex] || g.notifications[0]
    }

    function dismissFocused() {
        const n = focusedNotif()
        if (n)
            NotifsService.dismissNotif(n)
        else {
            const g = currentGroup()
            if (g && g.notifications.length === 1)
                NotifsService.dismissNotif(g.notifications[0])
        }
        clampIndices()
    }

    function dismissGroup() {
        const g = currentGroup()
        if (!g)
            return
        for (let i = 0; i < g.notifications.length; i++)
            NotifsService.dismissNotif(g.notifications[i])
        expandedKey = ""
        clampIndices()
    }

    onOpenChanged: {
        if (open) {
            groupIndex = 0
            expandedKey = ""
            itemIndex = 0
            Qt.callLater(clampIndices)
            Qt.callLater(forceActiveFocus)
        }
    }

    on_ListTickChanged: clampIndices()

    Component.onCompleted: clampIndices()

    Keys.onPressed: event => {
        if (!open)
            return
        const t = event.text
        if (event.key === Qt.Key_Escape) {
            ShellActions.closeMiddleSurface?.()
            event.accepted = true
            return
        }
        if (t === "j" || event.key === Qt.Key_Down) {
            const g = currentGroup()
            if (g && expandedKey === g.key && g.notifications.length > 1) {
                itemIndex = Math.min(g.notifications.length - 1, itemIndex + 1)
            } else {
                groupIndex = Math.min(groupCount - 1, groupIndex + 1)
                if (expandedKey.length && currentGroup()?.key !== expandedKey)
                    expandedKey = ""
                itemIndex = 0
            }
            event.accepted = true
            return
        }
        if (t === "k" || event.key === Qt.Key_Up) {
            const g = currentGroup()
            if (g && expandedKey === g.key && itemIndex > 0) {
                itemIndex--
            } else {
                groupIndex = Math.max(0, groupIndex - 1)
                if (expandedKey.length && currentGroup()?.key !== expandedKey)
                    expandedKey = ""
                itemIndex = 0
            }
            event.accepted = true
            return
        }
        if (t === "h" || event.key === Qt.Key_Left) {
            if (expandedKey.length) {
                expandedKey = ""
                itemIndex = 0
            } else {
                groupIndex = Math.max(0, groupIndex - 1)
            }
            event.accepted = true
            return
        }
        if (t === "l" || event.key === Qt.Key_Right || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            const g = currentGroup()
            if (!g) {
                event.accepted = true
                return
            }
            if (expandedKey === g.key) {
                const n = focusedNotif()
                if (n)
                    NotifsService.activateNotif(n)
            } else {
                toggleExpand()
            }
            event.accepted = true
            return
        }
        if (t === "o") {
            toggleExpand()
            event.accepted = true
            return
        }
        if (t === "x") {
            dismissFocused()
            event.accepted = true
            return
        }
        if (t === "X") {
            dismissGroup()
            event.accepted = true
            return
        }
        if (t === "d") {
            NotifsService.dismissAllTracked()
            expandedKey = ""
            clampIndices()
            event.accepted = true
        }
    }

    Column {
        id: column
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        RowLayout {
            id: header
            width: parent.width
            spacing: 8

            Text {
                text: "\uf0f3"
                color: WallustColors.notificationIcon
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize + 2
            }

            Text {
                text: "Notifications"
                color: WallustColors.moduleText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize + 1
                font.bold: true
            }

            Text {
                text: root.groupCount ? ("(" + NotifsService.tracked.length + ")") : ""
                color: WallustColors.moduleText
                opacity: 0.55
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize - 1
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "j/k · l/o · x · Esc"
                color: WallustColors.moduleText
                opacity: 0.4
                font.family: Style.fontFamily
                font.pixelSize: 9
            }
        }

        Text {
            width: parent.width
            visible: root.groupCount === 0
            horizontalAlignment: Text.AlignHCenter
            text: "Nothing here"
            color: WallustColors.moduleText
            opacity: 0.55
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize
        }

        ListView {
            id: list
            width: parent.width
            height: Math.min(280, Math.max(40, contentHeight))
            clip: true
            spacing: 4
            model: root.groups
            visible: root.groupCount > 0
            currentIndex: root.groupIndex
            highlightMoveDuration: Motion.fast

            delegate: Item {
                id: groupDelegate
                required property int index
                required property var modelData

                width: list.width
                implicitHeight: groupBox.implicitHeight

                readonly property bool groupFocused: index === root.groupIndex
                readonly property bool expanded: root.expandedKey === modelData.key

                Rectangle {
                    id: groupBox
                    width: parent.width
                    implicitHeight: inner.implicitHeight + 12
                    radius: 10
                    color: groupFocused
                        ? Qt.rgba(WallustColors.accent.r, WallustColors.accent.g, WallustColors.accent.b, 0.14)
                        : Qt.rgba(0, 0, 0, 0.22)
                    border.width: groupFocused ? 1 : 0
                    border.color: Qt.rgba(WallustColors.accent.r, WallustColors.accent.g, WallustColors.accent.b, 0.45)

                    Column {
                        id: inner
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 6
                        spacing: 4

                        Row {
                            width: parent.width
                            spacing: 8

                            Rectangle {
                                width: 28
                                height: 28
                                radius: 8
                                color: WallustColors.moduleBackground
                                border.width: 1
                                border.color: WallustColors.borderColor

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    source: NotifsService.iconFor(modelData.notifications[0])
                                    fillMode: Image.PreserveAspectFit
                                    visible: source.toString().length > 0
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: parent.children[0].source.toString().length === 0
                                    text: "\uf1b2"
                                    font.family: Style.fontFamily
                                    font.pixelSize: 12
                                    color: WallustColors.notificationIcon
                                }
                            }

                            Column {
                                width: parent.width - 52
                                spacing: 1

                                Text {
                                    width: parent.width
                                    elide: Text.ElideRight
                                    text: modelData.label || modelData.appName
                                    color: WallustColors.moduleText
                                    font.family: Style.fontFamily
                                    font.pixelSize: Style.fontPixelSize
                                    font.bold: true
                                }

                                Text {
                                    width: parent.width
                                    elide: Text.ElideRight
                                    opacity: 0.65
                                    text: modelData.notifications.length === 1
                                        ? (modelData.notifications[0].summary || modelData.notifications[0].body || "")
                                        : (modelData.notifications.length + " notifications")
                                    color: WallustColors.moduleText
                                    font.family: Style.fontFamily
                                    font.pixelSize: Style.fontPixelSize - 1
                                }
                            }

                            Text {
                                text: expanded ? "\uf078" : "\uf054"
                                font.family: Style.fontFamily
                                font.pixelSize: 10
                                color: WallustColors.moduleText
                                opacity: 0.5
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Repeater {
                            model: expanded ? modelData.notifications : []

                            delegate: Rectangle {
                                required property int index
                                required property var modelData

                                width: inner.width
                                implicitHeight: notifCol.implicitHeight + 10
                                radius: 8
                                color: (groupFocused && root.expandedKey === groupDelegate.modelData.key && index === root.itemIndex)
                                    ? Qt.rgba(WallustColors.sky.r, WallustColors.sky.g, WallustColors.sky.b, 0.12)
                                    : Qt.rgba(0, 0, 0, 0.18)

                                Column {
                                    id: notifCol
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    spacing: 2

                                    Text {
                                        width: parent.width
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                        text: modelData.summary || modelData.appName || ""
                                        color: WallustColors.moduleText
                                        font.family: Style.fontFamily
                                        font.pixelSize: Style.fontPixelSize
                                        font.bold: modelData.urgency === NotificationUrgency.Critical
                                    }

                                    Text {
                                        width: parent.width
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 3
                                        opacity: 0.75
                                        text: modelData.body || ""
                                        color: WallustColors.moduleText
                                        font.family: Style.fontFamily
                                        font.pixelSize: Style.fontPixelSize - 1
                                        visible: (modelData.body || "").length > 0
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        root.groupIndex = groupDelegate.index
                                        root.expandedKey = groupDelegate.modelData.key
                                        root.itemIndex = index
                                        NotifsService.activateNotif(modelData)
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.groupIndex = index
                            root.toggleExpand()
                        }
                    }
                }
            }
        }
    }
}