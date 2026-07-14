import QtQuick
import Quickshell
import Quickshell.Wayland
import "./LockPanelVisual.qml"
import "./LockPreviewPam.qml"

PanelWindow {
    id: root

    /** Injected by Variants { model: Quickshell.screens } */
    required property var modelData

    property bool active: false

    visible: active
    screen: modelData
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:samaelv2:lock-preview"
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; left: true; right: true; bottom: true }

    FocusScope {
        id: keyRoot
        anchors.fill: parent
        focus: root.active

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.active = false
                event.accepted = true
                return
            }
            previewPam.handleKey(event)
        }

        LockPreviewPam {
            id: previewPam
            onRequestClose: root.active = false
        }

        LockPanelVisual {
            id: visual
            anchors.fill: parent
            screen: modelData
            pamHost: previewPam
            designMode: true
            onRequestClose: root.active = false
        }
    }

    onActiveChanged: {
        if (active) {
            Qt.callLater(() => {
                keyRoot.forceActiveFocus()
                visual.playLockIn()
            })
        }
    }
}