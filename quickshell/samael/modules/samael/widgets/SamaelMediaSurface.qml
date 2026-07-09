import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.samael

SamaelPillSurface {
    id: surface

    mTop: 0
    mLeft: 0
    mRight: 0
    mBottom: 0

    onRequestClose: {
        GlobalStates.mediaControlsOpen = false
        GlobalStates.samaelMediaClosing = false
        // Ensure we give focus back to the previous client (Hyprland doesn't do it automatically)
        Qt.callLater(() => {
            if (typeof SamaelBarNavHub !== "undefined" && SamaelBarNavHub.restoreHyprClientIfNeeded)
                SamaelBarNavHub.restoreHyprClientIfNeeded()
        })
    }

    implicitWidth: 728
    implicitHeight: mediaManager.implicitHeight

    keyboardPanel: mediaManager

    SamaelMediaManager {
        id: mediaManager
        width: 728
        anchors.horizontalCenter: parent.horizontalCenter
        embeddedInBar: true
        focus: true
    }

    // ── Keyboard API — delegate to SamaelMediaManager's controls ──

    function moveH(dir) {
        mediaManager.moveControlFocus(dir)
    }

    function moveV(dir) {
        mediaManager.seekBy(dir > 0 ? mediaManager.seekStepSec : -mediaManager.seekStepSec)
    }

    function activate() {
        mediaManager.activateFocusedControl()
    }

    function back() {
        return false
    }
}
