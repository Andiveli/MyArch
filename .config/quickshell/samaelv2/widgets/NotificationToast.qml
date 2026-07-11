import QtQuick
import Quickshell.Services.Notifications
import "../singletons"

/** Toast body inside RightPill chrome (pill Toast layout, Wallust colors). */
Item {
    id: root

    property var notif: null
    property bool live: true

    readonly property bool critical: notif?.urgency === NotificationUrgency.Critical
    readonly property var acts: (notif && notif.actions)
        ? notif.actions.filter(a => a.text && a.text.length > 0)
        : []

    implicitHeight: Math.max(iconTile.height, col.implicitHeight)

    property double deadline: 0

    onNotifChanged: {
        if (!notif) {
            deadline = 0
            return
        }
        deadline = NotifsService.expireAt[notif.id] || (Date.now() + 6000)
    }

    Component.onCompleted: {
        if (notif)
            deadline = NotifsService.expireAt[notif.id] || (Date.now() + 6000)
    }

    Timer {
        interval: Math.max(300, root.deadline - Date.now())
        running: root.deadline > 0 && root.live && root.notif
                && root.notif.urgency !== NotificationUrgency.Critical
        onTriggered: NotifsService.removePopup(root.notif)
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            NotifsService.activateNotif(root.notif)
            NotifsService.removePopup(root.notif)
        }
    }

    Rectangle {
        id: iconTile
        width: 28
        height: 28
        radius: 9
        color: WallustColors.moduleBackground
        border.width: 1
        border.color: WallustColors.borderColor

        Image {
            id: toastImg
            anchors.fill: parent
            anchors.margins: root.notif?.image ? 0 : 6
            source: root.notif ? NotifsService.iconFor(root.notif) : ""
            sourceSize.width: 56
            sourceSize.height: 56
            fillMode: Image.PreserveAspectCrop
            visible: source.toString().length > 0
        }

        Rectangle {
            anchors.centerIn: parent
            visible: !toastImg.visible
            width: 7
            height: 7
            radius: 2
            rotation: 45
            color: root.critical ? WallustColors.accent : WallustColors.notificationIcon
        }
    }

    Text {
        id: dismiss
        anchors.right: parent.right
        anchors.top: parent.top
        text: "✕"
        color: dismissArea.containsMouse ? WallustColors.moduleText : WallustColors.moduleText
        opacity: dismissArea.containsMouse ? 1 : 0.5
        font.pixelSize: 11

        MouseArea {
            id: dismissArea
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: NotifsService.removePopup(root.notif)
        }
    }

    Column {
        id: col
        anchors.left: iconTile.right
        anchors.leftMargin: 10
        anchors.right: dismiss.left
        anchors.rightMargin: 8
        anchors.top: parent.top
        spacing: 3

        Text {
            width: parent.width
            text: (root.notif?.appName?.length) ? root.notif.appName : "System"
            color: WallustColors.moduleText
            opacity: 0.55
            font.pixelSize: 8
            font.weight: Font.DemiBold
            font.capitalization: Font.AllUppercase
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: root.notif?.summary ?? ""
            color: WallustColors.moduleText
            font.pixelSize: 12
            font.weight: Font.DemiBold
            maximumLineCount: 1
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: (root.notif?.body?.length ?? 0) > 0
            text: root.notif?.body ?? ""
            color: WallustColors.moduleText
            opacity: 0.7
            font.pixelSize: 10
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        Row {
            visible: root.acts.length > 0
            spacing: 6
            topPadding: 4

            Repeater {
                model: root.acts

                Rectangle {
                    required property var modelData
                    required property int index
                    height: 20
                    width: actText.implicitWidth + 18
                    radius: 10
                    color: WallustColors.moduleBackground
                    border.width: 1
                    border.color: WallustColors.borderColor

                    Text {
                        id: actText
                        anchors.centerIn: parent
                        text: parent.modelData.text
                        color: WallustColors.moduleText
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            parent.modelData.invoke()
                            if (parent.modelData.identifier === "default")
                                NotifsService.raiseWindow(root.notif)
                            NotifsService.removePopup(root.notif)
                        }
                    }
                }
            }
        }
    }
}