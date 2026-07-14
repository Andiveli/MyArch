pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/** Desktop app index + launcher modes (/f files, /s web, /t terminal). */
Singleton {
    id: root

    property var apps: []
    property var files: []
    property bool loading: false
    property bool filesLoading: false
    property bool terminalRunning: false
    property string lastError: ""
    property string filesError: ""
    property string terminalCommand: ""
    property int terminalExitCode: -999
    property string terminalStdout: ""
    property string terminalStderr: ""
    property int revision: 0

    function bump() {
        revision++
    }

    function parseQuery(raw) {
        const t = String(raw || "")
        const m = t.match(/^\/([a-zA-Z])\s*(.*)$/)
        if (!m)
            return { mode: "apps", term: t.trim() }
        const letter = m[1].toLowerCase()
        const rest = String(m[2] || "").trim()
        if (letter === "f")
            return { mode: "files", term: rest }
        if (letter === "s")
            return { mode: "search", term: rest }
        if (letter === "t")
            return { mode: "terminal", term: rest }
        return { mode: "apps", term: t.trim() }
    }

    function modeMeta(mode) {
        if (mode === "files")
            return { title: "Files", glyph: "\uf07b", placeholder: "" }
        if (mode === "search")
            return { title: "Search", glyph: "\uf0ac", placeholder: "" }
        if (mode === "terminal")
            return { title: "Terminal", glyph: "\uf120", placeholder: "" }
        return { title: "Applications", glyph: "\uf002", placeholder: "" }
    }

    function resetAuxiliary() {
        files = []
        filesError = ""
        filesLoading = false
        fileDebounce.stop()
        findProc._pendingTerm = ""
        terminalRunning = false
        terminalCommand = ""
        terminalExitCode = -999
        terminalStdout = ""
        terminalStderr = ""
        termProc._stdout = ""
    }

    function clearTerminalOutput() {
        terminalCommand = ""
        terminalExitCode = -999
        terminalStdout = ""
        terminalStderr = ""
        bump()
    }

    function runTerminalCommand(cmd) {
        const q = String(cmd || "").trim()
        if (!q.length || terminalRunning)
            return
        terminalRunning = true
        terminalCommand = q
        terminalStdout = ""
        terminalStderr = ""
        terminalExitCode = -999
        bump()
        termProc.execTerm(q)
    }

    function formatTerminalOutput() {
        const lines = []
        if (terminalCommand.length)
            lines.push("$ " + terminalCommand)
        if (terminalRunning)
            lines.push("…")
        else if (terminalExitCode !== -999) {
            const code = terminalExitCode
            lines.push("exit " + code)
            const out = String(terminalStdout || "").replace(/\s+$/, "")
            const err = String(terminalStderr || "").replace(/\s+$/, "")
            if (out.length)
                lines.push(out)
            if (err.length)
                lines.push(err)
            if (!out.length && !err.length)
                lines.push("(no output)")
        }
        return lines.join("\n")
    }

    function refresh() {
        if (loading)
            return
        loading = true
        lastError = ""
        scanProc.execScan()
    }

    function searchFiles(term) {
        const q = String(term || "").trim()
        if (!q.length) {
            files = []
            filesError = ""
            filesLoading = false
            fileDebounce.stop()
            findProc._pendingTerm = ""
            bump()
            return
        }
        findProc._pendingTerm = q
        fileDebounce.restart()
    }

    function openPath(path) {
        const p = String(path || "").trim()
        if (!p.length)
            return
        Quickshell.execDetached([
            "bash",
            Quickshell.shellPath("scripts/launcher-open-path.sh"),
            p
        ])
        bump()
    }

    function openWebSearch(term) {
        const q = String(term || "").trim()
        if (!q.length)
            return
        const url = "https://duckduckgo.com/?q=" + encodeURIComponent(q)
        Quickshell.execDetached(["xdg-open", url])
        bump()
    }

    function launchEntry(entry) {
        if (!entry || !entry.exec || !String(entry.exec).length)
            return
        const cmd = String(entry.exec)
        if (entry.terminal)
            Quickshell.execDetached(["sh", "-c", cmd])
        else
            Quickshell.execDetached(["sh", "-c", cmd])
        bump()
    }

    function launchByIndex(filtered, index) {
        if (!filtered || index < 0 || index >= filtered.length)
            return
        launchEntry(filtered[index])
    }

    function filterApps(query) {
        const q = String(query || "").trim().toLowerCase()
        const list = apps || []
        if (!q.length)
            return list.slice(0, 80)
        const out = []
        for (let i = 0; i < list.length; i++) {
            const a = list[i]
            const blob = (a.name + " " + (a.comment || "") + " " + (a.categories || "") + " " + (a.desktopId || "")).toLowerCase()
            if (blob.indexOf(q) >= 0)
                out.push(a)
            if (out.length >= 60)
                break
        }
        return out
    }

    function pinnedFirst(filtered) {
        const pins = ShellConfig.launcherPinned || []
        if (!pins.length || !filtered.length)
            return filtered
        const pinSet = {}
        for (let i = 0; i < pins.length; i++)
            pinSet[pins[i]] = true
        const head = []
        const tail = []
        for (let j = 0; j < filtered.length; j++) {
            const id = filtered[j].desktopId
            if (pinSet[id])
                head.push(filtered[j])
            else
                tail.push(filtered[j])
        }
        return head.concat(tail)
    }

    Timer {
        id: fileDebounce
        interval: 240
        repeat: false
        onTriggered: {
            const q = findProc._pendingTerm
            if (!q || !q.length)
                return
            filesLoading = true
            filesError = ""
            findProc.execFind(q)
        }
    }

    Process {
        id: termProc
        property string _stdout: ""
        command: ["python3", Quickshell.shellPath("scripts/launcher-run-cmd.py"), ""]
        function execTerm(cmd) {
            _stdout = ""
            command = ["python3", Quickshell.shellPath("scripts/launcher-run-cmd.py"), cmd]
            running = false
            running = true
        }
        stdout: StdioCollector {
            onStreamFinished: termProc._stdout = String(text)
        }
        onExited: (exitCode) => {
            root.terminalRunning = false
            const raw = termProc._stdout.trim()
            if (!raw.length) {
                root.terminalExitCode = exitCode !== 0 ? exitCode : -1
                root.terminalStderr = root.terminalStderr || "no runner output"
                root.bump()
                return
            }
            try {
                const parsed = JSON.parse(raw)
                root.terminalExitCode = typeof parsed.exitCode === "number" ? parsed.exitCode : -1
                root.terminalStdout = String(parsed.stdout || "")
                root.terminalStderr = String(parsed.stderr || "")
                if (parsed.command)
                    root.terminalCommand = String(parsed.command)
            } catch (e) {
                root.terminalExitCode = -1
                root.terminalStderr = "parse failed"
            }
            root.bump()
        }
    }

    Process {
        id: findProc
        property string _stdout: ""
        property string _pendingTerm: ""
        command: ["python3", Quickshell.shellPath("scripts/launcher-find-files.py"), ""]
        function execFind(term) {
            _stdout = ""
            command = ["python3", Quickshell.shellPath("scripts/launcher-find-files.py"), term]
            running = false
            running = true
        }
        stdout: StdioCollector {
            onStreamFinished: findProc._stdout = String(text)
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const err = String(text).trim()
                if (err.length)
                    root.filesError = err.slice(0, 160)
            }
        }
        onExited: (exitCode) => {
            root.filesLoading = false
            const raw = findProc._stdout.trim()
            if (exitCode !== 0 && !raw.length) {
                root.filesError = root.filesError || ("find exit " + exitCode)
                root.files = []
                root.bump()
                return
            }
            if (!raw.length) {
                root.files = []
                root.bump()
                return
            }
            try {
                const parsed = JSON.parse(raw)
                root.files = Array.isArray(parsed) ? parsed : []
                root.filesError = ""
            } catch (e) {
                root.filesError = "JSON parse failed"
                root.files = []
            }
            root.bump()
        }
    }

    Process {
        id: scanProc
        property string _stdout: ""
        command: ["python3", Quickshell.shellPath("scripts/scan-desktop-apps.py")]
        function execScan() {
            _stdout = ""
            running = false
            running = true
        }
        stdout: StdioCollector {
            onStreamFinished: scanProc._stdout = String(text)
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const err = String(text).trim()
                if (err.length)
                    root.lastError = err.slice(0, 160)
            }
        }
        onExited: (exitCode) => {
            root.loading = false
            const raw = scanProc._stdout.trim()
            if (exitCode !== 0 && !raw.length) {
                root.lastError = root.lastError || ("scan exit " + exitCode)
                root.bump()
                return
            }
            if (!raw.length) {
                root.lastError = "empty scan output"
                root.apps = []
                root.bump()
                return
            }
            try {
                const parsed = JSON.parse(raw)
                root.apps = Array.isArray(parsed) ? parsed : []
                root.lastError = root.apps.length ? "" : "0 apps parsed"
            } catch (e) {
                root.lastError = "JSON parse failed"
                root.apps = []
            }
            root.bump()
        }
    }
}