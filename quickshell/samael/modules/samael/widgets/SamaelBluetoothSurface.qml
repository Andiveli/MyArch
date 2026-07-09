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

    onRequestClose: GlobalStates.samaelBluetoothMenuOpen = false

    implicitWidth: 320
    implicitHeight: 400

    keyboardPanel: btMenu

    SamaelBluetoothMenu {
        id: btMenu
        anchors.fill: parent
        focus: true
    }

    // ── Keyboard API — delegate to SamaelBluetoothMenu's existing nav ──

    function moveH(dir) {
        // No horizontal sub-views in current Bluetooth menu
    }

    function moveV(dir) {
        btMenu.moveSelection(dir)
    }

    function activate() {
        btMenu.activateAt(btMenu.selectedIndex)
    }

    function back() {
        return false
    }
}
