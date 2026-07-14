import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../singletons"
import "./LockSurface.qml"
import "./LockPreviewOverlay.qml"

Scope {
    id: root

    property alias sessionLock: sessionLock
    property bool previewActive: false

    function requestLock() {
        if (ShellConfig.lockPreviewUi)
            root.previewActive = !root.previewActive
        else
            sessionLock.locked = true
    }

    function requestUnlock() {
        if (ShellConfig.lockPreviewUi)
            root.previewActive = false
        else
            LockService.forceUnlock()
    }

    function isLocked(): bool {
        if (ShellConfig.lockPreviewUi)
            return root.previewActive
        return sessionLock.locked
    }

    Component.onCompleted: LockService.loadSysInfo()

    WlSessionLock {
        id: sessionLock

        signal unlockRequested()

        function unlock() {
            unlockRequested()
        }

        onUnlockRequested: {
            // IPC unlock: release immediately (no password / no animation path)
            LockService.forceUnlock()
        }

        Component.onCompleted: LockService.wlSessionLock = sessionLock
        Component.onDestruction: {
            if (LockService.wlSessionLock === sessionLock)
                LockService.wlSessionLock = null
        }

        LockSurface {}
    }

    Variants {
        model: Quickshell.screens

        LockPreviewOverlay {
            active: root.previewActive
        }
    }

    Loader {
        asynchronous: true
        active: true
        onLoaded: active = false
        sourceComponent: ScreencopyView {
            captureSource: Quickshell.screens.length ? Quickshell.screens[0] : null
        }
    }
}