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
    }

    implicitWidth: 728
    implicitHeight: mediaManager.implicitHeight

    SamaelMediaManager {
        id: mediaManager
        width: 728
        anchors.horizontalCenter: parent.horizontalCenter
        embeddedInBar: true
        focus: true
    }

    // ── Keyboard API — delegate to SamaelMediaManager's controls ──

    function moveH(dir) {
        // Cycle through controls: shuffle ← prev ← play/pause ← next ← loop
        // For now, no-op as SamaelMediaManager handles its own focus
    }

    function moveV(dir) {
        // Seek backward/forward
    }

    function activate() {
        // Toggle play/pause
    }

    function back() {
        return false
    }
}
