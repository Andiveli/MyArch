import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import "../singletons"

Item {
    id: root

    Keys.onPressed: event => handleKey(event)

    property string buffer: ""
    property string statusText: ""
    property bool unlocking: false
    readonly property bool passwdActive: passwd.active

    signal unlock()

    function submitPassword() {
        if (!root.unlocking && !passwd.active)
            passwd.start()
    }

    function sessionLockRef() {
        return LockService.wlSessionLock
    }

    function finishUnlockSuccess() {
        root.statusText = ""
        root.buffer = ""
        passwd.abort()
        root.unlocking = true
        LockService.playUnlockAnimation()
        unlockForceTimer.restart()
    }

    PamContext {
        id: passwd
        config: "passwd"
        configDirectory: Quickshell.shellPath("assets/pam.d")

        onResponseRequiredChanged: {
            if (!responseRequired)
                return
            respond(root.buffer)
            root.buffer = ""
        }

        onCompleted: res => {
            if (res === PamResult.Success) {
                finishUnlockSuccess()
                return
            }
            root.unlocking = false
            if (res === PamResult.Error)
                root.statusText = "Authentication error"
            else if (res === PamResult.MaxTries)
                root.statusText = "Too many attempts"
            else
                root.statusText = "Wrong password"
            failTimer.restart()
        }
    }

    Timer {
        id: failTimer
        interval: 3500
        onTriggered: root.statusText = ""
    }

    /** Safety net if unlock animation does not release the session */
    Timer {
        id: unlockForceTimer
        interval: 1600
        repeat: false
        onTriggered: {
            if (LockService.wlSessionLock && LockService.wlSessionLock.locked)
                LockService.forceUnlock()
            root.unlocking = false
        }
    }

    function handleKey(event) {
        if (root.unlocking || passwd.active)
            return
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            passwd.start()
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Backspace) {
            if (event.modifiers & Qt.ControlModifier)
                root.buffer = ""
            else
                root.buffer = root.buffer.slice(0, -1)
            event.accepted = true
            return
        }
        const t = event.text
        if (t.length && /^[^\x00-\x1F\x7F-\x9F]+$/.test(t)) {
            root.buffer += t
            event.accepted = true
        }
    }

    Connections {
        target: LockService.wlSessionLock
        function onLockedChanged() {
            const sl = LockService.wlSessionLock
            if (sl && !sl.locked) {
                passwd.abort()
                root.buffer = ""
                root.statusText = ""
                root.unlocking = false
            }
        }
    }
}