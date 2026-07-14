import QtQuick
import QtQuick.Controls
import "../singletons"

/**
 * Middle launcher — apps; /f files, /s web, /t quick shell (samaelv2 command prefix).
 */
FocusScope {
    id: root

    property bool open: false
    property real morphCloseness: 1
    property string query: ""
    property int selectedIndex: 0

    readonly property var parsed: LauncherService.parseQuery(query)
    readonly property string mode: parsed.mode
    readonly property string searchTerm: parsed.term
    readonly property var modeInfo: LauncherService.modeMeta(mode)

    readonly property int _rev: LauncherService.revision
    readonly property var filteredApps: {
        const _r = _rev
        if (mode !== "apps")
            return []
        return LauncherService.pinnedFirst(LauncherService.filterApps(searchTerm))
    }

    readonly property size panelSize: ShellConfig.surfaceSize("launcher")

    readonly property bool listVisible: mode !== "terminal"
    readonly property real listBlockH: Math.min(300, Math.max(44, listModel.count > 0 ? (listModel.count * 39 + 8) : 120))
    readonly property real terminalBlockH: Math.min(280, Math.max(100, 88))
    readonly property real contentBlockH: mode === "terminal" ? terminalBlockH : listBlockH

    readonly property string launcherEmptyText: {
        if (mode === "files") {
            if (LauncherService.filesLoading)
                return qsTr("Searching…")
            if (!searchTerm.length)
                return qsTr("Type a name after /f")
            return LauncherService.filesError || qsTr("No files found")
        }
        if (mode === "search") {
            if (!searchTerm.length)
                return qsTr("Type a query after /s")
            return qsTr("Press Enter to search")
        }
        if (mode === "terminal") {
            if (!searchTerm.length)
                return qsTr("Type a command after /t — Enter runs it")
            if (LauncherService.terminalRunning)
                return qsTr("Running…")
            return ""
        }
        if (LauncherService.loading)
            return qsTr("Loading apps…")
        if (query.length)
            return qsTr("No matches")
        return LauncherService.lastError || qsTr("Empty index")
    }

    implicitWidth: panelSize.width
    implicitHeight: Math.min(panelSize.height, 24 + 8 + 36 + 8 + contentBlockH + 16)

    opacity: open ? Math.pow(morphCloseness, 1.2) : 0
    visible: opacity > 0.02
    enabled: open
    focus: open

    ListModel { id: listModel }

    function resyncModel() {
        listModel.clear()
        if (mode === "apps") {
            const list = filteredApps
            for (let i = 0; i < list.length; i++) {
                const e = list[i]
                if (!e)
                    continue
                listModel.append({
                    rowType: "app",
                    name: e.name || e.desktopId || "?",
                    sub: e.comment || e.desktopId || "",
                    desktopId: e.desktopId || "",
                    execLine: e.exec || "",
                    comment: e.comment || "",
                    iconPath: e.iconPath || "",
                    terminal: !!e.terminal,
                    path: "",
                    isDir: false
                })
            }
        } else if (mode === "files") {
            const list = LauncherService.files || []
            for (let j = 0; j < list.length; j++) {
                const f = list[j]
                if (!f)
                    continue
                listModel.append({
                    rowType: "file",
                    name: f.name || "?",
                    sub: f.path || "",
                    desktopId: "",
                    execLine: "",
                    comment: "",
                    iconPath: "",
                    terminal: false,
                    path: f.path || "",
                    isDir: !!f.isDir
                })
            }
        } else if (mode === "search") {
            const q = searchTerm.trim()
            if (q.length) {
                listModel.append({
                    rowType: "search",
                    name: qsTr("Search the web for “%1”").arg(q),
                    sub: "duckduckgo.com",
                    desktopId: "",
                    execLine: "",
                    comment: "",
                    iconPath: "",
                    terminal: false,
                    path: "",
                    isDir: false
                })
            }
        }
        clampIndex()
    }

    onFilteredAppsChanged: resyncModel()

    Connections {
        target: LauncherService
        function onRevisionChanged() {
            if (root.mode === "files")
                root.resyncModel()
        }
    }

    onModeChanged: {
        if (mode === "files")
            LauncherService.searchFiles(searchTerm)
        else if (mode !== "terminal")
            LauncherService.resetAuxiliary()
        else if (mode === "terminal") {
            LauncherService.files = []
            LauncherService.filesLoading = false
        }
        resyncModel()
    }
    onSearchTermChanged: {
        if (mode === "files")
            LauncherService.searchFiles(searchTerm)
        resyncModel()
    }

    Component.onCompleted: resyncModel()

    onOpenChanged: {
        if (open) {
            LauncherService.refresh()
            query = ""
            selectedIndex = 0
            LauncherService.resetAuxiliary()
            Qt.callLater(() => {
                resyncModel()
                focusSearch()
            })
        } else {
            LauncherService.resetAuxiliary()
        }
    }

    onQueryChanged: {
        selectedIndex = 0
    }

    function clampIndex() {
        const n = listModel.count
        selectedIndex = n === 0 ? 0 : Math.max(0, Math.min(n - 1, selectedIndex))
    }

    function appEntryAt(i) {
        if (i < 0 || i >= listModel.count)
            return null
        const r = listModel.get(i)
        if (r.rowType !== "app")
            return null
        return {
            name: r.name,
            desktopId: r.desktopId,
            exec: r.execLine,
            comment: r.comment,
            iconPath: r.iconPath,
            terminal: r.terminal
        }
    }

    function activateSelected() {
        if (listModel.count === 0)
            return
        const r = listModel.get(selectedIndex)
        if (!r)
            return
        if (r.rowType === "app") {
            const e = appEntryAt(selectedIndex)
            if (e)
                LauncherService.launchEntry(e)
        } else if (r.rowType === "file") {
            LauncherService.openPath(r.path)
        } else if (r.rowType === "search") {
            LauncherService.openWebSearch(searchTerm)
            ShellActions.closeMiddleSurface?.()
        }
    }

    function focusSearch() {
        searchField.forceActiveFocus()
    }

    function focusList() {
        searchField.focus = false
        root.focus = true
    }

    function handleKey(event) {
        if (!open)
            return
        if (event.key === Qt.Key_Escape) {
            if (searchField.activeFocus) {
                focusList()
                event.accepted = true
                return
            }
            ShellActions.closeMiddleSurface?.()
            event.accepted = true
            return
        }
        if ((event.key === Qt.Key_Slash || event.text === "/") && !searchField.activeFocus) {
            focusSearch()
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (mode === "terminal") {
                if (searchTerm.trim().length)
                    LauncherService.runTerminalCommand(searchTerm)
                event.accepted = true
                return
            }
            activateSelected()
            event.accepted = true
            return
        }
        if (searchField.activeFocus)
            return
        const t = event.text
        if (t === "j" || event.key === Qt.Key_Down) {
            if (listModel.count)
                selectedIndex = Math.min(listModel.count - 1, selectedIndex + 1)
            event.accepted = true
            return
        }
        if (t === "k" || event.key === Qt.Key_Up) {
            if (listModel.count)
                selectedIndex = Math.max(0, selectedIndex - 1)
            event.accepted = true
        }
    }

    Keys.onPressed: event => handleKey(event)

    Column {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        Row {
            width: parent.width
            height: 24
            spacing: 8

            Text {
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                text: modeInfo.glyph
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize + 2
                color: WallustColors.sapphire
            }

            Text {
                height: parent.height
                width: parent.width - 100
                verticalAlignment: Text.AlignVCenter
                text: modeInfo.title
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize + 1
                font.bold: true
                color: WallustColors.moduleText
                elide: Text.ElideRight
            }

            Text {
                height: parent.height
                width: 80
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                text: {
                    if (mode === "terminal")
                        return LauncherService.terminalRunning ? "…"
                            : (LauncherService.terminalExitCode !== -999 ? String(LauncherService.terminalExitCode) : "")
                    if (mode === "files")
                        return LauncherService.filesLoading ? "…" : String(listModel.count)
                    if (mode === "apps")
                        return LauncherService.loading ? "…"
                            : (listModel.count + "/" + LauncherService.apps.length)
                    return listModel.count ? "1" : "0"
                }
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize - 1
                color: WallustColors.yellow
            }
        }

        Rectangle {
            width: parent.width
            height: 36
            radius: 8
            color: Qt.rgba(WallustColors.moduleBackground.r, WallustColors.moduleBackground.g,
                WallustColors.moduleBackground.b, 0.75)
            border.width: 1
            border.color: WallustColors.borderColor

            TextField {
                id: searchField
                anchors.fill: parent
                anchors.margins: 6
                placeholderText: modeInfo.placeholder
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize
                color: WallustColors.moduleText
                placeholderTextColor: Qt.rgba(WallustColors.moduleText.r, WallustColors.moduleText.g,
                    WallustColors.moduleText.b, 0.45)
                background: Item {}
                selectByMouse: true
                text: root.query
                onTextChanged: root.query = text
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Down || event.key === Qt.Key_Up
                            || event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                            || event.key === Qt.Key_Escape) {
                        root.handleKey(event)
                        if (event.accepted)
                            return
                    }
                    event.accepted = false
                }
            }
        }

        Rectangle {
            id: terminalPanel
            width: parent.width
            height: root.terminalBlockH
            visible: root.mode === "terminal"
            radius: 8
            color: Qt.rgba(0, 0, 0, 0.35)
            border.width: 1
            border.color: WallustColors.borderColor

            Column {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                Row {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "\uf120"
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize
                        color: WallustColors.sapphire
                    }

                    Text {
                        width: parent.width - 72
                        text: LauncherService.terminalRunning ? qsTr("Running…")
                            : (LauncherService.terminalExitCode !== -999
                                ? ("exit " + LauncherService.terminalExitCode) : qsTr("Ready"))
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize - 1
                        font.bold: true
                        color: LauncherService.terminalExitCode === 0 && !LauncherService.terminalRunning
                            ? WallustColors.yellow
                            : (LauncherService.terminalExitCode > 0 && !LauncherService.terminalRunning
                                ? WallustColors.workspaceUrgent : WallustColors.moduleText)
                        elide: Text.ElideRight
                    }
                }

                ScrollView {
                    width: parent.width
                    height: parent.height - 28
                    clip: true
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    Text {
                        width: terminalPanel.width - 24
                        wrapMode: Text.Wrap
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize - 1
                        font.hintingPreference: Font.PreferNoHinting
                        color: WallustColors.moduleText
                        text: LauncherService.formatTerminalOutput()
                    }
                }
            }
        }

        ListView {
            id: appList
            width: parent.width
            height: root.listBlockH
            visible: root.listVisible
            clip: true
            spacing: 3
            model: listModel
            currentIndex: root.selectedIndex
            onCountChanged: root.clampIndex()

            delegate: Rectangle {
                required property int index
                required property string rowType
                required property string name
                required property string sub
                required property string desktopId
                required property string execLine
                required property string comment
                required property string iconPath
                required property bool terminal
                required property string path
                required property bool isDir

                width: appList.width
                height: rowType === "file" && sub.length ? 44 : 36
                radius: 6
                color: index === root.selectedIndex
                    ? Qt.rgba(WallustColors.sapphire.r, WallustColors.sapphire.g, WallustColors.sapphire.b, 0.35)
                    : Qt.rgba(WallustColors.moduleText.r, WallustColors.moduleText.g,
                        WallustColors.moduleText.b, 0.1)

                Row {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    Rectangle {
                        width: 28
                        height: 28
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 6
                        color: Qt.rgba(WallustColors.moduleBackground.r, WallustColors.moduleBackground.g,
                            WallustColors.moduleBackground.b, 0.85)
                        border.width: 1
                        border.color: WallustColors.borderColor

                        Image {
                            id: appIcon
                            anchors.fill: parent
                            anchors.margins: 4
                            source: rowType === "app" && iconPath.length ? iconPath : ""
                            fillMode: Image.PreserveAspectFit
                            visible: status === Image.Ready && source.toString().length > 0
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !appIcon.visible
                            text: {
                                if (rowType === "file")
                                    return isDir ? "\uf07b" : "\uf15b"
                                if (rowType === "search")
                                    return "\uf0ac"
                                return terminal ? "\uf120" : "\uf1b2"
                            }
                            font.family: Style.fontFamily
                            font.pixelSize: 12
                            color: WallustColors.sapphire
                        }
                    }

                    Column {
                        width: parent.width - 36
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0

                        Text {
                            width: parent.width
                            verticalAlignment: Text.AlignVCenter
                            text: name
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontPixelSize
                            font.bold: index === root.selectedIndex
                            color: WallustColors.moduleText
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            visible: sub.length > 0 && rowType !== "search"
                            text: sub
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontPixelSize - 2
                            color: WallustColors.moduleText
                            opacity: 0.55
                            elide: Text.ElideMiddle
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.selectedIndex = index
                        if (rowType === "app") {
                            LauncherService.launchEntry({
                                name: name,
                                desktopId: desktopId,
                                exec: execLine,
                                comment: comment,
                                iconPath: iconPath,
                                terminal: terminal
                            })
                        } else if (rowType === "file") {
                            LauncherService.openPath(path)
                        } else if (rowType === "search") {
                            LauncherService.openWebSearch(root.searchTerm)
                        }
                        ShellActions.closeMiddleSurface?.()
                    }
                }
            }

            onCurrentIndexChanged: {
                if (currentIndex >= 0)
                    root.selectedIndex = currentIndex
            }
        }

        Text {
            width: parent.width
            visible: root.listVisible && listModel.count === 0
                && !(root.mode === "terminal" && (LauncherService.terminalRunning
                    || LauncherService.terminalExitCode !== -999))
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: root.launcherEmptyText
            color: WallustColors.moduleText
            opacity: 0.65
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize - 1
        }
    }
}