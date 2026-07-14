import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../singletons"
import "../widgets/settings"

/**
 * Settings — Caelestia Nexus-style nav + Wallust + vim (j/k pages, h/l steppers, s save, Esc).
 */
FocusScope {
    id: root

    property bool open: false
    property real morphCloseness: 1

    readonly property var pages: ShellConfigService.pages
    property int pageIndex: 0
    property int focusBand: 0 // 0 nav, 1 content
    property int contentRow: 0

    readonly property string currentPageId: pages.length ? pages[Math.max(0, Math.min(pages.length - 1, pageIndex))].id : "general"
    readonly property int _rev: ShellConfigService.revision

    readonly property int panelW: 720
    readonly property int panelH: 440
    implicitWidth: panelW
    implicitHeight: panelH
    width: panelW
    height: panelH

    opacity: open ? Math.pow(morphCloseness, 1.2) : 0
    visible: opacity > 0.02
    enabled: open
    focus: open

    onOpenChanged: {
        if (open) {
            ShellConfigService.refreshDraftFromDisk(() => {
                pageIndex = 0
                focusBand = 0
                contentRow = 0
                Qt.callLater(forceActiveFocus)
                Qt.callLater(() => pageHost.rebuildRows())
            })
        }
    }

    function statusLine() {
        if (ShellConfigService.saving)
            return "Saving…"
        if (ShellConfigService.saveError.length)
            return ShellConfigService.saveError
        if (ShellConfigService.dirty)
            return "Unsaved changes · press s to save"
        if (ShellConfigService.statusMessage.length)
            return ShellConfigService.statusMessage
        return focusBand === 0
            ? "j/k page · l/Enter panel · Tab · s save · Esc"
            : "j/k row · l toggle/+ · Shift+h − · h nav · s save · Esc"
    }

    function handleKey(event) {
        if (!open)
            return
        const t = event.text
        if (event.key === Qt.Key_Escape) {
            ShellActions.closeMiddleSurface?.()
            event.accepted = true
            return
        }
        if (t === "s" || t === "S") {
            if (!ShellConfigService.saving)
                ShellConfigService.save()
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Tab) {
            focusBand = (focusBand + 1) % 2
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Backtab) {
            focusBand = focusBand === 0 ? 1 : 0
            event.accepted = true
            return
        }
        if (focusBand === 0) {
            if (t === "j" || event.key === Qt.Key_Down) {
                pageIndex = Math.min(pages.length - 1, pageIndex + 1)
                contentRow = 0
                event.accepted = true
                return
            }
            if (t === "k" || event.key === Qt.Key_Up) {
                pageIndex = Math.max(0, pageIndex - 1)
                contentRow = 0
                event.accepted = true
                return
            }
            if (t === "l" || event.key === Qt.Key_Right || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                focusBand = 1
                contentRow = 0
                Qt.callLater(() => {
                    pageHost.rebuildRows()
                    contentFlick.centerRowInView(0)
                })
                event.accepted = true
                return
            }
        } else {
            const rows = contentFlick.interactiveRows || 0
            if (t === "j" || event.key === Qt.Key_Down) {
                contentRow = Math.min(Math.max(0, rows - 1), contentRow + 1)
                event.accepted = true
                return
            }
            if (t === "k" || event.key === Qt.Key_Up) {
                contentRow = Math.max(0, contentRow - 1)
                event.accepted = true
                return
            }
            if (t === "h" || event.key === Qt.Key_Left) {
                focusBand = 0
                event.accepted = true
                return
            }
            if (t === "l" || event.key === Qt.Key_Right || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                contentFlick.activateRow(contentRow, 1)
                event.accepted = true
                return
            }
            if (t === "h" && (event.modifiers & Qt.ShiftModifier)) {
                contentFlick.activateRow(contentRow, -1)
                event.accepted = true
                return
            }
        }
    }

    Keys.onPressed: event => handleKey(event)

    readonly property int headerH: 44
    readonly property int navW: Math.round(root.panelW * 0.32)

    Item {
        anchors.fill: parent
        anchors.margins: 10

        Column {
            id: chrome
            anchors.fill: parent
            spacing: 6

        Rectangle {
            width: parent.width
            height: root.headerH
            radius: ShellConfig.cornerRadius * 0.5
            color: Style.menuPanelFill
            border.color: WallustColors.borderColor

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10
                Text {
                    text: "\uf013"
                    color: WallustColors.accent
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontPixelSize + 2
                    Layout.alignment: Qt.AlignVCenter
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2
                    Text {
                        Layout.fillWidth: true
                        text: root.pages[root.pageIndex] ? root.pages[root.pageIndex].label : "Settings"
                        color: WallustColors.moduleText
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize + 1
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.statusLine()
                        color: ShellConfigService.saveError.length ? WallustColors.red : WallustColors.moduleText
                        opacity: ShellConfigService.saveError.length ? 1 : 0.55
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize - 2
                        elide: Text.ElideRight
                    }
                }
            }
        }

        Row {
            width: parent.width
            height: parent.height - root.headerH - parent.spacing
            spacing: 6

            Rectangle {
                width: root.navW
                height: parent.height
                radius: ShellConfig.cornerRadius * 0.5
                color: Qt.rgba(WallustColors.moduleBackground.r, WallustColors.moduleBackground.g, WallustColors.moduleBackground.b, 0.72)
                border.color: WallustColors.borderColor

                Flickable {
                    id: navFlick
                    anchors.fill: parent
                    anchors.margins: 8
                    clip: true
                    contentWidth: width
                    contentHeight: navCol.height + navCol.topPadding + navCol.bottomPadding
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        implicitWidth: 4
                    }
                    Column {
                        id: navCol
                        width: navFlick.width
                        topPadding: 4
                        bottomPadding: 6
                        spacing: 2
                        Repeater {
                            model: root.pages
                            delegate: SettingsNavRow {
                                required property var modelData
                                required property int index
                                width: navCol.width
                                first: index === 0
                                last: index === root.pages.length - 1
                                selected: root.focusBand === 0 && root.pageIndex === index
                                label: modelData.label
                                status: ""
                                icon: modelData.icon
                                onActivated: {
                                    root.pageIndex = index
                                    root.focusBand = 1
                                    root.contentRow = 0
                                    root.forceActiveFocus()
                                    Qt.callLater(() => {
                                        pageHost.rebuildRows()
                                        contentFlick.centerRowInView(0)
                                    })
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: contentPane
                width: parent.width - root.navW - parent.spacing
                height: parent.height
                radius: ShellConfig.cornerRadius * 0.5
                color: Qt.rgba(WallustColors.moduleBackground.r, WallustColors.moduleBackground.g, WallustColors.moduleBackground.b, 0.5)
                border.color: WallustColors.borderColor
                border.width: 1

                Flickable {
                    id: contentFlick
                    anchors.fill: parent
                    anchors.margins: 10
                    clip: true
                    contentWidth: width
                    contentHeight: Math.max(height, pageHost.implicitHeight + 16)
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.VerticalFlick
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        implicitWidth: 4
                    }

                    property int interactiveRows: pageHost.rowCount

                    function activateRow(row, delta) {
                        const item = pageHost.rowItemAt(row)
                        if (!item)
                            return
                        if (typeof item.bump === "function")
                            item.bump(delta >= 0 ? 1 : -1)
                        else if (item.checked !== undefined)
                            item.toggled(!item.checked)
                    }

                    function ensureRowVisible(row) {
                        const mapped = pageHost.rowMappedY(row)
                        if (mapped < 0)
                            return
                        const item = pageHost.rowItemAt(row)
                        const h = item ? item.height : 40
                        if (mapped < contentY)
                            contentY = mapped
                        else if (mapped + h > contentY + height)
                            contentY = mapped + h - height
                    }

                    /** Keep focused row in the middle of the content pane when possible. */
                    function centerRowInView(row) {
                        const mapped = pageHost.rowMappedY(row)
                        if (mapped < 0)
                            return
                        const item = pageHost.rowItemAt(row)
                        const h = item ? item.height : 36
                        const rowMid = mapped + h * 0.5
                        let y = rowMid - height * 0.5
                        const maxY = Math.max(0, contentHeight - height)
                        contentY = Math.max(0, Math.min(maxY, y))
                    }

                    Connections {
                        target: root
                        function onContentRowChanged() {
                            if (root.focusBand === 1)
                                Qt.callLater(() => contentFlick.centerRowInView(root.contentRow))
                        }
                        function onFocusBandChanged() {
                            if (root.focusBand === 1)
                                Qt.callLater(() => contentFlick.centerRowInView(root.contentRow))
                        }
                        function onCurrentPageIdChanged() {
                            contentFlick.contentY = 0
                            if (root.focusBand === 1)
                                Qt.callLater(() => contentFlick.centerRowInView(0))
                        }
                    }

                    Item {
                        id: pageHost
                        width: contentFlick.width
                        x: 0
                        y: 4
                        property int rowCount: 0
                        property var _rowItems: []

                        function rowItemAt(i) {
                            if (i < 0 || i >= _rowItems.length)
                                return null
                            return _rowItems[i]
                        }

                        implicitHeight: pagesLoader.item ? pagesLoader.item.implicitHeight : 0

                        Loader {
                            id: pagesLoader
                            width: pageHost.width
                            source: "settings/SettingsPages.qml"
                            onLoaded: pagesLoader.bindPages()
                            onItemChanged: if (item) pagesLoader.bindPages()

                            function bindPages() {
                                if (!item)
                                    return
                                item.width = Qt.binding(() => pageHost.width)
                                item.pageId = Qt.binding(() => root.currentPageId)
                                Qt.callLater(pageHost.rebuildRows)
                            }
                        }

                        Connections {
                            target: pagesLoader.item
                            ignoreUnknownSignals: true
                            function onImplicitHeightChanged() {
                                pageHost.rebuildRows()
                                contentFlick.contentHeight = Math.max(contentFlick.height, pageHost.implicitHeight + 16)
                            }
                        }

                        function isInteractive(o) {
                            if (!o)
                                return false
                            if (o.settingsFocusable === true)
                                return true
                            return typeof o.bump === "function"
                        }

                        function walk(item, out) {
                            if (!item || item === pageHost)
                                return
                            if (item.visible === false)
                                return
                            if (item instanceof Loader) {
                                if (item.item)
                                    walk(item.item, out)
                                return
                            }
                            if (isInteractive(item)) {
                                out.push(item)
                                return
                            }
                            const ch = item.children
                            if (!ch)
                                return
                            for (let i = 0; i < ch.length; i++)
                                walk(ch[i], out)
                        }

                        function rowMappedY(i) {
                            const item = rowItemAt(i)
                            if (!item || !item.parent)
                                return -1
                            const p = item.mapToItem(pageHost, 0, 0)
                            return p.y
                        }

                        function setVimFocusOnRows() {
                            for (let i = 0; i < _rowItems.length; i++) {
                                const r = _rowItems[i]
                                if (r && r.vimFocus !== undefined)
                                    r.vimFocus = root.focusBand === 1 && i === root.contentRow
                            }
                        }

                        function rebuildRows() {
                            _rowItems = []
                            if (pagesLoader.item)
                                walk(pagesLoader.item, _rowItems)
                            rowCount = _rowItems.length
                            if (root.contentRow >= rowCount)
                                root.contentRow = Math.max(0, rowCount - 1)
                            setVimFocusOnRows()
                        }
                    }
                }
            }
        }
        }
    }

    onFocusBandChanged: Qt.callLater(() => {
        pageHost.setVimFocusOnRows()
        if (focusBand === 1)
            contentFlick.centerRowInView(contentRow)
    })
    onContentRowChanged: Qt.callLater(() => pageHost.setVimFocusOnRows())

    Connections {
        target: root
        function onCurrentPageIdChanged() {
            root.contentRow = 0
            Qt.callLater(() => pageHost.rebuildRows())
        }
        function on_RevChanged() { Qt.callLater(() => pageHost.rebuildRows()) }
    }
}