import QtQuick
import qs.modules.samael.widgets.tray as Tray

Item {
    id: root
    implicitWidth: tray.implicitWidth
    implicitHeight: tray.implicitHeight

    Tray.SysTray {
        id: tray
        anchors.fill: parent
        showSeparator: false
        showOverflowMenu: false
        showAllItemsInline: true
        trayIconSpacing: 2
    }
}
