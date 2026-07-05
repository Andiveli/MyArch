import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.samael

Item {
    id: root
    focus: true
    property var paths: []
    property var filteredPaths: []
    property string filterText: ""
    property int selectedIndex: 0
    property bool vimPendingG: false
    readonly property int columns: 5
    readonly property string wallDir: "/home/samael/Pictures/wallpapers"
    readonly property string applyScript: "/home/samael/.config/quickshell/ii/scripts/wallpaper/samael-wallpaper.sh"

    function rebuildFilter() {
        const q = filterText.trim().toLowerCase()
        if (!q.length) {
            filteredPaths = paths.slice()
        } else {
            filteredPaths = paths.filter(p => p.split("/").pop().toLowerCase().includes(q))
        }
        if (selectedIndex >= filteredPaths.length)
            selectedIndex = Math.max(0, filteredPaths.length - 1)
    }

    function applyPath(path) {
        if (!path || !path.length)
            return
        Quickshell.execDetached(["bash", applyScript, path])
        GlobalStates.wallpaperSelectorOpen = false
    }

    function applyRandom() {
        if (paths.length === 0)
            return
        applyPath(paths[Math.floor(Math.random() * paths.length)])
    }

    function moveToIndex(index) {
        if (filteredPaths.length === 0)
            return
        const clamped = Math.max(0, Math.min(index, filteredPaths.length - 1))
        selectedIndex = clamped
        grid.positionViewAtIndex(selectedIndex, GridView.Contain)
    }

    function moveSelection(delta) {
        if (filteredPaths.length === 0)
            return
        let next = selectedIndex + delta
        if (next < 0)
            next = filteredPaths.length - 1
        if (next >= filteredPaths.length)
            next = 0
        moveToIndex(next)
    }

    function vimMoveLeft() { moveSelection(-1) }
    function vimMoveRight() { moveSelection(1) }
    function vimMoveUp() { moveSelection(-columns) }
    function vimMoveDown() { moveSelection(columns) }

    function vimGoFirst() {
        vimPendingG = false
        moveToIndex(0)
    }

    function vimGoLast() {
        vimPendingG = false
        moveToIndex(filteredPaths.length - 1)
    }

    function handleVimG() {
        if (vimPendingG) {
            vimGoFirst()
        } else {
            vimPendingG = true
            vimGChordTimer.restart()
        }
    }

    function refreshList() {
        findProc.exec(["bash", "-c",
            `find -L "${wallDir}" -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' -o -iname '*.gif' \\) -print 2>/dev/null | sort`])
    }

    Timer {
        id: vimGChordTimer
        interval: 450
        repeat: false
        onTriggered: root.vimPendingG = false
    }

    Process {
        id: findProc
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").map(s => s.trim()).filter(s => s.length > 0)
                root.paths = lines
                root.rebuildFilter()
                root.selectedIndex = 0
            }
        }
    }

    Component.onCompleted: refreshList()
    onFilterTextChanged: rebuildFilter()

    implicitWidth: 920
    implicitHeight: 520

    Rectangle {
        anchors.fill: parent
        radius: 15
        color: WallustColors.moduleBackground
        border.width: 2
        border.color: WallustColors.borderColor

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Wallpapers"
                    color: WallustColors.moduleText
                    font.family: SamaelStyle.fontFamily
                    font.pixelSize: SamaelStyle.fontPixelSize + 2
                    font.bold: false
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: filteredPaths.length + " images"
                    color: WallustColors.buttonHover
                    font.family: SamaelStyle.fontFamily
                    font.pixelSize: SamaelStyle.fontPixelSize
                }
            }

            TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: "Filter — / focus · Esc back to grid"
                color: WallustColors.moduleText
                font.family: SamaelStyle.fontFamily
                font.pixelSize: SamaelStyle.fontPixelSize
                padding: 8
                background: Rectangle {
                    radius: 8
                    color: Qt.rgba(0, 0, 0, 0.35)
                    border.color: WallustColors.borderColor
                    border.width: 1
                }
                    onTextChanged: root.filterText = text

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            root.forceActiveFocus()
                            event.accepted = true
                        }
                    }
                }

            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: 172
                cellHeight: 108
                model: root.filteredPaths
                currentIndex: root.selectedIndex
                onCurrentIndexChanged: if (currentIndex >= 0) root.selectedIndex = currentIndex

                delegate: Item {
                    required property int index
                    required property string modelData
                    width: grid.cellWidth
                    height: grid.cellHeight

                    readonly property bool selected: index === root.selectedIndex

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 10
                        color: selected ? WallustColors.buttonHover : Qt.rgba(0, 0, 0, 0.25)
                        border.width: selected ? 2 : 1
                        border.color: selected ? WallustColors.workspaceActive : WallustColors.borderColor

                        Image {
                            anchors.fill: parent
                            anchors.margins: 6
                            source: "file://" + modelData
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            smooth: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.selectedIndex = index
                                root.applyPath(modelData)
                            }
                            onEntered: root.selectedIndex = index
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: "hjkl / arrows · gg first · G last · Enter apply · r random · / filter"
                    color: WallustColors.sapphire
                    font.family: SamaelStyle.fontFamily
                    font.pixelSize: Math.max(9, SamaelStyle.fontPixelSize - 1)
                }
            }
        }
    }

    Keys.onPressed: event => {
        const key = event.key
        const text = event.text

        if (key === Qt.Key_Escape) {
            GlobalStates.wallpaperSelectorOpen = false
            event.accepted = true
            return
        }
        if (key === Qt.Key_Slash) {
            searchField.forceActiveFocus()
            event.accepted = true
            return
        }
        if (key === Qt.Key_Return || key === Qt.Key_Enter) {
            if (filteredPaths.length > 0)
                root.applyPath(filteredPaths[selectedIndex])
            event.accepted = true
            return
        }

        // Vim motion (grid focus only — search field keeps normal typing)
        if (text === "h" || key === Qt.Key_Left) {
            vimMoveLeft()
            event.accepted = true
            return
        }
        if (text === "l" || key === Qt.Key_Right) {
            vimMoveRight()
            event.accepted = true
            return
        }
        if (text === "k" || key === Qt.Key_Up) {
            vimMoveUp()
            event.accepted = true
            return
        }
        if (text === "j" || key === Qt.Key_Down) {
            vimMoveDown()
            event.accepted = true
            return
        }
        if (text === "g" && !(event.modifiers & Qt.ShiftModifier)) {
            handleVimG()
            event.accepted = true
            return
        }
        if (text === "G" || (text === "g" && (event.modifiers & Qt.ShiftModifier))) {
            vimGoLast()
            event.accepted = true
            return
        }
        if (text === "r" || key === Qt.Key_R) {
            applyRandom()
            event.accepted = true
            return
        }
    }

    Connections {
        target: GlobalStates
        function onWallpaperSelectorOpenChanged() {
            if (GlobalStates.wallpaperSelectorOpen) {
                root.refreshList()
                root.forceActiveFocus()
            }
        }
    }
}