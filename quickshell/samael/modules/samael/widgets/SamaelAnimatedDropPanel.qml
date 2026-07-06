import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.services
import qs.modules.samael.widgets

PanelWindow {
    id: panel

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    color: "transparent"
    anchors.top: true
    margins.top: Appearance.sizes.barHeight + Appearance.sizes.hyprlandGapsOut + 4

    property real offsetScale: 1

    Behavior on offsetScale {
        NumberAnimation {
            duration: Appearance.animation.samaelMediaAttach.duration
            easing.type: Appearance.animation.samaelMediaAttach.type
            easing.bezierCurve: Appearance.animation.samaelMediaAttach.bezierCurve
        }
    }

    Item {
        id: clipHost
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: attach.implicitWidth
        height: attach.implicitHeight
        clip: true

        SamaelCaelestiaAttach {
            id: attach
            offsetScale: panel.offsetScale
            edge: "top"
        }
    }

    default property alias dropBody: attach.content

    implicitWidth: Math.max(clipHost.width, attach.implicitWidth)
    implicitHeight: attach.implicitHeight
    mask: Region { item: clipHost }

    function playOpen() {
        offsetScale = 0
    }

    function playClose(done) {
        closeDone = done || null
        offsetScale = 1
    }

    property var closeDone: null
    onOffsetScaleChanged: {
        if (offsetScale >= 0.999 && closeDone) {
            const f = closeDone
            closeDone = null
            f()
        }
    }

    function requestDismiss() {
        if (panel.onRequestClose)
            panel.onRequestClose()
        else
            GlobalFocusGrab.dismiss()
    }

    Component.onCompleted: {
        GlobalFocusGrab.addDismissable(panel)
        Qt.callLater(playOpen)
    }

    Component.onDestruction: GlobalFocusGrab.removeDismissable(panel)

    Connections {
        target: GlobalFocusGrab
        function onDismissed() {
            panel.requestDismiss()
        }
    }

    property var onRequestClose: null
}