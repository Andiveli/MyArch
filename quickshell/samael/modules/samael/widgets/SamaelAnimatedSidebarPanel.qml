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
    WlrLayershell.namespace: "quickshell:samael:systemSidebar"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    color: "transparent"
    anchors.top: true
    anchors.right: true
    margins.top: Appearance.sizes.barHeight + Appearance.sizes.hyprlandGapsOut + 8
    margins.right: Appearance.sizes.hyprlandGapsOut + 8

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
        anchors.right: parent.right
        width: attach.implicitWidth
        height: attach.implicitHeight
        clip: true

        SamaelCaelestiaAttach {
            id: attach
            offsetScale: panel.offsetScale
            edge: "right"
        }
    }

    default property alias sidebarBody: attach.content

    implicitWidth: attach.implicitWidth
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