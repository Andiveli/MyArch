import QtQuick
import qs
import qs.services
import qs.modules.samael

SamaelPillSurface {
    id: surface

    mTop: 0
    mLeft: 0
    mRight: 0
    mBottom: 0

    onRequestClose: GlobalStates.samaelNotificationsMenuOpen = false

    implicitWidth: 540
    implicitHeight: 480

    SamaelNotificationsMenu {
        id: menu
        anchors.fill: parent
        focus: true
    }

    // ── Keyboard API — delegate to SamaelNotificationsMenu's existing nav ──

    function moveH(dir) {
        // Notifications uses list nav — no horizontal concept
    }

    function moveV(dir) {
        menu.moveSelection(dir)
    }

    function activate() {
        menu.toggleExpandedAt(menu.selectedIndex)
    }

    function back() {
        return false
    }
}
