import QtQuick
import qs.modules.ii.bar as Bar

Item {
    id: root
    implicitWidth: tray.implicitWidth
    implicitHeight: tray.implicitHeight

    Bar.SysTray {
        id: tray
        anchors.fill: parent
        showSeparator: false
        showOverflowMenu: false
        showAllItemsInline: true
        trayIconSpacing: 2
    }
}
