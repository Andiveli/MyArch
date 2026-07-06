pragma ComponentBehavior: Bound

import QtQuick
import Qt5Compat.GraphicalEffects
import M3Shapes
import Quickshell.Services.Mpris
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.samael

/**
 * Bar media disc: cookie outline + cover image or fallback icon (no cava).
 */
Item {
    id: root

    readonly property alias shape: cookieShape

    readonly property var player: SamaelPlayers.active
    readonly property string artUrl: SamaelPlayers.getArtUrl(player)
    readonly property bool isPlaying: player?.playbackState === MprisPlaybackState.Playing

    /** Parent sets width/height; avoid implicitWidth ↔ width loop */
    implicitWidth: Tokens.sizes.dashboard.mediaCoverArtSize
    implicitHeight: implicitWidth

    MaterialShape {
        id: cookieShape
        anchors.centerIn: parent
        implicitSize: root.width > 0 ? root.width : root.implicitWidth
        shape: MaterialShape.Cookie12Sided
        color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
        z: 0

        Anim on rotation {
            running: true
            paused: !root.isPlaying
            from: 360
            to: 0
            duration: 23500
            easing.type: Easing.Linear
            loops: Animation.Infinite
        }
    }

    Item {
        id: artClip
        anchors.centerIn: parent
        width: parent.width * 0.88
        height: width
        z: 1

        Image {
            id: artImg
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            source: root.artUrl
            visible: status === Image.Ready && root.artUrl.length > 0
            layer.enabled: true
            layer.smooth: true
            layer.effect: OpacityMask {
                maskSource: Item {
                    width: artImg.width
                    height: artImg.height
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                    }
                }
            }
        }

        MaterialIcon {
            anchors.centerIn: parent
            z: 2
            grade: 200
            text: artImg.status === Image.Error ? "broken_image" : "art_track"
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.size(Math.max(parent.width * 0.38, 24)).build()
            visible: !artImg.visible
        }
    }
}