import QtQuick

/** Fake password field for lock UI preview — no PAM, Esc closes overlay. */
Item {
    id: root

    Keys.onPressed: event => handleKey(event)

    property string buffer: ""
    property string statusText: ""
    property bool unlocking: false

    signal unlock()
    signal requestClose()

    function handleKey(event) {
        if (event.key === Qt.Key_Escape) {
            root.requestClose()
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.statusText = "Incorrect password. Please try again."
            failTimer.restart()
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Backspace) {
            if (event.modifiers & Qt.ControlModifier)
                root.buffer = ""
            else
                root.buffer = root.buffer.slice(0, -1)
            event.accepted = true
            return
        }
        const t = event.text
        if (t.length && /^[^\x00-\x1F\x7F-\x9F]+$/.test(t)) {
            root.buffer += t
            event.accepted = true
        }
    }

    Timer {
        id: failTimer
        interval: 4000
        onTriggered: root.statusText = ""
    }
}