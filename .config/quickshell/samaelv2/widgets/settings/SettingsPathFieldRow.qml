import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../singletons"

/** Directory path row — vim row + field edit; Tab completion; suggestions list. */
SettingsConnectedRow {
    id: root

    readonly property bool settingsFocusable: true
    readonly property bool settingsPathFieldRow: true

    property string label: "Folder"
    property string placeholder: "~/Videos"
    property var pathKey: ["record", "saveDir"]
    property var defaultValue: "~/Videos"

    property var suggestions: []
    property string inlineCompletion: ""
    property int suggestPick: 0

    function draftValue() {
        const v = ShellConfigService.getDraftPath(pathKey, defaultValue)
        return v === null || v === undefined ? String(defaultValue) : String(v)
    }

    function blurPathField() {
        pathField.focus = false
        suggestions = []
        inlineCompletion = ""
        suggestPick = 0
        completeProc.running = false
    }

    function focusPathField() {
        pathField.forceActiveFocus()
        pathField.selectAll()
        scheduleComplete()
    }

    function trigger() {
        focusPathField()
    }

    readonly property bool pathFieldActive: pathField.activeFocus

    function scheduleComplete() {
        completeDebounce.restart()
    }

    function applySuggestion(path) {
        let p = path
        if (p.length && !p.endsWith("/"))
            p += "/"
        pathField.text = p
        ShellConfigService.setDraftPath(root.pathKey, p)
        inlineCompletion = ""
        suggestions = []
        suggestPick = 0
    }

    function applyInlineCompletion() {
        if (!inlineCompletion.length)
            return false
        pathField.text = inlineCompletion
        ShellConfigService.setDraftPath(root.pathKey, inlineCompletion)
        inlineCompletion = ""
        scheduleComplete()
        return true
    }

    function bumpSuggestion(delta) {
        if (!suggestions.length)
            return
        suggestPick = (suggestPick + delta + suggestions.length) % suggestions.length
    }

    implicitHeight: col.implicitHeight + (suggestBox.visible ? suggestBox.implicitHeight + 4 : 0) + 14

    Timer {
        id: completeDebounce
        interval: 120
        onTriggered: {
            const q = pathField.text
            completeProc.command = ["python3", Quickshell.shellPath("scripts/path-complete.py"), q]
            completeProc.running = true
        }
    }

    Process {
        id: completeProc
        stdout: StdioCollector { id: completeOut }
        onExited: (code) => {
            if (code !== 0 || !pathField.activeFocus)
                return
            try {
                const j = JSON.parse(completeOut.text || "{}")
                root.suggestions = j.suggestions || []
                root.inlineCompletion = j.completion || ""
                root.suggestPick = 0
            } catch (e) {
                root.suggestions = []
                root.inlineCompletion = ""
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        propagateComposedEvents: true
        onPressed: mouse => {
            if (mouse.button === Qt.LeftButton)
                root.focusPathField()
            mouse.accepted = false
        }
    }

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 6

        Text {
            Layout.fillWidth: true
            text: root.label
            color: WallustColors.moduleText
            opacity: 0.55
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize - 2
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 32

            Text {
                id: ghostText
                anchors.left: pathField.left
                anchors.verticalCenter: pathField.verticalCenter
                anchors.leftMargin: 8
                visible: pathField.activeFocus && root.inlineCompletion.length > pathField.text.length
                        && root.inlineCompletion.toLowerCase().startsWith(pathField.text.toLowerCase())
                text: {
                    const t = pathField.text
                    const c = root.inlineCompletion
                    if (c.length <= t.length)
                        return ""
                    return t + c.slice(t.length)
                }
                color: WallustColors.moduleText
                opacity: 0.28
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize
            }

            TextField {
                id: pathField
                anchors.fill: parent
                text: root.draftValue()
                placeholderText: root.placeholder
                color: WallustColors.moduleText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize
                selectByMouse: true
                onTextEdited: {
                    ShellConfigService.setDraftPath(root.pathKey, text)
                    root.scheduleComplete()
                }
                onActiveFocusChanged: {
                    if (activeFocus)
                        selectAll()
                    else {
                        root.suggestions = []
                        root.inlineCompletion = ""
                    }
                }
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Tab) {
                        if (event.modifiers & Qt.ShiftModifier) {
                            if (root.suggestions.length)
                                root.bumpSuggestion(-1)
                        } else if (root.applyInlineCompletion()) {
                            event.accepted = true
                            return
                        } else if (root.suggestions.length) {
                            root.applySuggestion(root.suggestions[root.suggestPick])
                            event.accepted = true
                            return
                        }
                    }
                    if (event.key === Qt.Key_Down && root.suggestions.length) {
                        root.bumpSuggestion(1)
                        event.accepted = true
                        return
                    }
                    if (event.key === Qt.Key_Up && root.suggestions.length) {
                        root.bumpSuggestion(-1)
                        event.accepted = true
                        return
                    }
                    if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && root.suggestions.length) {
                        root.applySuggestion(root.suggestions[root.suggestPick])
                        root.blurPathField()
                        event.accepted = true
                        return
                    }
                    if (event.key === Qt.Key_Escape) {
                        root.blurPathField()
                        event.accepted = true
                        return
                    }
                }
                background: Rectangle {
                    radius: 6
                    color: Qt.rgba(0, 0, 0, 0.25)
                    border.width: pathField.activeFocus ? 2 : 1
                    border.color: pathField.activeFocus ? WallustColors.accent : WallustColors.borderColor
                }
            }
        }

        ColumnLayout {
            id: suggestBox
            Layout.fillWidth: true
            spacing: 2
            visible: pathField.activeFocus && root.suggestions.length > 0

            Repeater {
                model: Math.min(6, root.suggestions.length)
                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 22
                    radius: 4
                    color: index === root.suggestPick
                        ? Qt.rgba(WallustColors.accent.r, WallustColors.accent.g, WallustColors.accent.b, 0.18)
                        : Qt.rgba(0, 0, 0, 0.12)
                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 6
                        verticalAlignment: Text.AlignVCenter
                        text: root.suggestions[index]
                        elide: Text.ElideMiddle
                        color: WallustColors.moduleText
                        opacity: index === root.suggestPick ? 1 : 0.75
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize - 2
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.suggestPick = index
                            root.applySuggestion(root.suggestions[index])
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: ShellConfigService
        function onRevisionChanged() {
            if (!pathField.activeFocus)
                pathField.text = root.draftValue()
        }
    }
}