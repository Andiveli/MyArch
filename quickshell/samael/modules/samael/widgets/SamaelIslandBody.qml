import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.samael
import qs.modules.common

// Compact / expanded body inside the center bar capsule (not a separate overlay panel).
Item {
    id: root
    property bool expanded: false
    property int lineWidth: parent ? parent.width : 280
    // 0..1 drip reveal from overlay island; 1 = show text immediately
    property real revealProgress: 1
    readonly property real labelOpacity: {
if (revealProgress >= 1)
return 1
if (revealProgress < 0.52)
return 0
return Math.min(1, (revealProgress - 0.52) / 0.28)
    }

    readonly property var popupNotifs: Notifications.popupList
    readonly property bool active: popupNotifs.length > 0 && !GlobalStates.screenLocked

    readonly property var topNotif: {
        const pl = popupNotifs
        if (!pl.length)
            return null
        let best = pl[0]
        for (let i = 1; i < pl.length; i++) {
            if (pl[i].time > best.time)
                best = pl[i]
        }
        return best
    }

    readonly property int moreCount: Math.max(0, popupNotifs.length - 1)

    width: Math.max(lineWidth, 1)
    implicitHeight: active ? bodyColumn.implicitHeight : 0
    height: implicitHeight
    clip: true

    function dismissTop() {
        const n = topNotif
        if (n)
            Notifications.discardNotification(n.notificationId)
    }

    function dismissAllPopups() {
        const ids = popupNotifs.map(n => n.notificationId)
        for (let i = 0; i < ids.length; i++)
            Notifications.discardNotification(ids[i])
    }

    function syncTimeouts(hovering) {
        if (!active)
            return
        popupNotifs.forEach(notif => {
            if (hovering)
                Notifications.cancelTimeout(notif.notificationId)
            else
                Notifications.timeoutNotification(notif.notificationId)
        })
    }

    ColumnLayout {
        id: bodyColumn
        width: root.width
        spacing: 4
        opacity: root.labelOpacity
        Behavior on opacity {
        NumberAnimation { duration: 70; easing.type: Easing.OutQuad }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: WallustColors.borderColor
            opacity: 0.55
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: ""
                font.family: SamaelStyle.fontFamily
                font.pixelSize: SamaelStyle.fontPixelSize
                color: WallustColors.notificationIcon
            }

            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                maximumLineCount: 1
                text: topNotif ? SamaelNotificationFormat.line(topNotif) : ""
                font.family: SamaelStyle.fontFamily
                font.pixelSize: SamaelStyle.fontPixelSize
                color: WallustColors.moduleText
            }

            Item {
                visible: moreCount > 0
                implicitWidth: moreBadge.implicitWidth + 8
                implicitHeight: moreBadge.implicitHeight + 4
                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: Qt.rgba(0, 0, 0, 0.25)
                }
                Text {
                    id: moreBadge
                    anchors.centerIn: parent
                    text: "+" + moreCount
                    font.family: SamaelStyle.fontFamily
                    font.pixelSize: Math.max(8, SamaelStyle.fontPixelSize - 2)
                    color: WallustColors.workspaceActive
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: expanded && (topNotif?.body || "").length > 0
            text: topNotif?.body || ""
            wrapMode: Text.Wrap
            maximumLineCount: 4
            elide: Text.ElideRight
            font.family: SamaelStyle.fontFamily
            font.pixelSize: Math.max(8, SamaelStyle.fontPixelSize - 1)
            color: WallustColors.sapphire
            opacity: expanded ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: 180 }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: active
            horizontalAlignment: Text.AlignHCenter
            text: expanded ? "click · dismiss   │   right · all   │   mid · one" : "click · expand"
            font.family: SamaelStyle.fontFamily
            font.pixelSize: 7
            color: WallustColors.buttonHover
            opacity: 0.85
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onContainsMouseChanged: root.syncTimeouts(containsMouse)
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.dismissAllPopups()
            else if (mouse.button === Qt.MiddleButton)
                root.dismissTop()
            else
                root.expanded = !root.expanded
        }
    }

    Connections {
        target: Notifications
        function onListChanged() {
            if (!root.topNotif)
                root.expanded = false
        }
    }
}