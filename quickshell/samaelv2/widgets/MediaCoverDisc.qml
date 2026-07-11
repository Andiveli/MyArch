import QtQuick
import Qt5Compat.GraphicalEffects
import M3Shapes
import Quickshell.Services.Mpris
import "../singletons"

/** Cookie9Sided + visible outline (stroke on a separate shape — mask hid it before). */
Item {
    id: root

    property var player: MprisPlayers.activePlayer
    property int side: 200

    width: side
    height: side
    implicitWidth: side
    implicitHeight: side

    readonly property string artUrl: MprisPlayers.getArtUrl(player)
    readonly property bool isPlaying: player?.playbackState === MprisPlaybackState.Playing

    Item {
        id: discSpin
        anchors.fill: parent

        RotationAnimation on rotation {
            running: root.isPlaying
            from: 360
            to: 0
            duration: 23500
            easing.type: Easing.Linear
            loops: Animation.Infinite
        }

        MaterialShape {
            id: cookieOutline
            anchors.centerIn: parent
            z: 3
            implicitSize: parent.width
            shape: MaterialShape.Cookie9Sided
            color: "transparent"
            strokeWidth: 3
            strokeColor: Qt.rgba(WallustColors.sky.r, WallustColors.sky.g, WallustColors.sky.b, 0.85)
        }

        Item {
            id: shapeWrapper
            anchors.fill: parent
            z: 1
            layer.enabled: true

            MaterialShape {
                anchors.centerIn: parent
                implicitSize: parent.width
                shape: MaterialShape.Cookie9Sided
                color: Qt.rgba(WallustColors.buttonColor.r, WallustColors.buttonColor.g,
                                WallustColors.buttonColor.b, 0.92)
                strokeWidth: 0
            }
        }

        Image {
            id: artImg
            z: 2
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
            cache: true
            source: root.artUrl
            visible: status === Image.Ready && root.artUrl.length > 0
            layer.enabled: true
            layer.smooth: true
            layer.effect: OpacityMask {
                maskSource: shapeWrapper
            }
        }

        Text {
            anchors.centerIn: parent
            z: 4
            visible: !artImg.visible
            text: artImg.status === Image.Error ? "\uf1f8" : "\uf001"
            font.family: Style.fontFamily
            font.pixelSize: Math.max(24, parent.width * 0.38)
            color: WallustColors.buttonHover
        }
    }
}