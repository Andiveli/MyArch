import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.samael

SamaelPillSurface {
    id: surface

    mTop: 0
    mLeft: 0
    mRight: 0
    mBottom: 0

    onRequestClose: {
        GlobalStates.samaelRecorderOpen = false
        if (recording) stopRecording()
    }

    implicitWidth: 340
    implicitHeight: 260

    readonly property var modes: [
        { label: "Fullscreen", icon: "󰊨" },
        { label: "Region",     icon: "󰆟" },
        { label: "Window",     icon: "" }
    ]

    property int selectedMode: 0
    property bool recording: false

    function startRecording() {
        const mode = modes[selectedMode].label.toLowerCase()
        // TODO: wire to actual recording command
        Quickshell.execDetached(["bash", "-c",
            `notify-send "Recording started" "Mode: ${mode}"`])
        recording = true
    }

    function stopRecording() {
        // TODO: wire to actual recording stop command
        Quickshell.execDetached(["bash", "-c",
            `notify-send "Recording stopped"`])
        recording = false
    }

    function toggleRecording() {
        if (recording) stopRecording()
        else startRecording()
    }

    // ── Keyboard API ──

    function moveH(dir) {
        if (recording) return
        const n = modes.length
        selectedMode = (selectedMode + dir + n) % n
    }

    function moveV(dir) {
        // single row, no vertical navigation needed
    }

    function activate() {
        toggleRecording()
    }

    function back() {
        return false
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: SamaelStyle.menuPanelFill
        border.width: 2
        border.color: WallustColors.borderColor

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Text {
                text: "󰄀 Screen Recorder"
                color: WallustColors.moduleText
                font.family: SamaelStyle.fontFamily
                font.pixelSize: SamaelStyle.fontPixelSize + 2
            }

            // Mode selector
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: surface.modes

                    Rectangle {
                        required property int index
                        required property var modelData

                        Layout.fillWidth: true
                        height: 48
                        radius: 10
                        color: index === surface.selectedMode
                            ? WallustColors.buttonHover
                            : Qt.rgba(0, 0, 0, 0.25)
                        border.width: index === surface.selectedMode ? 1 : 0
                        border.color: WallustColors.workspaceActive

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.icon
                                color: index === surface.selectedMode
                                    ? WallustColors.moduleText
                                    : WallustColors.buttonHover
                                font.pixelSize: 20
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                color: index === surface.selectedMode
                                    ? WallustColors.moduleText
                                    : WallustColors.sapphire
                                font.family: SamaelStyle.fontFamily
                                font.pixelSize: Math.max(9, SamaelStyle.fontPixelSize - 2)
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: surface.selectedMode = index
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // Start/Stop button
            Rectangle {
                Layout.fillWidth: true
                height: 48
                radius: 12
                color: surface.recording ? "#E74C3C" : "#27AE60"

                Text {
                    anchors.centerIn: parent
                    text: surface.recording ? "■ Stop Recording" : "● Start Recording"
                    color: "white"
                    font.family: SamaelStyle.fontFamily
                    font.pixelSize: SamaelStyle.fontPixelSize
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: surface.toggleRecording()
                }
            }

            Text {
                text: "h/l · mode · Enter start/stop · Esc close"
                color: WallustColors.buttonHover
                font.family: SamaelStyle.fontFamily
                font.pixelSize: 9
            }
        }
    }
}
