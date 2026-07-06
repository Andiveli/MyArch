pragma Singleton
import QtQuick
import qs

QtObject {
    property var panel: null

    function moveSel(dr, dc) {
        if (panel)
            panel.moveSel(dr, dc)
    }

    function activateSelected() {
        if (panel)
            panel.activateAt(panel.selectedIndex)
    }

    function closeMenu() {
        if (panel)
            panel.closeMenu()
        else
            GlobalStates.sessionOpen = false
    }
}