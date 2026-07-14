import QtQuick
import Quickshell.Wayland
import "../singletons"
import "./LockPam.qml"
import "./LockPanelVisual.qml"

WlSessionLockSurface {
    id: root

    color: "transparent"

    readonly property var lockHost: LockService.wlSessionLock

    LockPam {
        id: pam
        anchors.fill: parent
        visible: false
        enabled: true
        focus: false
    }

    LockPanelVisual {
        id: visual
        anchors.fill: parent
        screen: root.screen
        pamHost: pam
        designMode: false
    }

    onVisibleChanged: {
        if (visible) {
            LockService.loadSysInfo()
            Qt.callLater(() => visual.playLockIn())
        }
    }
}