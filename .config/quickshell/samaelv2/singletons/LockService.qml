pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    /** Set from lock/Lock.qml — avoids null sessionLock in Pam after binding issues */
    property var wlSessionLock: null

    function forceUnlock() {
        if (wlSessionLock)
            wlSessionLock.locked = false
    }

    /** Fired when PAM succeeds — every LockPanelVisual should run unlock animation */
    signal playUnlockAnimation()

    property var sysLines: []
    property bool sysLoading: false
    property string sysError: ""
    property int sysRevision: 0
    /** Última altura estable fastfetch+media (para locks siguientes y animación) */
    property real layoutLeftColH: 0
    /** Evita saltos de layout mientras corre lock-in */
    property bool layoutFrozen: false

    function loadSysInfo() {
        if (sysProc.running)
            return
        sysLoading = true
        sysError = ""
        sysProc.running = true
    }

    Process {
        id: sysProc
        command: ["python3", Quickshell.shellPath("scripts/lock-sysinfo.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                root.sysLoading = false
                try {
                    const j = JSON.parse(this.text.trim())
                    root.sysLines = Array.isArray(j.lines) ? j.lines : []
                    root.sysError = ""
                } catch (e) {
                    root.sysLines = []
                    root.sysError = "sysinfo parse failed"
                }
                root.sysRevision++
            }
        }
        stderr: StdioCollector {}
        onExited: code => {
            root.sysLoading = false
            if (code !== 0 && !root.sysLines.length)
                root.sysError = "sysinfo exit " + code
        }
    }
}