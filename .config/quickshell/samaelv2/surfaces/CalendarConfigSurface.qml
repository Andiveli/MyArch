import QtQuick
import QtQuick.Controls
import "../singletons"

/**
 * Calendar iCal setup — one URL per line → calendar-secrets.json (gitignored).
 * Esc back · Enter save (Ctrl+Enter newline in field) · r refresh
 */
FocusScope {
    id: root

    property bool open: false
    property real morphCloseness: 1

    readonly property real s: Math.max(0.85, Style.fontPixelSize / 11)
    readonly property real panelW: 440 * s
    readonly property real lineH: Math.max(18, urlField.font.pixelSize * 1.45)
    readonly property real fieldPad: 10 * s
    readonly property real fieldH: Math.max(lineH + fieldPad * 2,
        Math.min(lineH * 8 + fieldPad * 2, urlField.contentHeight + fieldPad * 2 + 4))

    signal requestClose()
    signal saved()

    property string draftText: ""
    property string statusLine: ""
    property string statusKind: "" // ok | err | wait
    property bool saving: false

    implicitWidth: panelW
    implicitHeight: column.height + 2 * s

    opacity: open ? Math.pow(morphCloseness, 1.2) : 0
    visible: opacity > 0.02
    enabled: open
    focus: open

    function syncDraftFromService() {
        const list = CalendarService.savedIcalUrls || []
        draftText = list.join("\n")
        statusLine = ""
        statusKind = ""
    }

    function urlsFromDraft() {
        const lines = draftText.split("\n")
        const out = []
        for (let i = 0; i < lines.length; i++) {
            const u = lines[i].trim()
            if (u.length > 0 && (u.indexOf("http://") === 0 || u.indexOf("https://") === 0))
                out.push(u)
        }
        return out
    }

    function setStatus(kind, msg) {
        statusKind = kind
        statusLine = msg
    }

    function doSave() {
        if (saving)
            return
        const urls = urlsFromDraft()
        if (!urls.length) {
            setStatus("err", "No valid URL — paste a line starting with https://")
            return
        }
        saving = true
        setStatus("wait", "Saving " + urls.length + " feed(s)…")
        CalendarService.saveSecrets(urls, ok => {
            saving = false
            if (!ok) {
                setStatus("err", CalendarService.secretsSaveError || "Save failed")
                return
            }
            setStatus("wait", "Saved · loading calendar…")
            CalendarService.refresh()
            saved()
        })
    }

    Connections {
        target: CalendarService
        function onRevisionChanged() {
            if (!root.open)
                return
            if (root.statusKind !== "wait")
                return
            if (!root.statusLine.length || root.statusLine.indexOf("Saved") < 0)
                return
            if (CalendarService.loading)
                return
            if (CalendarService.configured) {
                const n = CalendarService.events.length
                setStatus("ok", "Ready — " + n + " event(s) loaded · Esc back to calendar")
            } else if (CalendarService.lastError.length) {
                setStatus("err", "Saved but fetch failed: " + CalendarService.lastError)
            } else {
                setStatus("ok", "Saved · no events in range (or empty calendar)")
            }
        }
    }

    onOpenChanged: {
        if (open) {
            CalendarService.reloadSecrets()
            syncDraftFromService()
            Qt.callLater(() => urlField.forceActiveFocus())
        }
    }

    Keys.onPressed: event => {
        if (!open)
            return
        if (event.key === Qt.Key_Escape) {
            requestClose()
            event.accepted = true
        }
    }

    Column {
        id: column
        width: root.panelW
        spacing: 8 * root.s

        Text {
            text: "Calendar feeds"
            color: WallustColors.moduleText
            font.family: Style.fontFamily
            font.pixelSize: 13 * root.s
            font.bold: true
        }
        Text {
            width: parent.width
            wrapMode: Text.Wrap
            text: "Secret iCal URL — one per line. Enter saves · Ctrl+Enter new line."
            color: WallustColors.moduleText
            opacity: 0.5
            font.family: Style.fontFamily
            font.pixelSize: 9 * root.s
        }

        Rectangle {
            id: fieldBlock
            width: parent.width
            height: root.fieldH
            radius: 8 * root.s
            color: Qt.rgba(0, 0, 0, 0.22)
            border.width: 1
            border.color: urlField.activeFocus
                ? Qt.alpha(WallustColors.buttonHover, 0.65)
                : Qt.rgba(WallustColors.borderColor.r, WallustColors.borderColor.g, WallustColors.borderColor.b, 0.4)
            clip: true

            Behavior on height {
                NumberAnimation { duration: Motion.fast; easing.type: Easing.OutCubic }
            }

            TextArea {
                id: urlField
                anchors.fill: parent
                anchors.margins: root.fieldPad
                wrapMode: TextArea.Wrap
                selectByMouse: true
                placeholderText: "https://calendar.google.com/calendar/ical/…/basic.ics"
                placeholderTextColor: Qt.rgba(WallustColors.moduleText.r, WallustColors.moduleText.g,
                    WallustColors.moduleText.b, 0.35)
                color: WallustColors.moduleText
                font.family: Style.fontFamily
                font.pixelSize: 10.5 * root.s
                background: null
                text: root.draftText
                onTextChanged: root.draftText = text
                padding: 0

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (event.modifiers & (Qt.ControlModifier | Qt.MetaModifier)) {
                            const pos = selectionStart
                            text = text.slice(0, pos) + "\n" + text.slice(selectionEnd)
                            selectionStart = selectionEnd = pos + 1
                            event.accepted = true
                            return
                        }
                        root.doSave()
                        event.accepted = true
                        return
                    }
                    if (event.key === Qt.Key_Escape) {
                        root.requestClose()
                        event.accepted = true
                    }
                    if (event.text === "r" || event.text === "R") {
                        CalendarService.refresh()
                        root.setStatus("wait", "Refreshing feeds…")
                        event.accepted = true
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            radius: 6 * root.s
            color: {
                if (root.statusKind === "ok")
                    return Qt.alpha(WallustColors.teal, 0.18)
                if (root.statusKind === "err")
                    return Qt.alpha(WallustColors.red, 0.15)
                if (root.statusKind === "wait")
                    return Qt.alpha(WallustColors.buttonHover, 0.12)
                return Qt.rgba(1, 1, 1, 0.03)
            }
            border.width: root.statusLine.length ? 1 : 0
            border.color: root.statusKind === "err" ? Qt.alpha(WallustColors.red, 0.45)
                : (root.statusKind === "ok" ? Qt.alpha(WallustColors.teal, 0.4) : WallustColors.borderColor)
            implicitHeight: feedbackText.height + 14 * root.s

            Row {
                id: feedbackRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 8 * root.s
                spacing: 8 * root.s

                BusyIndicator {
                    id: saveSpinner
                    visible: root.saving || (root.statusKind === "wait"
                        && (CalendarService.loading || root.statusLine.indexOf("Saving") >= 0))
                    width: 14 * root.s
                    height: 14 * root.s
                    running: visible
                }

                Text {
                    id: feedbackText
                    width: Math.max(0, feedbackRow.width - (saveSpinner.visible ? saveSpinner.width + 8 * root.s : 0))
                    text: root.statusLine.length ? root.statusLine
                        : (CalendarService.configured
                            ? (CalendarService.events.length + " events cached · Enter to update URLs")
                            : "Paste URL · Enter to save")
                    color: root.statusKind === "err" ? WallustColors.red
                        : (root.statusKind === "ok" ? WallustColors.teal : WallustColors.moduleText)
                    opacity: root.statusLine.length ? 1 : 0.5
                    font.family: Style.fontFamily
                    font.pixelSize: 9.5 * root.s
                    font.bold: root.statusKind === "ok" || root.statusKind === "err"
                    wrapMode: Text.Wrap
                }
            }
        }

        Text {
            width: parent.width
            text: "Esc back to month view"
            color: WallustColors.moduleText
            opacity: 0.32
            font.family: Style.fontFamily
            font.pixelSize: 8.5 * root.s
        }
    }
}