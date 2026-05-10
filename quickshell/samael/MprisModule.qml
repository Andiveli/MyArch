import QtQuick
import Quickshell
import Quickshell.Services.Mpris

/**
 * Módulo Mpris mejorado - estilo Waybar Samael
 * Usa el servicio nativo Mpris de Quickshell (sin polling)
 * Se oculta cuando no hay ningún reproductor activo
 */
Item {
    id: root

    readonly property MprisPlayer activePlayer: Mpris.players.values[0] ?? null
    readonly property bool hasPlayer: activePlayer !== null
    readonly property bool isPlaying: activePlayer?.isPlaying ?? false
    readonly property string playerName: activePlayer?.identity ?? "Sin reproductor"
    readonly property string title: activePlayer?.trackTitle ?? ""
    readonly property string artist: activePlayer?.trackArtist ?? ""
    readonly property real position: activePlayer?.position ?? 0
    readonly property real length: activePlayer?.length ?? 0
    readonly property real progress: length > 0 ? (position / length) : 0

    readonly property string displayText: {
        if (!hasPlayer) return ""
        if (title !== "" && artist !== "") return artist + " - " + title
        if (title !== "") return title
        return playerName
    }

    // Width is 0 when no player (collapses)
    readonly property real contentWidth: hasPlayer ? (row.width + 20) : 0

    implicitWidth: contentWidth
    implicitHeight: hasPlayer ? 28 : 0

    clip: true

    // Smooth show/hide animation
    Behavior on implicitHeight { NumberAnimation { duration: 200 } }
    Behavior on implicitWidth { NumberAnimation { duration: 200 } }

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

        // Progress circular
        Rectangle {
            width: 20
            height: 20
            radius: 10
            color: "transparent"
            border.width: 2
            border.color: "#a6e3a1"

            Rectangle {
                anchors {
                    bottom: parent.bottom
                    left: parent.left
                }
                width: parent.width * progress
                height: 2
                color: "#a6e3a1"
            }

            Text {
                anchors.centerIn: parent
                text: isPlaying ? "" : ""
                font.pixelSize: 10
                font.family: "JetBrainsMono Nerd Font"
                color: "#a6e3a1"
            }
        }

        Text {
            text: displayText
            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"
            color: "#e5d9f5"
            elide: Text.ElideRight
            maximumLineCount: 1
            width: 180
        }
    }

    // Tooltip con detalles + controles
    MouseArea {
        id: tooltipArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: hasPlayer ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

        onClicked: (mouse) => {
            if (!hasPlayer) return

            if (mouse.button === Qt.LeftButton) {
                if (activePlayer.canTogglePlaying) {
                    activePlayer.togglePlaying()
                }
            } else if (mouse.button === Qt.MiddleButton) {
                if (activePlayer.canGoNext) {
                    activePlayer.next()
                }
            }
        }

        onWheel: {
            if (!hasPlayer) return

            if (wheel.angleDelta.y > 0) {
                if (activePlayer.canGoNext) {
                    activePlayer.next()
                }
            } else {
                if (activePlayer.canGoPrevious) {
                    activePlayer.previous()
                }
            }
        }

        Rectangle {
            visible: parent.containsMouse && hasPlayer
            y: -50
            height: 40
            color: "#1a1a2e"
            radius: 6
            border.width: 1
            border.color: "#f700ff"
            anchors { horizontalCenter: parent.horizontalCenter }

            Column {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    text: title || playerName
                    font.pixelSize: 11
                    font.family: "JetBrainsMono Nerd Font"
                    color: "#e5d9f5"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: artist
                    font.pixelSize: 9
                    font.family: "JetBrainsMono Nerd Font"
                    color: "#a6e3a1"
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: artist !== ""
                }
            }

            Behavior on opacity { NumberAnimation { duration: 150 } }
            opacity: parent.containsMouse ? 1 : 0
        }
    }

    // Update position timer for smooth progress
    Timer {
        running: hasPlayer && isPlaying
        interval: 1000
        repeat: true
        onTriggered: {
            if (activePlayer) {
                const dummy = activePlayer.position
            }
        }
    }
}
