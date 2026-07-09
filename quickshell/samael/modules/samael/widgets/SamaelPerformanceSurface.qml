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
        GlobalStates.samaelPerformanceDropOpen = false
        GlobalStates.samaelPerformanceClosing = false
        Qt.callLater(() => {
            if (typeof SamaelBarNavHub !== "undefined" && SamaelBarNavHub.restoreHyprClientIfNeeded)
                SamaelBarNavHub.restoreHyprClientIfNeeded()
        })
    }

    implicitWidth: 840
    implicitHeight: perfBody.implicitHeight

    keyboardPanel: perfBody

    SamaelPerformanceDropBody {
        id: perfBody
        width: parent.width
        focus: true
    }

    // ── Keyboard API — delegate to SamaelPerformanceDropBody's tab nav ──

    function moveH(dir) {
        // Tab switch: h/l cycles between overview and processes tabs
        const tabs = 2
        perfBody.dropTabIndex = (perfBody.dropTabIndex + dir + tabs) % tabs
    }

    function moveV(dir) {
        // Scroll within active tab — handled by tab's internal focus
    }

    function activate() {
        // Activate focused item within tab
    }

    function back() {
        return false
    }
}
