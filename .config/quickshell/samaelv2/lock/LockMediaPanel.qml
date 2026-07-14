import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../singletons"
import "../widgets"

/** Caelestia lock/Media.qml — altura por contenido, no strip fijo */
Item {
    id: root

    readonly property real s: Math.max(0.85, Style.fontPixelSize / 11)
    readonly property var player: MprisPlayers.activePlayer
    readonly property real hPad: 14 * s
    readonly property real vPad: 12 * s

    implicitWidth: 200 * s
    implicitHeight: inner.implicitHeight + vPad * 2
    width: implicitWidth
    height: implicitHeight
    clip: true

    Rectangle {
        anchors.fill: parent
        radius: ShellConfig.cornerRadius
        color: WallustColors.moduleBackground
        clip: true

        Image {
            id: artBg
            anchors.fill: parent
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            source: player ? MprisPlayers.getArtUrl(player) : ""
            opacity: status === Image.Ready && source.length > 0 ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: Motion.standard }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: artBg.opacity > 0
                ? Qt.rgba(WallustColors.moduleBackground.r, WallustColors.moduleBackground.g,
                    WallustColors.moduleBackground.b, 0.7)
                : WallustColors.moduleBackground
        }

        ColumnLayout {
            id: inner
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: hPad
            anchors.rightMargin: hPad
            spacing: 4 * s

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: StringUtils.cleanMusicTitle(player?.trackTitle)
                    || (player ? qsTr("Unknown track") : qsTr("Nothing playing"))
                color: WallustColors.sky
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize + 2
                font.bold: true
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: player
                    ? (player.trackArtist || qsTr("Unknown artist"))
                    : qsTr("Try playing some music!")
                color: WallustColors.buttonHover
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 6 * s
                spacing: 6 * s

                MediaControlButton {
                    glyph: "\uf048"
                    diameter: Math.round(32 * s)
                    enabled: player?.canGoPrevious ?? false
                    onClicked: player?.previous()
                }
                MediaControlButton {
                    glyph: player?.isPlaying ? "\uf04c" : "\uf04b"
                    diameter: Math.round(38 * s)
                    primary: true
                    enabled: player?.canTogglePlaying ?? false
                    checked: player?.isPlaying ?? false
                    onClicked: player?.togglePlaying()
                }
                MediaControlButton {
                    glyph: "\uf051"
                    diameter: Math.round(32 * s)
                    enabled: player?.canGoNext ?? false
                    onClicked: player?.next()
                }
            }
        }
    }
}