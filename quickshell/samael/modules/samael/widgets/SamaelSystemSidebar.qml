import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Caelestia.Config
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import qs
import qs.components
import qs.components.controls as PerfControls
import qs.services
import qs.modules.samael
import qs.modules.samael.widgets
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

Item {
    id: root
    focus: true

    /** Bar performance drop: only top processes + audio (Caelestia perf is sibling). */
    property bool performanceDropMode: false

    readonly property int panelWidth: performanceDropMode ? width : 460

    /** Readable on dark m3surfaceContainer in performance drop (Wallust, not dark m3onSurface). */
    readonly property color performanceDropText: WallustColors.foreground
    readonly property color performanceDropMuted: Qt.rgba(0.72, 0.8, 0.92, 0.85)

    function procRankAccent(rank: int): color {
        if (!performanceDropMode)
            return rank === 0 ? "#ef4444" : (rank === 1 ? "#3b82f6" : "#14b8a6")
        if (rank === 0)
            return Colours.palette.m3error
        if (rank === 1)
            return Colours.palette.m3primary
        return Colours.palette.m3tertiary
    }

    property var focusRows: []
    property int focusIndex: 0

    property bool devicePickerOpen: false
    property string devicePickerMode: "" // "out" | "in"
    property int devicePickerIndex: 0

    readonly property real maxPanelHeight: {
        const screens = Quickshell.screens
        if (!screens || screens.length === 0)
            return 920
        const sh = screens[0].height
        const top = Appearance.sizes.barHeight + Appearance.sizes.hyprlandGapsOut + 8
        return Math.max(480, sh - top - Appearance.sizes.hyprlandGapsOut - 20)
    }

            function closeMenu() {
                devicePickerOpen = false
                if (performanceDropMode)
                    GlobalStates.samaelPerformanceDropOpen = false
                else
                    GlobalStates.samaelSystemSidebarOpen = false
            }

        function pickerDeviceList() {
            return devicePickerMode === "in" ? Audio.inputDevices : Audio.outputDevices
        }

        function openDevicePicker(mode) {
            const list = mode === "in" ? Audio.inputDevices : Audio.outputDevices
            if (!list || list.length === 0)
                return
            devicePickerMode = mode
            const current = mode === "in" ? Audio.source : Audio.sink
            let idx = 0
            for (let i = 0; i < list.length; i++) {
                if (list[i] === current) {
                    idx = i
                    break
                }
            }
            devicePickerIndex = idx
            devicePickerOpen = true
        }

        function closeDevicePicker() {
            devicePickerOpen = false
            devicePickerMode = ""
        }

        function confirmDevicePicker() {
            const list = pickerDeviceList()
            if (!devicePickerOpen || devicePickerIndex < 0 || devicePickerIndex >= list.length)
                return
            const node = list[devicePickerIndex]
            if (devicePickerMode === "in")
                Audio.setDefaultSource(node)
            else
                Audio.setDefaultSink(node)
            closeDevicePicker()
        }

        function vimMovePicker(delta) {
            const list = pickerDeviceList()
            const n = list.length
            if (n === 0)
                return
            devicePickerIndex = (devicePickerIndex + delta + n) % n
        }

    function fmtTemp() {
        if (isNaN(SamaelSystemMonitor.temperatureC))
            return "—"
        return SamaelSystemMonitor.temperatureC.toFixed(0) + "°C"
    }

    function fmtMem() {
        const used = (SamaelSystemMonitor.memUsedKb / (1024 * 1024)).toFixed(1)
        const total = (SamaelSystemMonitor.memTotalKb / (1024 * 1024)).toFixed(0)
        return used + " / " + total + " GB"
    }

    function fmtDisk() {
        if (!SamaelSystemMonitor.diskUsed) return ""
        return SamaelSystemMonitor.diskUsed + " / " + SamaelSystemMonitor.diskTotal
    }

        implicitWidth: panelWidth
            readonly property real dropModeMaxHeight: Math.min(maxPanelHeight, 580)
            implicitHeight: performanceDropMode
                ? (scrollContent.implicitHeight > dropModeMaxHeight
                    ? dropModeMaxHeight
                    : scrollContent.implicitHeight + 20)
                : Math.min(maxPanelHeight, scrollContent.implicitHeight + 28)

    function rebuildFocusRows() {
        const rows = []
        const cpuProcs = SamaelSystemMonitor.topProcessesByCpu
        for (let i = 0; i < cpuProcs.length && i < 3; i++)
            rows.push({ kind: "procCpu", index: i })
        const memProcs = SamaelSystemMonitor.topProcessesByMem
        for (let i = 0; i < memProcs.length && i < 3; i++)
            rows.push({ kind: "procMem", index: i })
        rows.push({ kind: "audioOut" })
        rows.push({ kind: "audioIn" })
        const streamN = Math.min(3, Audio.outputAppNodes.length)
        for (let i = 0; i < streamN; i++)
            rows.push({ kind: "stream", index: i })
        focusRows = rows
        if (focusIndex >= focusRows.length)
            focusIndex = Math.max(0, focusRows.length - 1)
    }

    function currentFocusRow() {
        if (focusIndex < 0 || focusIndex >= focusRows.length)
            return null
        return focusRows[focusIndex]
    }

    function focusMatches(kind, index) {
        const row = currentFocusRow()
        if (!row || row.kind !== kind)
            return false
        if (index === undefined)
            return true
        return row.index === index
    }

        function focusIsProcess() {
            const row = currentFocusRow()
            return row && (row.kind === "procCpu" || row.kind === "procMem")
        }

            function vimMoveOutOfProcess(delta) {
                const n = focusRows.length
                if (n === 0)
                    return
                let i = focusIndex + delta
                while (i >= 0 && i < n) {
                    const k = focusRows[i].kind
                        if (k !== "procCpu" && k !== "procMem") {
                            focusIndex = i
                            if (root.performanceDropMode)
                                Qt.callLater(ensureFocusedRowVisible)
                            return
                        }
                    i += delta
                }
            }

            /** j/k within CPU or MEM column; at edge leaves process block (never CPU→MEM via j/k). */
            function vimMoveProcVertical(delta) {
                const row = currentFocusRow()
                if (!row || (row.kind !== "procCpu" && row.kind !== "procMem"))
                    return
                const ni = row.index + delta
                if (ni >= 0 && ni <= 2) {
                    for (let i = 0; i < focusRows.length; i++) {
                        const r = focusRows[i]
                            if (r.kind === row.kind && r.index === ni) {
                                focusIndex = i
                                if (root.performanceDropMode)
                                    Qt.callLater(ensureFocusedRowVisible)
                                return
                            }
                    }
                }
                vimMoveOutOfProcess(delta)
            }

            /** h/l: same row index, switch CPU ↔ MEMORY column. */
            function vimMoveProcAcrossColumns(toMem) {
                const row = currentFocusRow()
                if (!row || (row.kind !== "procCpu" && row.kind !== "procMem"))
                    return
                const targetKind = toMem ? "procMem" : "procCpu"
                for (let off = 0; off <= 2; off++) {
                    const candidates = off === 0 ? [row.index] : [row.index - off, row.index + off]
                    for (let c = 0; c < candidates.length; c++) {
                        const tryIndex = candidates[c]
                        if (tryIndex < 0 || tryIndex > 2)
                            continue
                        for (let i = 0; i < focusRows.length; i++) {
                            const r = focusRows[i]
                                if (r.kind === targetKind && r.index === tryIndex) {
                                    focusIndex = i
                                    if (root.performanceDropMode)
                                        Qt.callLater(ensureFocusedRowVisible)
                                    return
                                }
                        }
                    }
                }
            }

        function vimMove(delta) {
            const n = focusRows.length
            if (n === 0)
                return
            focusIndex = (focusIndex + delta + n) % n
        }

        function rowBlockHeight(kind) {
            if (kind === "procCpu" || kind === "procMem")
                return 46
            if (kind === "audioOut" || kind === "audioIn")
                return 78
            if (kind === "stream")
                return 84
            return 50
        }

        /** Cumulative Y in scrollContent for current focus row (drop). */
        function focusRowContentY() {
            if (!performanceDropMode)
                return focusIndex * 52
            const procCardH = 248
            const idx = focusIndex
            if (idx <= 5) {
                const rowInCol = idx % 3
                const col = idx < 3 ? 0 : 1
                return 44 + col * 118 + rowInCol * 46
            }
            if (idx === 6)
                return procCardH + Tokens.spacing.medium + 28
            if (idx === 7)
                return procCardH + Tokens.spacing.medium + 28 + 78
            return procCardH + Tokens.spacing.medium + 28 + 78 + 78 + 20 + (idx - 8) * 84
        }

        function ensureFocusedRowVisible() {
            if (!performanceDropMode || !sidebarFlick)
                return
            const maxY = Math.max(0, sidebarFlick.contentHeight - sidebarFlick.height)
            if (maxY <= 0)
                return
            const rowH = currentFocusRow()?.kind === "stream" ? 88 : 52
            const targetTop = Math.max(0, focusRowContentY())
            const idealY = targetTop - (sidebarFlick.height - rowH) * 0.35
            sidebarFlick.contentY = Math.max(0, Math.min(maxY, idealY))
        }

        function vimMoveWithScroll(delta) {
            vimMove(delta)
            Qt.callLater(ensureFocusedRowVisible)
        }

        function vimMoveProcVerticalWithScroll(delta) {
            vimMoveProcVertical(delta)
            Qt.callLater(ensureFocusedRowVisible)
        }

    function adjustFocusedVolume(delta) {
        const row = currentFocusRow()
        if (!row)
            return
        const step = 0.05
        if (row.kind === "audioOut" && Audio.sink?.audio) {
            Audio.sink.audio.volume = Math.max(0, Math.min(1, Audio.sink.audio.volume + delta * step))
            return
        }
        if (row.kind === "audioIn" && Audio.source?.audio) {
            Audio.source.audio.volume = Math.max(0, Math.min(1, Audio.source.audio.volume + delta * step))
            return
        }
        if (row.kind === "stream") {
            const node = Audio.outputAppNodes[row.index]
            if (node)
                setStreamVolume(node, streamVolume(node) + delta * step)
        }
    }

    function toggleFocusedMute() {
        const row = currentFocusRow()
        if (!row)
            return
        if (row.kind === "audioOut") {
            Audio.toggleMute()
            return
        }
        if (row.kind === "audioIn") {
            Audio.toggleMicMute()
            return
        }
        if (row.kind === "stream") {
            const node = Audio.outputAppNodes[row.index]
            if (node?.audio)
                node.audio.muted = !node.audio.muted
        }
    }

        function killFocusedProcess() {
            const row = currentFocusRow()
            if (!row || (row.kind !== "procCpu" && row.kind !== "procMem"))
                return
            const list = row.kind === "procCpu"
                ? SamaelSystemMonitor.topProcessesByCpu
                : SamaelSystemMonitor.topProcessesByMem
            if (row.index >= list.length)
                return
            const pid = list[row.index].pid
            if (pid > 0)
                Quickshell.execDetached(["kill", "-TERM", String(pid)])
        }

        function mprisForStream(node) {
            if (!node)
                return null
            const app = (Audio.appNodeDisplayName(node) || "").toLowerCase()
            const players = MprisController.players
            for (let i = 0; i < players.length; i++) {
                const p = players[i]
                const dbus = (p.dbusName || "").toLowerCase()
                const identity = (p.identity || "").toLowerCase()
                const de = (p.desktopEntry || "").toLowerCase().replace(".desktop", "")
                if (app.includes("firefox") && dbus.includes("firefox"))
                    return p
                if ((app.includes("zen") || app.includes("firefox")) && dbus.includes("firefox"))
                    return p
                if ((app.includes("chromium") || app.includes("brave") || app.includes("chrome"))
                        && (dbus.includes("chromium") || dbus.includes("chrome")))
                    return p
                if (app.includes("spotify") && dbus.includes("spotify"))
                    return p
                if (app.includes("vlc") && dbus.includes("vlc"))
                    return p
                if (identity.length > 2 && (app.includes(identity) || identity.includes(app)))
                    return p
                if (de.length > 2 && (app.includes(de) || de.includes(app)))
                    return p
            }
            if (players.length === 1)
                return players[0]
            return null
        }

        function streamVolume(node) {
            const m = mprisForStream(node)
            if (m && m.volumeSupported && m.canControl)
                return m.volume
            return node?.audio?.volume ?? 0
        }

        function setStreamVolume(node, value) {
            const v = Math.max(0, Math.min(1, value))
            const m = mprisForStream(node)
            if (m && m.volumeSupported && m.canControl)
                m.volume = v
            if (node?.audio)
                node.audio.volume = v
        }

        function focusedStreamNode() {
            const row = currentFocusRow()
            if (!row || row.kind !== "stream")
                return null
            return Audio.outputAppNodes[row.index] ?? null
        }

        function focusedStreamMpris() {
            return mprisForStream(focusedStreamNode())
        }

        function toggleFocusedStreamPlay() {
            const m = focusedStreamMpris()
            if (m && m.canControl)
                m.togglePlaying()
        }

        function focusedStreamPrevious() {
            const m = focusedStreamMpris()
            if (m?.canGoPrevious)
                m.previous()
        }

        function focusedStreamNext() {
            const m = focusedStreamMpris()
            if (m?.canGoNext)
                m.next()
        }

        function streamIdentityDiffersFromApp(identity, app) {
            const a = (app || "").toLowerCase().trim()
            const i = (identity || "").toLowerCase().trim()
            if (!i.length)
                return false
            if (i === a)
                return false
            if (a.includes(i) || i.includes(a))
                return false
            const browserish = /firefox|zen|chromium|chrome|brave|vivaldi|edge/
            if (browserish.test(i))
                return false
            return true
        }

        /** Same idea as bar MediaWidget + ii volume mixer media.name per stream. */
        function streamDisplayLabel(node) {
            if (!node)
                return ""
            const app = Audio.appNodeDisplayName(node)
            const media = Audio.streamMediaName(node)
            const player = mprisForStream(node)
            if (player) {
                const identity = (player.identity || "").trim()
                const title = StringUtils.cleanMusicTitle(player.trackTitle)
                const artist = (player.trackArtist || "").trim()
                const trackLine = title.length
                    ? title + (artist.length ? " • " + artist : "")
                    : ""
                if (streamIdentityDiffersFromApp(identity, app)) {
                    if (trackLine.length)
                        return identity + " • " + trackLine
                    return identity
                }
                if (trackLine.length)
                    return trackLine
                if (media.length)
                    return media
            }
            if (media.length && media.toLowerCase() !== app.toLowerCase())
                return app + " • " + media
            return app
        }

    Rectangle {
        anchors.fill: parent
        radius: performanceDropMode ? 0 : 16
        color: performanceDropMode ? "transparent" : SamaelStyle.menuPanelFill
        border.width: performanceDropMode ? 0 : 1
        border.color: Qt.rgba(0.18, 0.22, 0.30, 0.9)

            Flickable {
                id: sidebarFlick
                anchors.fill: parent
                anchors.margins: performanceDropMode ? 10 : 14
                clip: true
                interactive: true
                boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.VerticalFlick
                    contentHeight: scrollContent.implicitHeight
                        + (root.performanceDropMode ? Tokens.padding.large : 0)
                    contentWidth: width
                    ScrollBar.vertical: ScrollBar {
                        visible: root.performanceDropMode && sidebarFlick.contentHeight > sidebarFlick.height
                        policy: ScrollBar.AsNeeded
                    }

                    WheelHandler {
                        enabled: root.performanceDropMode
                        onWheel: event => {
                            const maxY = Math.max(0, sidebarFlick.contentHeight - sidebarFlick.height)
                            sidebarFlick.contentY = Math.max(0, Math.min(maxY,
                                sidebarFlick.contentY - event.angleDelta.y * 0.35))
                            event.accepted = true
                        }
                    }

                ColumnLayout {
                    id: scrollContent
                    width: parent.width
                    spacing: 12

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: !root.performanceDropMode

                Rectangle {
                    width: 22
                    height: 22
                    radius: 4
                    color: "#1793D1"

                    Text {
                        anchors.centerIn: parent
                        text: "\uF303"
                        color: "white"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                    }
                }

                Text {
                    text: "SYSTEM OVERVIEW"
                    color: "#e0e6f0"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "esc"
                    color: "#6b7280"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                }
            }

            // === CIRCULAR METRICS ===
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 14
                visible: !root.performanceDropMode

// CPU
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    Item {
                        implicitWidth: 94
                        implicitHeight: 94

                        CircularProgress {
                            anchors.centerIn: parent
                            implicitSize: 94
                            lineWidth: 9
                            value: SamaelSystemMonitor.cpuUsage
                            colPrimary: "#1a8cff"
                            colSecondary: Qt.rgba(0.12, 0.16, 0.24, 0.75)
                        }

                        Text {
                            anchors.centerIn: parent
                            text: Math.round(SamaelSystemMonitor.cpuUsage * 100) + "%"
                            color: "#1a8cff"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 22
                            font.bold: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "CPU UTILIZATION"
                            color: "#e0e6f0"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Text {
                            text: "Core • Current load"
                            color: "#8b95a8"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                        }
                    }
                }

// MEMORY
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    Item {
                        implicitWidth: 94
                        implicitHeight: 94

                        CircularProgress {
                            anchors.centerIn: parent
                            implicitSize: 94
                            lineWidth: 9
                            value: SamaelSystemMonitor.memUsedRatio
                            colPrimary: "#10b981"
                            colSecondary: Qt.rgba(0.08, 0.22, 0.17, 0.75)
                        }

                        Text {
                            anchors.centerIn: parent
                            text: Math.round(SamaelSystemMonitor.memUsedRatio * 100) + "%"
                            color: "#10b981"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 22
                            font.bold: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "MEMORY USAGE"
                            color: "#e0e6f0"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Text {
                            text: fmtMem()
                            color: "#8b95a8"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                        }
                    }
                }

// DISK
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    Item {
                        implicitWidth: 94
                        implicitHeight: 94

                        CircularProgress {
                            anchors.centerIn: parent
                            implicitSize: 94
                            lineWidth: 9
                            value: SamaelSystemMonitor.diskPct / 100
                            colPrimary: "#f59e0b"
                            colSecondary: Qt.rgba(0.28, 0.2, 0.08, 0.75)
                        }

                        Text {
                            anchors.centerIn: parent
                            text: SamaelSystemMonitor.diskPct + "%"
                            color: "#f59e0b"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 22
                            font.bold: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "DISK USAGE"
                            color: "#e0e6f0"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Text {
                            text: fmtDisk() || "—"
                            color: "#8b95a8"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                        }
                    }
                }

// TEMPERATURES
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    Item {
                        implicitWidth: 94
                        implicitHeight: 94

                        CircularProgress {
                            anchors.centerIn: parent
                            implicitSize: 94
                            lineWidth: 9
                            value: Math.min(1, (SamaelSystemMonitor.temperatureC || 40) / 95)
                            colPrimary: (SamaelSystemMonitor.temperatureCritical ? "#ef4444" : "#f97316")
                            colSecondary: Qt.rgba(0.32, 0.12, 0.08, 0.75)
                        }

                        Text {
                            anchors.centerIn: parent
                            text: fmtTemp()
                            color: (SamaelSystemMonitor.temperatureCritical ? "#ef4444" : "#f97316")
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 22
                            font.bold: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "TEMPERATURES"
                            color: "#e0e6f0"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Text {
                            text: "CPU: " + fmtTemp()
                            color: "#8b95a8"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                        }
                        Text {
                            text: "GPU: —"
                            color: "#8b95a8"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(0.25, 0.28, 0.35, 0.6)
            }

                // === TOP PROCESSES: CPU | MEMORY ===
                StyledRect {
                    Layout.fillWidth: true
                    visible: root.performanceDropMode
                    color: Colours.tPalette.m3surfaceContainer
                    radius: Tokens.rounding.extraLarge
                    implicitHeight: procDropInner.implicitHeight + Tokens.padding.large * 2
                    height: implicitHeight

                    ColumnLayout {
                        id: procDropInner
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.large
                        spacing: Tokens.spacing.medium

                        StyledText {
                            text: qsTr("Top processes")
                            font: Tokens.font.title.small
                            color: root.performanceDropText
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.medium

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.small

                                StyledText {
                                    text: qsTr("CPU")
                                    font: Tokens.font.label.medium
                                    color: WallustColors.sky
                                }

                                Repeater {
                                    model: SamaelSystemMonitor.topProcessesByCpu
                                    delegate: RowLayout {
                                        required property int index
                                        required property var modelData
                                        Layout.fillWidth: true
                                        spacing: Tokens.spacing.small

                                        Rectangle {
                                            width: 3
                                            Layout.preferredHeight: procCpuDropCol.implicitHeight
                                            radius: 1
                                            visible: root.focusMatches("procCpu", index)
                                            color: Colours.palette.m3primary
                                        }

                                        ColumnLayout {
                                            id: procCpuDropCol
                                            Layout.fillWidth: true
                                            spacing: 2

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: Tokens.spacing.extraSmall

                                                StyledText {
                                                    Layout.fillWidth: true
                                                    text: modelData.name
                                                    elide: Text.ElideRight
                                                    font: Tokens.font.body.medium
                                                    color: root.performanceDropText
                                                }
                                                StyledText {
                                                    text: modelData.cpu.toFixed(0) + "%"
                                                    font: Tokens.font.label.large
                                                    color: procRankAccent(index)
                                                }
                                            }

                                            SamaelPerformanceProcWaveBar {
                                                Layout.fillWidth: true
                                                fraction: Math.min(1, modelData.cpu / 100)
                                                fgColour: procRankAccent(index)
                                            }
                                        }
                                    }
                                }

                                StyledText {
                                    visible: SamaelSystemMonitor.topProcessesByCpu.length === 0
                                    text: "…"
                                    font: Tokens.font.body.small
                                    color: root.performanceDropMuted
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 1
                                Layout.fillHeight: true
                                color: Qt.alpha(Colours.palette.m3outline, 0.35)
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.small

                                StyledText {
                                    text: qsTr("Memory")
                                    font: Tokens.font.label.medium
                                    color: WallustColors.mauve
                                }

                                Repeater {
                                    model: SamaelSystemMonitor.topProcessesByMem
                                    delegate: RowLayout {
                                        required property int index
                                        required property var modelData
                                        Layout.fillWidth: true
                                        spacing: Tokens.spacing.small

                                        Rectangle {
                                            width: 3
                                            Layout.preferredHeight: procMemDropCol.implicitHeight
                                            radius: 1
                                            visible: root.focusMatches("procMem", index)
                                            color: Colours.palette.m3secondary
                                        }

                                        ColumnLayout {
                                            id: procMemDropCol
                                            Layout.fillWidth: true
                                            spacing: 2

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: Tokens.spacing.extraSmall

                                                StyledText {
                                                    Layout.fillWidth: true
                                                    text: modelData.name
                                                    elide: Text.ElideRight
                                                    font: Tokens.font.body.medium
                                                    color: root.performanceDropText
                                                }
                                                StyledText {
                                                    text: modelData.mem.toFixed(1) + "%"
                                                    font: Tokens.font.label.large
                                                    color: procRankAccent(index)
                                                }
                                            }

                                            SamaelPerformanceProcWaveBar {
                                                Layout.fillWidth: true
                                                fraction: Math.min(1, modelData.mem / 100)
                                                fgColour: procRankAccent(index)
                                            }
                                        }
                                    }
                                }

                                StyledText {
                                    visible: SamaelSystemMonitor.topProcessesByMem.length === 0
                                    text: "…"
                                    font: Tokens.font.body.small
                                    color: root.performanceDropMuted
                                }
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            text: qsTr("CPU: top 3 by %CPU. MEM: top 3 by %RAM. x kills focused row.")
                            font: Tokens.font.body.small
                            color: root.performanceDropMuted
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: !root.performanceDropMode

                    Text {
                        text: "TOP PROCESSES"
                        color: "#a0aec0"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                    }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: "CPU"
                            color: "#1a8cff"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.bold: true
                        }

                        Repeater {
                            model: SamaelSystemMonitor.topProcessesByCpu
                            delegate: RowLayout {
                                required property int index
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 6

                                Rectangle {
                                    width: 3
                                    Layout.preferredHeight: procCpuCol.implicitHeight
                                    radius: 1
                                    visible: root.focusMatches("procCpu", index)
                                    color: "#1a8cff"
                                }

                                ColumnLayout {
                                    id: procCpuCol
                                    Layout.fillWidth: true
                                    spacing: 2

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 4
                                        Rectangle {
width: 6
height: 6
radius: 2
color: index === 0 ? "#ef4444" : (index === 1 ? "#3b82f6" : "#14b8a6")
                                        }
                                        Text {
Layout.fillWidth: true
text: modelData.name
elide: Text.ElideRight
color: "#e0e6f0"
font.family: "JetBrainsMono Nerd Font"
font.pixelSize: 14
                                        }
                                        Text {
text: modelData.cpu.toFixed(0) + "%"
color: "#1a8cff"
font.family: "JetBrainsMono Nerd Font"
font.pixelSize: 12
font.bold: true
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 4
                                        radius: 2
                                        color: Qt.rgba(0.12, 0.14, 0.18, 1)
                                        Rectangle {
width: parent.width * Math.min(1, modelData.cpu / 100)
height: parent.height
radius: 2
color: index === 0 ? "#ef4444" : (index === 1 ? "#3b82f6" : "#14b8a6")
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            visible: SamaelSystemMonitor.topProcessesByCpu.length === 0
                            text: "…"
                            color: "#6b7280"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        color: Qt.rgba(0.25, 0.28, 0.35, 0.5)
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: "MEMORY"
                            color: "#a855f7"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.bold: true
                        }

                        Repeater {
                            model: SamaelSystemMonitor.topProcessesByMem
                            delegate: RowLayout {
                                required property int index
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 6

                                Rectangle {
                                    width: 3
                                    Layout.preferredHeight: procMemCol.implicitHeight
                                    radius: 1
                                    visible: root.focusMatches("procMem", index)
                                    color: "#a855f7"
                                }

                                ColumnLayout {
                                    id: procMemCol
                                    Layout.fillWidth: true
                                    spacing: 2

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 4
                                        Rectangle {
width: 6
height: 6
radius: 2
color: index === 0 ? "#ef4444" : (index === 1 ? "#3b82f6" : "#14b8a6")
                                        }
                                        Text {
Layout.fillWidth: true
text: modelData.name
elide: Text.ElideRight
color: "#e0e6f0"
font.family: "JetBrainsMono Nerd Font"
font.pixelSize: 14
                                        }
                                        Text {
text: modelData.mem.toFixed(1) + "%"
color: "#a855f7"
font.family: "JetBrainsMono Nerd Font"
font.pixelSize: 12
font.bold: true
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 4
                                        radius: 2
                                        color: Qt.rgba(0.12, 0.14, 0.18, 1)
                                        Rectangle {
width: parent.width * Math.min(1, modelData.mem / 100)
height: parent.height
radius: 2
color: index === 0 ? "#ef4444" : (index === 1 ? "#3b82f6" : "#14b8a6")
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            visible: SamaelSystemMonitor.topProcessesByMem.length === 0
                            text: "…"
                            color: "#6b7280"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: "CPU: top 3 by process %CPU (can exceed 100% on multi-core). MEM: top 3 by % of total RAM. x kills focused row."
                    color: "#475569"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 7
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                visible: !root.performanceDropMode
                color: Qt.rgba(0.25, 0.28, 0.35, 0.6)
            }

            // === AUDIO MANAGER ===
            Item {
                Layout.fillWidth: true
                implicitHeight: audioManagerCol.implicitHeight
                    + (root.performanceDropMode ? Tokens.padding.large * 2 : 0)
                height: implicitHeight

                StyledRect {
                    visible: root.performanceDropMode
                    anchors.fill: parent
                    color: Colours.tPalette.m3surfaceContainer
                    radius: Tokens.rounding.extraLarge
                }

            ColumnLayout {
                id: audioManagerCol
                anchors.fill: parent
                anchors.margins: root.performanceDropMode ? Tokens.padding.large : 0
                spacing: root.performanceDropMode ? Tokens.spacing.medium : 10

                    StyledText {
                        visible: root.performanceDropMode
                        text: qsTr("Audio")
                        font: Tokens.font.title.small
                        color: root.performanceDropText
                    }

                    Text {
                        visible: !root.performanceDropMode
                        text: "AUDIO MANAGER"
                        color: "#a0aec0"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                    }

                    ColumnLayout {
                        visible: root.devicePickerOpen
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: devicePickerMode === "in" ? "SELECT INPUT" : "SELECT OUTPUT"
                            color: "#1a8cff"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            font.bold: true
                        }

                        Repeater {
                            model: root.devicePickerOpen ? root.pickerDeviceList() : []
                            delegate: RowLayout {
                                required property int index
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 6

                                Rectangle {
                                    width: 3
                                    height: 18
                                    radius: 1
                                    visible: root.devicePickerOpen && root.devicePickerIndex === index
                                    color: "#1a8cff"
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: Audio.friendlyDeviceName(modelData)
                                    elide: Text.ElideRight
                                    color: root.devicePickerIndex === index ? "#e0e6f0" : "#94a3b8"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12
                                }

                                Text {
                                    visible: (root.devicePickerMode === "in" ? Audio.source : Audio.sink) === modelData
                                    text: "●"
                                    color: "#10b981"
                                    font.pixelSize: 10
                                }

                                MouseArea {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: 22
                                    onClicked: {
                                        root.devicePickerIndex = index
                                        root.confirmDevicePicker()
                                    }
                                }
                            }
                        }

                        Text {
                            text: "j/k device · Enter apply · Esc cancel"
                            color: "#475569"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 8
                        }
                    }

                    // --- OUTPUTS ---
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        StyledText {
                            visible: root.performanceDropMode
                            text: qsTr("Outputs")
                            font: Tokens.font.label.medium
                            color: root.performanceDropMuted
                        }
                        Text {
                            visible: !root.performanceDropMode
                            text: "OUTPUTS"
                            color: "#64748b"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                            font.bold: true
                        }
                        StyledText {
                            visible: root.performanceDropMode
                            text: qsTr("Active")
                            font: Tokens.font.label.small
                            color: Colours.palette.m3tertiary
                        }
                        Text {
                            visible: !root.performanceDropMode
                            text: "(Active)"
                            color: "#10b981"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Rectangle {
                            width: 3
                            height: 20
                            radius: 1
                            visible: root.focusMatches("audioOut") && !root.devicePickerOpen
                            color: "#1a8cff"
                        }
                        Text {
                            text: ""
                            color: "#e0e6f0"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                        }
                        MouseArea {
                            Layout.fillWidth: true
                            implicitHeight: 22
                            hoverEnabled: true
                            onClicked: root.openDevicePicker("out")
                            Text {
                                width: parent.width
                                text: Audio.friendlyDeviceName(Audio.sink) || "Headphones"
                                elide: Text.ElideRight
                                    color: root.performanceDropMode
                                        ? (root.focusMatches("audioOut") ? root.performanceDropText : root.performanceDropMuted)
                                        : (root.focusMatches("audioOut") ? "#e0e6f0" : "#cbd5e1")
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                        Text {
                            visible: root.focusMatches("audioOut") && !root.devicePickerOpen
                            text: "⏎"
                            color: "#64748b"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                        }
                        MouseArea {
                            implicitWidth: 18
                            implicitHeight: 18
                            onClicked: Audio.toggleMute()
                            Text {
                                anchors.centerIn: parent
                                text: (Audio.sink?.audio?.muted ?? false) ? "" : ""
                                color: (Audio.sink?.audio?.muted ?? false) ? "#ef4444" : "#10b981"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.performanceDropMode ? 28 : 36

                        Rectangle {
                            visible: !root.performanceDropMode
                            anchors.fill: parent
                            radius: 6
                            color: root.focusMatches("audioOut") ? Qt.rgba(0.1, 0.14, 0.22, 0.9) : "transparent"
                            border.width: root.focusMatches("audioOut") ? 1 : 0
                            border.color: "#1a8cff"
                        }
PerfControls.StyledSlider {
                            id: outSliderDrop
                            visible: root.performanceDropMode
                            anchors.fill: parent
                            from: 0
                            to: 1
                            stepSize: 0.01
                            wavy: true
                            animateWave: true
                            value: Audio.sink?.audio?.volume ?? 0
                            fgColour: Colours.palette.m3primary
                            bgColour: Colours.palette.m3secondaryContainer
                            onMoved: {
                                if (Audio.sink?.audio)
                                    Audio.sink.audio.volume = value
                            }
                        }
                        Slider {
                            id: outSlider
                            visible: !root.performanceDropMode
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            from: 0
                            to: 1
                            stepSize: 0.01
                            value: Audio.sink?.audio?.volume ?? 0
                            onMoved: {
                                if (Audio.sink?.audio)
                                    Audio.sink.audio.volume = value
                            }
                        }
                    }
                }

                // --- INPUTS ---
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        StyledText {
                            visible: root.performanceDropMode
                            text: qsTr("Inputs")
                            font: Tokens.font.label.medium
                            color: root.performanceDropMuted
                        }
                        Text {
                            visible: !root.performanceDropMode
                            text: "INPUTS"
                            color: "#64748b"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                            font.bold: true
                        }
                        StyledText {
                            visible: root.performanceDropMode
                            text: qsTr("Active")
                            font: Tokens.font.label.small
                            color: Colours.palette.m3tertiary
                        }
                        Text {
                            visible: !root.performanceDropMode
                            text: "(Active)"
                            color: "#10b981"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Rectangle {
                            width: 3
                            height: 20
                            radius: 1
                            visible: root.focusMatches("audioIn") && !root.devicePickerOpen
                            color: "#1a8cff"
                        }
                        Text {
                            text: ""
                            color: "#e0e6f0"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                        }
                        MouseArea {
                            Layout.fillWidth: true
                            implicitHeight: 22
                            hoverEnabled: true
                            onClicked: root.openDevicePicker("in")
                            Text {
                                width: parent.width
                                    text: Audio.friendlyDeviceName(Audio.source) || "Microphone"
                                    elide: Text.ElideRight
                                    color: root.performanceDropMode
                                        ? (root.focusMatches("audioIn") ? root.performanceDropText : root.performanceDropMuted)
                                        : (root.focusMatches("audioIn") ? "#e0e6f0" : "#cbd5e1")
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                        Text {
                            visible: root.focusMatches("audioIn") && !root.devicePickerOpen
                            text: "⏎"
                            color: "#64748b"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                        }
                        MouseArea {
                            implicitWidth: 18
                            implicitHeight: 18
                            onClicked: Audio.toggleMicMute()
                            Text {
                                anchors.centerIn: parent
                                text: (Audio.source?.audio?.muted ?? false) ? "" : ""
                                color: (Audio.source?.audio?.muted ?? false) ? "#ef4444" : "#10b981"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.performanceDropMode ? 28 : 36

                        Rectangle {
                            visible: !root.performanceDropMode
                            anchors.fill: parent
                            radius: 6
                            color: root.focusMatches("audioIn") ? Qt.rgba(0.1, 0.14, 0.22, 0.9) : "transparent"
                            border.width: root.focusMatches("audioIn") ? 1 : 0
                            border.color: "#1a8cff"
                        }
PerfControls.StyledSlider {
                            id: inSliderDrop
                            visible: root.performanceDropMode
                            anchors.fill: parent
                            from: 0
                            to: 1
                            stepSize: 0.01
                            wavy: true
                            animateWave: true
                            value: Audio.source?.audio?.volume ?? 0
                            fgColour: Colours.palette.m3primary
                            bgColour: Colours.palette.m3secondaryContainer
                            onMoved: {
                                if (Audio.source?.audio)
                                    Audio.source.audio.volume = value
                            }
                        }
                        Slider {
                            id: inSlider
                            visible: !root.performanceDropMode
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            from: 0
                            to: 1
                            stepSize: 0.01
                            value: Audio.source?.audio?.volume ?? 0
                            onMoved: {
                                if (Audio.source?.audio)
                                    Audio.source.audio.volume = value
                            }
                        }
                    }
                }

                // --- App streams ---
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: Audio.outputAppNodes.length > 0

                    StyledText {
                        visible: root.performanceDropMode
                        text: qsTr("Streams")
                        font: Tokens.font.label.medium
                        color: root.performanceDropMuted
                    }
                    Text {
                        visible: !root.performanceDropMode
                        text: "STREAMS"
                        color: "#64748b"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 9
                        font.bold: true
                    }

                    Repeater {
                        model: Math.min(3, Audio.outputAppNodes.length)
                        delegate: ColumnLayout {
                            required property int index
                            Layout.fillWidth: true
                            spacing: 4

                            property var node: Audio.outputAppNodes[index]
                            readonly property var mprisPlayer: root.mprisForStream(node)

                            PwObjectTracker {
                                objects: node ? [node] : []
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Rectangle {
                                    width: 3
                                    height: 14
                                    radius: 1
                                    visible: root.focusMatches("stream", index)
                                    color: "#1a8cff"
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: node ? root.streamDisplayLabel(node) : ""
                                    elide: Text.ElideRight
                                        color: root.performanceDropMode
                                            ? (root.focusMatches("stream", index) ? root.performanceDropText : root.performanceDropMuted)
                                            : (root.focusMatches("stream", index) ? "#e0e6f0" : "#94a3b8")
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12
                                    verticalAlignment: Text.AlignVCenter
                                }
                                Text {
                                    text: node ? Math.round(root.streamVolume(node) * 100) + "%" : ""
                                    color: root.performanceDropMode ? root.performanceDropMuted : "#64748b"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Item {
                                    visible: mprisPlayer !== null
                                    Layout.alignment: Qt.AlignVCenter
                                    implicitWidth: streamMediaBtn.width
                                    implicitHeight: streamMediaBtn.height
                                    Text {
                                        id: streamMediaBtn
                                        anchors.centerIn: parent
                                        text: (mprisPlayer?.isPlaying ?? false) ? "󰏦" : "󰎈"
                                        color: "#10b981"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 13
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -4
                                        hoverEnabled: true
                                        onClicked: {
                                            if (mprisPlayer?.canControl)
                                                mprisPlayer.togglePlaying()
                                        }
                                    }
                                }

                                Item {
                                    visible: mprisPlayer?.canGoPrevious ?? false
                                    Layout.alignment: Qt.AlignVCenter
                                    implicitWidth: streamPrevBtn.width
                                    implicitHeight: streamPrevBtn.height
                                    Text {
                                        id: streamPrevBtn
                                        anchors.centerIn: parent
                                        text: "󰒮"
                                        color: "#94a3b8"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 13
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -4
                                        hoverEnabled: true
                                        onClicked: mprisPlayer?.previous()
                                    }
                                }

                                Item {
                                    visible: mprisPlayer?.canGoNext ?? false
                                    Layout.alignment: Qt.AlignVCenter
                                    implicitWidth: streamNextBtn.width
                                    implicitHeight: streamNextBtn.height
                                    Text {
                                        id: streamNextBtn
                                        anchors.centerIn: parent
                                        text: "󰒭"
                                        color: "#94a3b8"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 13
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -4
                                        hoverEnabled: true
                                        onClicked: mprisPlayer?.next()
                                    }
                                }
                            }

                            PerfControls.StyledSlider {
                                id: streamSliderDrop
                                visible: root.performanceDropMode
                                Layout.fillWidth: true
                                Layout.preferredHeight: 24
                                from: 0
                                to: 1
                                stepSize: 0.01
                                wavy: true
                                animateWave: true
                                value: node ? root.streamVolume(node) : 0
                                fgColour: Colours.palette.m3primary
                                bgColour: Colours.palette.m3secondaryContainer
                                onMoved: {
                                    if (node)
                                        root.setStreamVolume(node, value)
                                }
                            }

                            Slider {
                                id: streamSlider
                                visible: !root.performanceDropMode
                                Layout.fillWidth: true
                                Layout.preferredHeight: 32
                                from: 0
                                to: 1
                                stepSize: 0.01
                                value: node ? root.streamVolume(node) : 0
                                onMoved: {
                                    if (node)
                                        root.setStreamVolume(node, value)
                                }
                            }

                            Connections {
                                target: node?.audio ?? null
                                function onVolumeChanged() {
                                    if (node && !streamSlider.pressed && !streamSliderDrop.dragging) {
                                        const v = root.streamVolume(node)
                                        streamSlider.value = v
                                        streamSliderDrop.value = v
                                    }
                                }
                            }
                        }
                    }
                }

                StyledText {
                    visible: root.performanceDropMode
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    wrapMode: Text.WordWrap
                    text: qsTr("j/k move · h/l vol · Enter device · m mute · x kill · wheel scroll")
                    font: Tokens.font.body.small
                    color: root.performanceDropMuted
                }
                Text {
                    visible: !root.performanceDropMode
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    wrapMode: Text.WordWrap
                    text: "proc: j/k · h/l CPU|MEM · audio: j/k · h/l vol · Enter device · m mute · x kill · Esc"
                    color: "#475569"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 8
                }
                    }
                }
            }
        }
    }

        Connections {
            target: Audio.sink?.audio
        function onVolumeChanged() {
            const v = Audio.sink?.audio?.volume ?? 0
            if (!outSlider.pressed && !outSliderDrop.dragging) {
                outSlider.value = v
                outSliderDrop.value = v
            }
        }
    }
    Connections {
        target: Audio.source?.audio
        function onVolumeChanged() {
            const v = Audio.source?.audio?.volume ?? 0
            if (!inSlider.pressed && !inSliderDrop.dragging) {
                inSlider.value = v
                inSliderDrop.value = v
            }
        }
    }

    Component.onCompleted: rebuildFocusRows()

    Connections {
        target: SamaelSystemMonitor
        function onTopProcessesByCpuChanged() { root.rebuildFocusRows() }
        function onTopProcessesByMemChanged() { root.rebuildFocusRows() }
    }
    Timer {
        interval: 2000
        running: GlobalStates.samaelSystemSidebarOpen || GlobalStates.samaelPerformanceDropOpen
        repeat: true
        onTriggered: root.rebuildFocusRows()
    }

        Keys.onPressed: event => {
            const text = event.text
            if (event.key === Qt.Key_Escape) {
                if (root.devicePickerOpen) {
                    root.closeDevicePicker()
                    event.accepted = true
                    return
                }
                root.closeMenu()
                event.accepted = true
                return
            }
            if (root.devicePickerOpen) {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.confirmDevicePicker()
                    event.accepted = true
                    return
                }
                if (text === "j" || event.key === Qt.Key_Down) {
                    root.vimMovePicker(1)
                    event.accepted = true
                    return
                }
                if (text === "k" || event.key === Qt.Key_Up) {
                    root.vimMovePicker(-1)
                    event.accepted = true
                    return
                }
                return
            }
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                const row = root.currentFocusRow()
                if (row?.kind === "audioOut") {
                    root.openDevicePicker("out")
                    event.accepted = true
                    return
                }
                if (row?.kind === "audioIn") {
                    root.openDevicePicker("in")
                    event.accepted = true
                    return
                }
            }
                if (text === "j" || event.key === Qt.Key_Down) {
                    if (root.performanceDropMode) {
                        if (root.focusIsProcess())
                            vimMoveProcVerticalWithScroll(1)
                        else
                            vimMoveWithScroll(1)
                    } else {
                        if (root.focusIsProcess())
                            vimMoveProcVertical(1)
                        else
                            vimMove(1)
                    }
                    event.accepted = true
                    return
                }
                if (text === "k" || event.key === Qt.Key_Up) {
                    if (root.performanceDropMode) {
                        if (root.focusIsProcess())
                            vimMoveProcVerticalWithScroll(-1)
                        else
                            vimMoveWithScroll(-1)
                    } else {
                        if (root.focusIsProcess())
                            vimMoveProcVertical(-1)
                        else
                            vimMove(-1)
                    }
                    event.accepted = true
                    return
                }
            if (text === "h" || event.key === Qt.Key_Left) {
                if (root.focusIsProcess())
                    vimMoveProcAcrossColumns(false)
                else
                    adjustFocusedVolume(-1)
                if (root.performanceDropMode)
                    Qt.callLater(ensureFocusedRowVisible)
                event.accepted = true
                return
            }
            if (text === "l" || event.key === Qt.Key_Right) {
                if (root.focusIsProcess())
                    vimMoveProcAcrossColumns(true)
                else
                    adjustFocusedVolume(1)
                if (root.performanceDropMode)
                    Qt.callLater(ensureFocusedRowVisible)
                event.accepted = true
                return
            }
        if (text === "m") {
            toggleFocusedMute()
            event.accepted = true
            return
        }
        if (text === "x") {
            killFocusedProcess()
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Space) {
            toggleFocusedStreamPlay()
            event.accepted = true
            return
        }
        if (text === "," || text === "u") {
            focusedStreamPrevious()
            event.accepted = true
            return
        }
        if (text === "." || text === "i") {
            focusedStreamNext()
            event.accepted = true
            return
        }
    }

    Connections {
        target: GlobalStates
        function onSamaelSystemSidebarOpenChanged() {
            if (GlobalStates.samaelSystemSidebarOpen) {
                root.rebuildFocusRows()
                Qt.callLater(() => root.forceActiveFocus())
            }
        }
    }
}