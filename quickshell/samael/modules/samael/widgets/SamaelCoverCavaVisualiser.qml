pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import M3Shapes
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.samael

/**
 * Same structure as Caelestia dashboard/media/CoverVisualiser.qml:
 * one Item with radial Shape bars anchored to cover.shape + cover art centered.
 */
Item {
    id: root

    property int coverSize: Tokens.sizes.dashboard.mediaCoverArtSize
    property bool playing: true

    readonly property alias cover: cover

    readonly property int barCount: (typeof GlobalConfig !== "undefined" && GlobalConfig.services)
        ? GlobalConfig.services.visualiserBars
        : 64

    readonly property real centerX: width / 2
    readonly property real centerY: height / 2
    readonly property real spacing: Tokens.spacing.medium

    implicitWidth: coverSize + Tokens.spacing.large * 4
    implicitHeight: implicitWidth

    readonly property real maxMagnitude: Math.max(8, (width - cover.implicitWidth) / 2 - spacing)

    property int _cavaTick: 0

    function barValue(index) {
        const vals = CavaService.bars
        if (!vals.length)
            return playing ? 0.05 : 1e-2
        const srcIdx = Math.floor(index * vals.length / barCount) % vals.length
        return Math.max(1e-2, Math.min(1, vals[srcIdx] * 1.2 + 0.04))
    }

    Shape {
        z: 0
        anchors.fill: parent
        asynchronous: true
        preferredRendererType: Shape.CurveRenderer
        data: bars.instances
        opacity: playing ? 1 : 0.45
    }

    Variants {
        id: bars
        model: Array.from({ length: root.barCount }, (_, i) => i)

        ShapePath {
            id: bar
            required property int modelData

            readonly property real value: {
                root._cavaTick
                return root.barValue(modelData)
            }
            readonly property real angle: modelData * 2 * Math.PI / root.barCount
            readonly property real shapeEdgeDist: {
                cover.shape.rotation
                const sDist = cover.shape.distanceAtAngle(
                    modelData * 360 / root.barCount + 90)
                return sDist + root.spacing + strokeWidth / 2
            }
            readonly property real dist: shapeEdgeDist + value * root.maxMagnitude
            readonly property real cos: Math.cos(angle)
            readonly property real sin: Math.sin(angle)

            asynchronous: true
            capStyle: root.Tokens.rounding.scale === 0 ? ShapePath.SquareCap : ShapePath.RoundCap
            strokeWidth: 360 / root.barCount - root.Tokens.spacing.small / 4
            strokeColor: Colours.palette.m3primary

            startX: root.centerX + shapeEdgeDist * cos
            startY: root.centerY + shapeEdgeDist * sin

            PathLine {
                x: root.centerX + bar.dist * bar.cos
                y: root.centerY + bar.dist * bar.sin
            }

            Behavior on strokeColor {
                CAnim {}
            }
        }
    }

    SamaelCoverArt {
        id: cover
        z: 1
        anchors.centerIn: parent
        width: root.coverSize
        height: root.coverSize
    }

    Connections {
        target: CavaService
        function onBarsChanged() {
            root._cavaTick++
        }
    }

    Timer {
        interval: 60
        running: GlobalStates.barOpen || GlobalStates.samaelMediaControlsOpen
        repeat: true
        onTriggered: root._cavaTick++
    }
}