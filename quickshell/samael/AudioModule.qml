import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Módulo de audio + micrófono - estilo Waybar
 * Usa Pipewire si está disponible, sino fallback a wpctl
 */
Item {
    id: root

    // Try to use Pipewire first, fall back to wpctl
    readonly property bool usePipewire: {
        try {
            // Check if Pipewire service exists and has defaultAudioSink
            return Pipewire && Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio
        } catch (e) {
            return false
        }
    }

    readonly property real sinkVolume: {
        if (usePipewire) {
            return Math.round((Pipewire.defaultAudioSink?.audio?.volume ?? 0) * 100)
        }
        return Math.round(volumeValue * 100)
    }

    readonly property bool sinkMuted: {
        if (usePipewire) {
            return Pipewire.defaultAudioSink?.audio?.muted ?? false
        }
        return mutedValue
    }

    readonly property real sourceVolume: {
        if (usePipewire) {
            return Math.round((Pipewire.defaultAudioSource?.audio?.volume ?? 0) * 100)
        }
        return Math.round(micVolumeValue * 100)
    }

    readonly property bool sourceMuted: {
        if (usePipewire) {
            return Pipewire.defaultAudioSource?.audio?.muted ?? false
        }
        return micMutedValue
    }

    // Fallback properties for wpctl
    property real volumeValue: 0
    property bool mutedValue: false
    property real micVolumeValue: 0
    property bool micMutedValue: false

    implicitWidth: row.width + 20
    implicitHeight: 28

    clip: true

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        radius: 15
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: 2
        border.color: "#f700ff"
        radius: 15
    }

    Row {
        id: row
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            leftMargin: 10
        }
        spacing: 6

        Text {
            text: sinkMuted ? "󰸈" : ""
            font.pixelSize: 14
            font.family: "JetBrainsMono Nerd Font"
            color: "#ff00bf"
        }

        Text {
            text: sinkMuted ? "MUTED" : `${sinkVolume}%`
            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"
            color: "#e5d9f5"
        }

        Text {
            text: "|"
            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"
            color: "#e5d9f5"
        }

        Text {
            text: sourceMuted ? "󰍺" : "󰍹"
            font.pixelSize: 14
            font.family: "JetBrainsMono Nerd Font"
            color: "#89b4fa"
        }

        Text {
            text: sourceMuted ? "MUTED" : `${sourceVolume}%`
            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"
            color: "#e5d9f5"
        }
    }

    // Tooltip
    MouseArea {
        id: tooltipArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: toggleMute()

        Rectangle {
            visible: parent.containsMouse
            y: -35
            height: 24
            color: "#1a1a2e"
            radius: 6
            border.width: 1
            border.color: "#f700ff"
            anchors { horizontalCenter: parent.horizontalCenter }

            Text {
                anchors.centerIn: parent
                text: sinkMuted ? "Silenciado" : "Volumen: " + sinkVolume + "%"
                font.pixelSize: 11
                font.family: "JetBrainsMono Nerd Font"
                color: "#e5d9f5"
            }

            Behavior on opacity { NumberAnimation { duration: 150 } }
            opacity: parent.containsMouse ? 1 : 0
        }

        onWheel: {
            if (wheel.angleDelta.y > 0) {
                changeVolume(0.05)
            } else {
                changeVolume(-0.05)
            }
        }
    }

    readonly property string tooltipText: sinkMuted ? "Silenciado" : "Volumen: " + sinkVolume + "%"

    // Fallback polling for wpctl (only active if Pipewire not available)
    // Using 200ms interval for near-instant updates (sincronizado con sidebar)
    Timer {
        interval: 200
        running: !usePipewire
        repeat: true
        onTriggered: {
            volumeProcess.running = true
            muteProcess.running = true
            micVolumeProcess.running = true
            micMuteProcess.running = true
        }
    }

    // Get sink volume (fallback)
    Process {
        id: volumeProcess
        running: false
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | sed 's/.*Volume: *\\([0-9.]*\\).*/\\1/'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parsed = parseFloat(this.text.trim())
                if (!isNaN(parsed)) {
                    volumeValue = parsed
                }
            }
        }
    }

    // Get sink mute status (fallback)
    Process {
        id: muteProcess
        running: false
        command: ["bash", "-c", "wpctl get-mute @DEFAULT_AUDIO_SINK@ | grep -q 'Muted: YES' && echo '1' || echo '0'"]
        stdout: StdioCollector {
            onStreamFinished: {
                mutedValue = this.text.trim() === '1'
            }
        }
    }

    // Get mic volume (fallback)
    Process {
        id: micVolumeProcess
        running: false
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | sed 's/.*Volume: *\\([0-9.]*\\).*/\\1/'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parsed = parseFloat(this.text.trim())
                if (!isNaN(parsed)) {
                    micVolumeValue = parsed
                }
            }
        }
    }

    // Get mic mute status (fallback)
    Process {
        id: micMuteProcess
        running: false
        command: ["bash", "-c", "wpctl get-mute @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -q 'Muted: YES' && echo '1' || echo '0'"]
        stdout: StdioCollector {
            onStreamFinished: {
                micMutedValue = this.text.trim() === '1'
            }
        }
    }

    function toggleMute() {
        if (usePipewire) {
            const sink = Pipewire.defaultAudioSink
            if (sink && sink.audio) {
                sink.audio.muted = !sink.audio.muted
            }
        } else {
            Quickshell.execDetached(["bash", "-c", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"])
            Qt.callLater(() => {
                volumeProcess.running = true
                muteProcess.running = true
            })
        }
    }

    function changeVolume(delta) {
        if (usePipewire) {
            const sink = Pipewire.defaultAudioSink
            if (sink && sink.audio) {
                const newVolume = Math.max(0, Math.min(2.0, sink.audio.volume + delta))
                sink.audio.volume = newVolume
            }
        } else {
            Quickshell.execDetached(["bash", "-c", "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (delta > 0 ? "0.05+" : "0.05-")])
            Qt.callLater(() => {
                volumeProcess.running = true
                muteProcess.running = true
            })
        }
    }

    Component.onCompleted: {
        if (!usePipewire) {
            console.log("AudioModule: Pipewire not available, using wpctl fallback")
            // Initial fetch
            volumeProcess.running = true
            muteProcess.running = true
            micVolumeProcess.running = true
            micMuteProcess.running = true
        } else {
            console.log("AudioModule: Using Pipewire")
        }
    }
}
