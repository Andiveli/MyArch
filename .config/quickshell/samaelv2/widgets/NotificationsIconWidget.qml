import QtQuick
import "../singletons"

/** Bar notifications control — samael-style bell + numeric badge (tracked inbox). */
Item {
    id: root

    readonly property int _rev: NotifsService.listRevision
    readonly property int inboxCount: {
        const _t = _rev
        return (NotifsService.tracked || []).length
    }
    readonly property bool showBadge: inboxCount > 0 && !NotifsService.dnd
    readonly property string badgeText: inboxCount > 99 ? "99+" : String(inboxCount)

    implicitWidth: bell.implicitWidth + (showBadge ? 10 : 0)
    implicitHeight: Style.barContentHeight

    Text {
        id: bell
        anchors.verticalCenter: parent.verticalCenter
        text: NotifsService.dnd ? "\uf1f6" : "\uf0f3"
        color: root.showBadge ? WallustColors.accent : WallustColors.moduleText
        font.pixelSize: Style.fontPixelSize
        font.family: Style.fontFamily
        opacity: NotifsService.dnd ? 0.45 : (root.showBadge ? 1 : 0.85)
    }

    Rectangle {
        id: badgeBg
        visible: root.showBadge
        z: 2
        width: Math.max(badgeLbl.implicitWidth + 6, 14)
        height: 14
        radius: 7
        color: WallustColors.accent
        anchors.left: bell.right
        anchors.leftMargin: -6
        anchors.top: bell.top
        anchors.topMargin: -4

        Text {
            id: badgeLbl
            anchors.centerIn: parent
            text: root.badgeText
            color: WallustColors.moduleText
            font.family: Style.fontFamily
            font.pixelSize: inboxCount > 99 ? 6 : 7
            font.bold: true
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                NotifsService.dnd = !NotifsService.dnd
                return
            }
            if (NotifsService.popups.length > 0)
                NotifsService.removePopup(NotifsService.popups[NotifsService.popups.length - 1])
            else if (ShellActions.toggleNotifications)
                ShellActions.toggleNotifications()
        }
    }
}