pragma ComponentBehavior: Bound

import qs.modules.common.widgets
import qs.services
import qs.modules.samael.widgets
import QtQuick
import Quickshell

// Same model/delegate wiring as common NotificationListView; Samael chrome on groups.
StyledListView {
    id: root
    property bool popup: false

    popin: true
    animateAppearance: true
    animateMovement: true
    spacing: 3

    model: ScriptModel {
        values: root.popup ? Notifications.popupAppNameList : Notifications.appNameList
    }
    delegate: SamaelNotificationGroup {
        required property int index
        required property var modelData
        popup: root.popup
        width: ListView.view.width
        notificationGroup: popup
            ? Notifications.popupGroupsByAppName[modelData]
            : Notifications.groupsByAppName[modelData]
    }
}