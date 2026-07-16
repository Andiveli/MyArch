pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/** Screen record — scripts/record-ctl.py + gpu-screen-recorder (no caelestia CLI). */
Singleton {
    id: root

    readonly property string scriptPath: Quickshell.shellDir + "/scripts/record-ctl.py"

    property bool running: false
    property bool paused: false
    property bool recorderInstalled: false
    property string lastError: ""
    property var monitors: []
    property var windows: []
    property var audioSink: ({ volume: 0, muted: false })
    property var audioSource: ({ volume: 0, muted: false })
    property var recordConfig: ({})
    property bool configOpen: false
    property int revision: 0
    property bool opBusy: false
    property int _lastRecordToggleMs: 0

    function bump() {
        revision++
    }

    function _parseStatus(out) {
        try {
            const j = JSON.parse(out)
            root.running = !!j.running
            root.paused = !!j.paused
            root.recorderInstalled = !!j.recorderInstalled
            root.monitors = j.monitors || []
            root.windows = j.windows || []
            root.audioSink = j.audioSink || { volume: 0, muted: false }
            root.audioSource = j.audioSource || { volume: 0, muted: false }
            root.recordConfig = j.config || {}
            if (j.lastError)
                root.lastError = j.lastError
            bump()
            return true
        } catch (e) {
            root.lastError = "status parse failed"
            return false
        }
    }

    function refresh() {
        statusProc.running = true
    }

    function startMonitor() {
        if (opBusy)
            return
        runOp(["start"])
    }

    function toggleRecord() {
        const now = Date.now()
        if (now - _lastRecordToggleMs < 700)
            return
        _lastRecordToggleMs = now
        if (opBusy)
            return
        if (running)
            stop()
        else
            startMonitor()
    }

    function startRegion() {
        runOp(["start", "slurp"])
    }

    function stop() {
        runOp(["stop"])
    }

    function togglePause() {
        runOp(["pause"])
    }

    function toggleSinkMute() {
        runOp(["audio", "toggle-mute", "sink"])
    }

    function toggleSourceMute() {
        runOp(["audio", "toggle-mute", "source"])
    }

    function setSinkVolume(pct) {
        runOp(["audio", "set-volume", "sink", String(Math.round(pct))])
    }

    function setSourceVolume(pct) {
        runOp(["audio", "set-volume", "source", String(Math.round(pct))])
    }

    function patchConfig(obj) {
        if (!obj || typeof obj !== "object")
            return
        patchProc.command = ["python3", root.scriptPath, "patch", JSON.stringify(obj)]
        patchProc.running = true
    }

    function runOp(args) {
        if (opProc.running)
            return
        opBusy = true
        opProc.command = ["python3", root.scriptPath].concat(args)
        opProc.running = true
    }

    Process {
        id: statusProc
        command: ["python3", root.scriptPath, "status"]
        stdout: StdioCollector {}
        onExited: (code, status) => {
            if (code === 0 && stdout.text)
                root._parseStatus(stdout.text)
        }
    }

    Process {
        id: opProc
        command: ["python3", root.scriptPath, "status"]
        stdout: StdioCollector {}
        onExited: (code, status) => {
            root.opBusy = false
            if (stdout.text) {
                try {
                    const j = JSON.parse(stdout.text)
                    if (!j.ok && j.error)
                        root.lastError = j.error
                    else if (j.ok && j.path !== undefined && j.path.length > 0)
                        root.lastError = ""
                    else if (j.ok && j.error)
                        root.lastError = j.error
                } catch (e) { /* ignore */ }
            }
            Qt.callLater(root.refresh)
        }
    }

    Process {
        id: patchProc
        command: ["python3", root.scriptPath, "patch", "{}"]
        stdout: StdioCollector {}
        onExited: () => {
            ShellConfig.reloadFromDisk()
            Qt.callLater(root.refresh)
        }
    }

    Timer {
        interval: running ? 800 : 2500
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}