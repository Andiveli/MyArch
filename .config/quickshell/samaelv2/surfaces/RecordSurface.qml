import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../singletons"
import "../widgets"


/** Left pill — screen record (gpu-screen-recorder via record-ctl.py). */
FocusScope {
    id: root

    property bool open: false
    property real morphCloseness: 1

    readonly property int _rev: RecordService.revision
    readonly property bool running: RecordService.running
    readonly property bool paused: RecordService.paused
    readonly property bool recorderOk: RecordService.recorderInstalled

    property int focusRow: 0
    property int focusCol: 0
    property bool micVolAdjust: false
    property bool sysVolAdjust: false

    readonly property var mainRowWidths: [4, 2, 2]

    function mainCellId(row, col) {
        if (row === 0) {
            const ids = ["record", "pause", "region", "config"]
            return ids[col] || ""
        }
        if (row === 1)
            return col === 0 ? "mic_mute" : "mic_vol"
        if (row === 2)
            return col === 0 ? "sys_mute" : "sys_vol"
        return ""
    }

    function isMainFocused(row, col) {
        if (RecordService.configOpen)
            return false
        return focusRow === row && focusCol === col
    }

    function clampMainFocus() {
        if (RecordService.configOpen)
            return
        const rw = mainRowWidths
        focusRow = Math.max(0, Math.min(rw.length - 1, focusRow))
        const w = rw[focusRow] || 1
        focusCol = Math.max(0, Math.min(w - 1, focusCol))
    }

    function moveMainH(delta) {
        if (focusRow === 1) {
            const v = RecordService.audioSource.volume + delta * 5
            RecordService.setSourceVolume(v)
            focusCol = 1
            return
        }
        if (focusRow === 2) {
            const v = RecordService.audioSink.volume + delta * 5
            RecordService.setSinkVolume(v)
            focusCol = 1
            return
        }
        const w = mainRowWidths[focusRow] || 1
        focusCol = Math.max(0, Math.min(w - 1, focusCol + delta))
    }

    function moveMainV(delta) {
        micVolAdjust = false
        sysVolAdjust = false
        const next = focusRow + delta
        if (next < 0 || next >= mainRowWidths.length)
            return
        focusRow = next
        const w = mainRowWidths[focusRow]
        if (focusRow === 1 || focusRow === 2)
            focusCol = 1
        else if (focusCol >= w)
            focusCol = w - 1
        clampMainFocus()
    }

    readonly property var configRows: {
        const _r = _rev
        const rows = [{ id: "path" }]
        rows.push({ id: "mode", chip: 0 }, { id: "mode", chip: 1 }, { id: "mode", chip: 2 })
        const mode = RecordService.recordConfig.mode || "monitor"
        const mons = RecordService.monitors || []
        const wins = RecordService.windows || []
        if (mode === "monitor") {
            for (let i = 0; i < mons.length; i++)
                rows.push({ id: "mon", index: i })
        } else if (mode === "window") {
            for (let i = 0; i < wins.length; i++)
                rows.push({ id: "win", index: i })
        }
        rows.push({ id: "inc_mic" }, { id: "inc_sys" })
        return rows
    }

    property int configFocusIndex: 0
    property string configFocusKey: "path"
    readonly property int configRowCount: configRows.length

    function configRowKey(row) {
        if (!row)
            return "path"
        if (row.id === "mode")
            return "mode:" + row.chip
        if (row.id === "mon")
            return "mon:" + row.index
        if (row.id === "win")
            return "win:" + row.index
        return row.id
    }

    function syncConfigFocusIndex() {
        const key = configFocusKey
        for (let i = 0; i < configRows.length; i++) {
            if (configRowKey(configRows[i]) === key) {
                configFocusIndex = i
                return
            }
        }
        configFocusIndex = Math.max(0, Math.min(configRowCount - 1, configFocusIndex))
        configFocusKey = configRowKey(configRows[configFocusIndex])
    }

    function clampConfigFocus() {
        configFocusIndex = Math.max(0, Math.min(configRowCount - 1, configFocusIndex))
        configFocusKey = configRowKey(configRows[configFocusIndex])
    }

    function focusedConfigRow() {
        if (configFocusIndex < 0 || configFocusIndex >= configRows.length)
            return null
        return configRows[configFocusIndex]
    }

    function isFocusedConfig(rowId, extra) {
        if (!RecordService.configOpen)
            return false
        const row = focusedConfigRow()
        if (!row || row.id !== rowId)
            return false
        if (rowId === "mode" && extra !== undefined)
            return row.chip === extra
        if (rowId === "mon" && extra !== undefined)
            return row.index === extra
        if (rowId === "win" && extra !== undefined)
            return row.index === extra
        return rowId === "path" || rowId === "inc_mic" || rowId === "inc_sys"
    }

    function activateMain() {
        const id = mainCellId(focusRow, focusCol)
        if (!id)
            return
        if (id === "mic_vol") {
            micVolAdjust = true
            return
        }
        if (id === "sys_vol") {
            sysVolAdjust = true
            return
        }
        micVolAdjust = false
        sysVolAdjust = false
        switch (id) {
        case "record":
            if (!recorderOk)
                return
            RecordService.toggleRecord()
            break
        case "pause":
            if (running)
                RecordService.togglePause()
            break
        case "region":
            if (!running && recorderOk) {
                ShellActions.closeLeftSurface?.()
                regionArmTimer.restart()
            }
            break
        case "config":
            RecordService.configOpen = true
            configFocusIndex = 0
            configFocusKey = "path"
            break
        case "mic_mute":
            RecordService.toggleSourceMute()
            break
        case "sys_mute":
            RecordService.toggleSinkMute()
            break
        }
    }

    function activateFocused() {
        if (RecordService.configOpen) {
            const row = focusedConfigRow()
            if (!row)
                return
            if (row.id === "path") {
                pathField.forceActiveFocus()
                return
            }
            if (row.id === "mode") {
                const modes = ["monitor", "region", "window"]
                RecordService.patchConfig({ mode: modes[row.chip] || "monitor" })
                return
            }
            if (row.id === "mon") {
                const m = RecordService.monitors[row.index]
                if (m)
                    RecordService.patchConfig({ mode: "monitor", monitor: m.name })
                return
            }
            if (row.id === "win") {
                const w = RecordService.windows[row.index]
                if (w)
                    RecordService.patchConfig({ mode: "window", windowAddress: w.address })
                return
            }
            if (row.id === "inc_mic") {
                RecordService.patchConfig({ includeMic: !RecordService.recordConfig.includeMic })
                return
            }
            if (row.id === "inc_sys") {
                const on = RecordService.recordConfig.includeSystemAudio !== false
                RecordService.patchConfig({ includeSystemAudio: !on })
            }
            return
        }
        activateMain()
    }

    implicitWidth: 380
    implicitHeight: RecordService.configOpen
        ? Math.min(420, column.implicitHeight + 16)
        : Math.min(248, column.implicitHeight + 16)

    opacity: open ? Math.pow(morphCloseness, 1.2) : 0
    visible: opacity > 0.02
    enabled: open
    focus: open

    onOpenChanged: {
        if (open) {
            focusRow = 0
            focusCol = 0
            micVolAdjust = false
            sysVolAdjust = false
            RecordService.refresh()
            Qt.callLater(forceActiveFocus)
        } else {
            RecordService.configOpen = false
            focusRow = 0
            focusCol = 0
        }
    }

    Connections {
        target: RecordService
        function onRevisionChanged() {
            if (RecordService.configOpen)
                root.syncConfigFocusIndex()
            else
                root.clampConfigFocus()
        }
        function onConfigOpenChanged() {
            if (RecordService.configOpen) {
                root.configFocusIndex = 0
                root.configFocusKey = "path"
            } else {
                root.focusRow = 0
                root.focusCol = 3
                root.clampMainFocus()
                Qt.callLater(() => root.forceActiveFocus())
            }
        }
    }

    Keys.onPressed: event => {
        if (!open)
            return
        if (pathField.activeFocus && event.key !== Qt.Key_Escape) {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                pathField.focus = false
                root.forceActiveFocus()
                event.accepted = true
            }
            return
        }
        const t = event.text
        if (event.key === Qt.Key_Escape) {
            if (pathField.activeFocus) {
                pathField.focus = false
                root.forceActiveFocus()
                event.accepted = true
                return
            }
            if (RecordService.configOpen) {
                RecordService.configOpen = false
                focusRow = 0
                focusCol = 3
                clampMainFocus()
                Qt.callLater(() => root.forceActiveFocus())
                event.accepted = true
                return
            }
            micVolAdjust = false
            sysVolAdjust = false
            ShellActions.closeLeftSurface?.()
            event.accepted = true
            return
        }
        if (RecordService.configOpen) {
            if (t === "j" || event.key === Qt.Key_Down) {
                configFocusIndex = Math.min(configRowCount - 1, configFocusIndex + 1)
                configFocusKey = configRowKey(configRows[configFocusIndex])
                event.accepted = true
                return
            }
            if (t === "k" || event.key === Qt.Key_Up) {
                configFocusIndex = Math.max(0, configFocusIndex - 1)
                configFocusKey = configRowKey(configRows[configFocusIndex])
                event.accepted = true
                return
            }
            if (t === "h" || event.key === Qt.Key_Left) {
                const row = focusedConfigRow()
                if (row && row.id === "mode" && row.chip > 0)
                    configFocusIndex--
                else
                    configFocusIndex = Math.max(0, configFocusIndex - 1)
                configFocusKey = configRowKey(configRows[configFocusIndex])
                event.accepted = true
                return
            }
            if (t === "l" || event.key === Qt.Key_Right) {
                const row = focusedConfigRow()
                if (row && row.id === "mode" && row.chip < 2)
                    configFocusIndex++
                else
                    configFocusIndex = Math.min(configRowCount - 1, configFocusIndex + 1)
                configFocusKey = configRowKey(configRows[configFocusIndex])
                event.accepted = true
                return
            }
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                activateFocused()
                event.accepted = true
            }
            return
        }

        if (t === " " || event.key === Qt.Key_Space) {
            if (focusRow === 1) {
                RecordService.toggleSourceMute()
                event.accepted = true
                return
            }
            if (focusRow === 2) {
                RecordService.toggleSinkMute()
                event.accepted = true
                return
            }
        }

        if (t === "j" || event.key === Qt.Key_Down) {
            moveMainV(1)
            event.accepted = true
            return
        }
        if (t === "k" || event.key === Qt.Key_Up) {
            moveMainV(-1)
            event.accepted = true
            return
        }
        if (t === "h" || event.key === Qt.Key_Left) {
            moveMainH(-1)
            event.accepted = true
            return
        }
        if (t === "l" || event.key === Qt.Key_Right) {
            moveMainH(1)
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            activateMain()
            event.accepted = true
        }
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "\uf03d"
                color: running ? WallustColors.red : WallustColors.accent
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize + 2
            }

            Column {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: running ? (paused ? "Paused" : "Recording") : "Screen record"
                    color: WallustColors.moduleText
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontPixelSize + 1
                    font.bold: true
                }

                Text {
                    text: recorderOk ? "gpu-screen-recorder" : "Install gpu-screen-recorder"
                    color: WallustColors.moduleText
                    opacity: recorderOk ? 0.45 : 0.85
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontPixelSize - 2
                }
            }

            Text {
                text: "h/l vol · j/k · Space mute · Enter · Esc"
                color: WallustColors.moduleText
                opacity: 0.4
                font.family: Style.fontFamily
                font.pixelSize: 9
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Rectangle {
                Layout.preferredWidth: recBtn.implicitWidth + 20
                Layout.preferredHeight: 32
                radius: 10
                color: running
                    ? Qt.rgba(WallustColors.red.r, WallustColors.red.g, WallustColors.red.b, 0.25)
                    : Qt.rgba(WallustColors.accent.r, WallustColors.accent.g, WallustColors.accent.b, 0.2)
                border.width: root.isMainFocused(0, 0) ? 2 : 1
                border.color: root.isMainFocused(0, 0)
                    ? WallustColors.sky
                    : (running ? WallustColors.red : WallustColors.accent)

                Text {
                    id: recBtn
                    anchors.centerIn: parent
                    text: running ? "\uf04d  Stop" : "\uf111  Record"
                    color: WallustColors.moduleText
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontPixelSize
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: recorderOk
                    onClicked: RecordService.toggleRecord()
                }
            }

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 32
                radius: 10
                color: Qt.rgba(0, 0, 0, 0.22)
                border.width: root.isMainFocused(0, 1) ? 2 : 1
                border.color: root.isMainFocused(0, 1) ? WallustColors.sky : WallustColors.borderColor
                opacity: running ? 1 : 0.35

                Text {
                    anchors.centerIn: parent
                    text: paused ? "\uf04b" : "\uf04c"
                    color: WallustColors.moduleText
                    font.family: Style.fontFamily
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: running
                    onClicked: RecordService.togglePause()
                }
            }

            Rectangle {
                id: regionBtn
                Layout.preferredWidth: 36
                Layout.preferredHeight: 32
                radius: 10
                color: Qt.rgba(0, 0, 0, 0.22)
                border.width: root.isMainFocused(0, 2) ? 2 : 1
                border.color: root.isMainFocused(0, 2) ? WallustColors.sky : WallustColors.borderColor
                opacity: running ? 0.35 : 1

                Text {
                    anchors.centerIn: parent
                    text: "\uf065"
                    color: WallustColors.moduleText
                    font.family: Style.fontFamily
                    font.pixelSize: 11
                }

                ToolTip {
                    visible: regionMouse.containsMouse
                    delay: 400
                    text: running
                        ? "Region — stop recording first"
                        : (recorderOk
                            ? "Region — closes menu, draw area with mouse (slurp)"
                            : "Install gpu-screen-recorder")
                }

                MouseArea {
                    id: regionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !running && recorderOk
                    onClicked: {
                        ShellActions.closeLeftSurface?.()
                        regionArmTimer.restart()
                    }
                }
            }

            Timer {
                id: regionArmTimer
                interval: 280
                onTriggered: RecordService.startRegion()
            }

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 32
                radius: 10
                color: RecordService.configOpen
                    ? Qt.rgba(WallustColors.sky.r, WallustColors.sky.g, WallustColors.sky.b, 0.2)
                    : Qt.rgba(0, 0, 0, 0.22)
                border.width: root.isMainFocused(0, 3) ? 2 : 1
                border.color: root.isMainFocused(0, 3) ? WallustColors.sky : WallustColors.borderColor

                Text {
                    anchors.centerIn: parent
                    text: "\uf013"
                    color: WallustColors.moduleText
                    font.family: Style.fontFamily
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: RecordService.configOpen = !RecordService.configOpen
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: !RecordService.configOpen

            RecordVolumeStrip {
                id: micStrip
                Layout.fillWidth: true
                label: "Microphone"
                icon: "\uf130"
                volume: RecordService.audioSource.volume
                muted: RecordService.audioSource.muted
                vimFocus: root.focusRow === 1
                focusMute: root.isMainFocused(1, 0)
                focusVol: root.isMainFocused(1, 1) || (root.focusRow === 1 && root.micVolAdjust)
                muteAction: function() { RecordService.toggleSourceMute() }
            }

            RecordVolumeStrip {
                id: sysStrip
                Layout.fillWidth: true
                label: "System audio"
                icon: "\uf028"
                volume: RecordService.audioSink.volume
                muted: RecordService.audioSink.muted
                vimFocus: root.focusRow === 2
                focusMute: root.isMainFocused(2, 0)
                focusVol: root.isMainFocused(2, 1) || (root.focusRow === 2 && root.sysVolAdjust)
                muteAction: function() { RecordService.toggleSinkMute() }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: RecordService.configOpen

            Text {
                text: "Output folder"
                color: WallustColors.moduleText
                opacity: 0.55
                font.family: Style.fontFamily
                font.pixelSize: 9
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: pathField.height + 8
                radius: 8
                color: Qt.rgba(0, 0, 0, 0.15)
                border.width: root.isFocusedConfig("path") ? 2 : 1
                border.color: root.isFocusedConfig("path") ? WallustColors.sky : WallustColors.borderColor

                TextField {
                    id: pathField
                    anchors.fill: parent
                    anchors.margins: 4
                    color: WallustColors.moduleText
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontPixelSize - 1
                    selectionColor: WallustColors.accent
                    placeholderText: "~/Videos"
                    text: RecordService.recordConfig.saveDir || ShellConfig.recordSaveDir
                    onEditingFinished: RecordService.patchConfig({ saveDir: text.trim() })
                }
            }

            Text {
                text: "Capture in file"
                color: WallustColors.moduleText
                opacity: 0.55
                font.family: Style.fontFamily
                font.pixelSize: 9
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: [
                        { id: "monitor", label: "Monitor" },
                        { id: "region", label: "Region" },
                        { id: "window", label: "Window" }
                    ]

                    delegate: Rectangle {
                        required property int index
                        required property var modelData
                        Layout.fillWidth: true
                        height: 28
                        radius: 8
                        color: (RecordService.recordConfig.mode || "monitor") === modelData.id
                            ? Qt.rgba(WallustColors.accent.r, WallustColors.accent.g, WallustColors.accent.b, 0.22)
                            : Qt.rgba(0, 0, 0, 0.15)
                        border.width: root.isFocusedConfig("mode", index) ? 2 : 1
                        border.color: root.isFocusedConfig("mode", index) ? WallustColors.sky : WallustColors.borderColor

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: WallustColors.moduleText
                            font.family: Style.fontFamily
                            font.pixelSize: 9
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: RecordService.patchConfig({ mode: modelData.id })
                        }
                    }
                }
            }

            Text {
                visible: (RecordService.recordConfig.mode || "") === "window"
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: "Pick window below, then Record"
                color: WallustColors.moduleText
                opacity: 0.5
                font.family: Style.fontFamily
                font.pixelSize: 9
            }

            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(120, Math.max(40, count * 32))
                clip: true
                spacing: 2
                visible: (RecordService.recordConfig.mode || "") === "monitor"
                model: RecordService.monitors

                delegate: Rectangle {
                    required property int index
                    required property var modelData
                    width: ListView.view.width
                    height: 30
                    radius: 8
                    color: (RecordService.recordConfig.monitor || "") === modelData.name
                            || (!RecordService.recordConfig.monitor && modelData.focused)
                        ? Qt.rgba(WallustColors.sky.r, WallustColors.sky.g, WallustColors.sky.b, 0.15)
                        : Qt.rgba(0, 0, 0, 0.12)
                    border.width: root.isFocusedConfig("mon", index) ? 2 : 0
                    border.color: WallustColors.sky

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        width: parent.width - 16
                        elide: Text.ElideRight
                        text: (modelData.focused ? "● " : "") + (modelData.description || modelData.name)
                        color: WallustColors.moduleText
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize - 1
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: RecordService.patchConfig({ mode: "monitor", monitor: modelData.name })
                    }
                }
            }

            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(140, Math.max(40, count * 32))
                clip: true
                spacing: 2
                visible: (RecordService.recordConfig.mode || "") === "window"
                model: RecordService.windows

                delegate: Rectangle {
                    required property int index
                    required property var modelData
                    width: ListView.view.width
                    height: 30
                    radius: 8
                    color: RecordService.recordConfig.windowAddress === modelData.address
                        ? Qt.rgba(WallustColors.sky.r, WallustColors.sky.g, WallustColors.sky.b, 0.15)
                        : Qt.rgba(0, 0, 0, 0.12)
                    border.width: root.isFocusedConfig("win", index) ? 2 : 0
                    border.color: WallustColors.sky

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        width: parent.width - 16
                        elide: Text.ElideRight
                        text: (modelData.class || "?") + " — " + (modelData.title || "")
                        color: WallustColors.moduleText
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize - 2
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: RecordService.patchConfig({
                            mode: "window",
                            windowAddress: modelData.address
                        })
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                radius: 8
                color: Qt.rgba(0, 0, 0, 0.1)
                border.width: root.isFocusedConfig("inc_mic") ? 2 : 0
                border.color: WallustColors.sky

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 8

                    Text {
                        text: "Mic in recording"
                        color: WallustColors.moduleText
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize - 1
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 44
                        height: 22
                        radius: 11
                        color: RecordService.recordConfig.includeMic
                            ? WallustColors.accent
                            : Qt.rgba(0, 0, 0, 0.3)

                        Rectangle {
                            x: RecordService.recordConfig.includeMic ? parent.width - width - 2 : 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        height: 18
                        radius: 9
                        color: WallustColors.moduleText
                        Behavior on x { NumberAnimation { duration: 120 } }
                    }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: RecordService.patchConfig({
                                includeMic: !RecordService.recordConfig.includeMic
                            })
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                radius: 8
                color: Qt.rgba(0, 0, 0, 0.1)
                border.width: root.isFocusedConfig("inc_sys") ? 2 : 0
                border.color: WallustColors.sky

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 8

                    Text {
                        text: "System audio"
                        color: WallustColors.moduleText
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize - 1
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 44
                        height: 22
                        radius: 11
                        color: RecordService.recordConfig.includeSystemAudio !== false
                            ? WallustColors.accent
                            : Qt.rgba(0, 0, 0, 0.3)

                        Rectangle {
                            x: RecordService.recordConfig.includeSystemAudio !== false
                                ? parent.width - width - 2 : 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        height: 18
                        radius: 9
                        color: WallustColors.moduleText
                        Behavior on x { NumberAnimation { duration: 120 } }
                    }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: RecordService.patchConfig({
                                includeSystemAudio: !(RecordService.recordConfig.includeSystemAudio !== false)
                            })
                        }
                    }
                }
            }

        }

        Text {
            Layout.fillWidth: true
            visible: RecordService.lastError.length > 0
            wrapMode: Text.WordWrap
            text: RecordService.lastError
            color: WallustColors.red
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize - 2
        }
    }
}