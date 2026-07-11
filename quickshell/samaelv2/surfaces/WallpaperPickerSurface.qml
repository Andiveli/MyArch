import QtQuick
import "../singletons"

/**
 * Filmstrip — vim-style search: / insert filter, Esc → normal (keep filter, h/l matches).
 * Keys handled on this FocusScope only (no TextField focus; Esc works on layer shell).
 */
FocusScope {
    id: root

    property bool active: true
    signal requestClose()

    property int focusIndex: 0
    /** Filter bar visible (query may be non-empty). */
    property bool searching: false
    /** true = typing filter (/ or re-edit); false = navigate strip with filter applied. */
    property bool searchEditMode: false
    property string query: ""
    property real pos: 0

    readonly property var items: WallsService.filtered(query)
    readonly property int itemCount: items.length

    readonly property var slotW: [196, 126, 104, 88, 74]
    readonly property var slotH: [110, 71, 59, 50, 42]
    readonly property var slotCX: [0, 143, 244, 326, 393]
    readonly property var slotBright: [1, 0.56, 0.42, 0.30, 0.22]

    anchors.fill: parent
    clip: true
    focus: true

    function slotLerp(arr, ao) {
        if (ao >= 4)
            return arr[4]
        const i = Math.floor(ao)
        const f = ao - i
        return arr[i] + (arr[i + 1] - arr[i]) * f
    }

    function offsetX(off) {
        const ao = Math.abs(off)
        const cx = ao <= 4 ? slotLerp(slotCX, ao) : slotCX[4] + (ao - 4) * 60
        return (off < 0 ? -cx : cx)
    }

    function move(delta) {
        if (itemCount === 0)
            return
        focusIndex = Math.max(0, Math.min(itemCount - 1, focusIndex + delta))
    }

    function activate() {
        if (focusIndex < 0 || focusIndex >= itemCount)
            return
        WallsService.apply(items[focusIndex].path)
    }

    function centerOnCurrent() {
        const idx = WallsService.indexInList(items)
        focusIndex = idx
        pos = idx
    }

    function applyQuery(q) {
        query = q
        focusIndex = 0
        pos = 0
    }

    /** Esc from insert: keep query, navigate matches. */
    function leaveSearchInput() {
        searchEditMode = false
        focusIndex = Math.min(focusIndex, Math.max(0, itemCount - 1))
        pos = focusIndex
        forceActiveFocus()
    }

    function clearFilter() {
        searching = false
        searchEditMode = false
        applyQuery("")
        centerOnCurrent()
        forceActiveFocus()
    }

    function startSearch() {
        searching = true
        searchEditMode = true
        forceActiveFocus()
    }

    function prepareOpen() {
        // Lightweight mtime check — if new wallpapers added, re-scan without blocking
        WallsService.checkForChanges()
        searching = false
        searchEditMode = false
        applyQuery("")
        Qt.callLater(centerOnCurrent)
        Qt.callLater(forceActiveFocus)
    }

    onActiveChanged: if (active)
        prepareOpen()

    Connections {
        target: WallsService
        function onEntriesChanged() {
            if (root.active && !root.searchEditMode)
                root.centerOnCurrent()
        }
        function onCurrentChanged() {
            if (root.active && !root.searchEditMode && root.itemCount > 0)
                root.centerOnCurrent()
        }
    }

    onItemsChanged: {
        if (focusIndex >= itemCount)
            focusIndex = Math.max(0, itemCount - 1)
    }

    FrameAnimation {
        running: root.active && root.pos !== root.focusIndex
        onTriggered: {
            const k = 1 - Math.exp(-frameTime / 0.07)
            const next = root.pos + (root.focusIndex - root.pos) * k
            root.pos = Math.abs(next - root.focusIndex) < 0.001 ? root.focusIndex : next
        }
    }

    Rectangle {
        id: searchBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 4
        height: searching ? 32 : 0
        visible: height > 0
        radius: 8
        color: Qt.rgba(0, 0, 0, searchEditMode ? 0.45 : 0.32)
        border.width: 0

        Text {
            anchors.fill: parent
            anchors.margins: 8
            verticalAlignment: Text.AlignVCenter
            color: WallustColors.moduleText
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize
            text: query.length ? query : "…"
            opacity: query.length ? 1 : 0.45
        }
    }

    Item {
        id: strip
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: searching ? searchBar.bottom : parent.top
        anchors.topMargin: searching ? 6 : 0
        anchors.bottom: parent.bottom
        anchors.margins: 2
        clip: true

        Repeater {
            model: root.items

            delegate: Item {
                id: tile
                required property int index
                required property var modelData

                readonly property real off: index - root.pos
                readonly property real ao: Math.abs(off)
                readonly property bool focused: index === root.focusIndex
                readonly property real bright: root.slotLerp(root.slotBright, ao)
                readonly property real corner: 8 + 2 * Math.max(0, 1 - ao)

                width: root.slotLerp(root.slotW, ao)
                height: root.slotLerp(root.slotH, ao)
                x: strip.width / 2 + root.offsetX(off) - width / 2
                y: (strip.height - height) / 2
                z: 10 - ao
                visible: ao <= 5
                opacity: ao <= 4 ? 1 : Math.max(0, 5 - ao)

                Rectangle {
                    anchors.fill: parent
                    radius: tile.corner
                    color: "transparent"
                    border.width: 0
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: tile.ao <= 6
                            ? ("file://" + (WallsService.thumbsReady ? modelData.thumb : modelData.path))
                            : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        smooth: true
                        sourceSize.width: 400
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "#000000"
                        opacity: 1 - tile.bright
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.focusIndex = index
                        root.activate()
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: root.itemCount === 0
            text: root.query.length ? "No matches" : ("No images in " + ShellConfig.wallpaperDir)
            color: WallustColors.buttonHover
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize
        }
    }

    MouseArea {
        anchors.fill: strip
        z: 1
        acceptedButtons: Qt.NoButton
        property real acc: 0
        onWheel: wheel => {
            if (root.searchEditMode)
                return
            acc += wheel.angleDelta.y / 120
            const notches = Math.trunc(acc)
            if (notches !== 0) {
                root.move(-notches)
                acc -= notches
            }
            wheel.accepted = true
        }
    }

    Keys.onPressed: event => {
        const key = event.key
        const t = event.text

        if (searchEditMode) {
            if (key === Qt.Key_Escape) {
                leaveSearchInput()
                event.accepted = true
                return
            }
            if (key === Qt.Key_Return || key === Qt.Key_Enter) {
                leaveSearchInput()
                event.accepted = true
                return
            }
            if (key === Qt.Key_Backspace) {
                applyQuery(query.slice(0, -1))
                event.accepted = true
                return
            }
            if (t.length === 1 && t >= " " && key !== Qt.Key_Slash) {
                applyQuery(query + t)
                event.accepted = true
            }
            return
        }

        if (key === Qt.Key_Escape) {
            if (searching || query.length > 0)
                clearFilter()
            else
                requestClose()
            event.accepted = true
            return
        }
        if (key === Qt.Key_Slash) {
            startSearch()
            event.accepted = true
            return
        }
        if (key === Qt.Key_Return || key === Qt.Key_Enter) {
            activate()
            event.accepted = true
            return
        }
        if (t === "h" || key === Qt.Key_Left) {
            move(-1)
            event.accepted = true
            return
        }
        if (t === "l" || key === Qt.Key_Right) {
            move(1)
            event.accepted = true
        }
    }
}