import QtQuick
import "../singletons"

Item {
    implicitWidth: bell.implicitWidth
    implicitHeight: Style.barContentHeight

    Text {
        id: bell
        anchors.verticalCenter: parent.verticalCenter
        text: "\uf0f3"
        color: WallustColors.notificationIcon
        font.pixelSize: Style.fontPixelSize
        font.family: Style.fontFamily
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (NotifsService.popups.length > 0)
                NotifsService.removePopup(NotifsService.popups[NotifsService.popups.length - 1])
            else if (ShellActions.toggleNotifications)
                ShellActions.toggleNotifications()
        }
    }
}