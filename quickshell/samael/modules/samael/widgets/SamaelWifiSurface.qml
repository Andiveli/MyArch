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

    onRequestClose: GlobalStates.samaelWifiMenuOpen = false

    implicitWidth: 400
    implicitHeight: 420

    keyboardPanel: wifiMenu

    SamaelWifiMenu {
        id: wifiMenu
        anchors.fill: parent
        focus: true
    }

    // ── Keyboard API — delegate to SamaelWifiMenu's existing nav ──

    function moveH(dir) {
        if (wifiMenu.menuMode === "password" || wifiMenu.menuMode === "detail") {
            wifiMenu.menuMode = "list"
        } else if (wifiMenu.menuMode === "list" && dir > 0) {
            wifiMenu.menuMode = "filter"
        }
    }

    function moveV(dir) {
        wifiMenu.moveSelection(dir)
    }

    function activate() {
        wifiMenu.tryConnectSelected()
    }

    function back() {
        if (wifiMenu.menuMode !== "list") {
            wifiMenu.menuMode = "list"
            return true
        }
        return false
    }
}
