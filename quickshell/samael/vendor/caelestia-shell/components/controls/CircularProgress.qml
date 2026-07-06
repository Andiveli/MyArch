pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    property real value
    property int startAngle: -90
    property int sweepAngle: 360
    property int strokeWidth: Tokens.padding.small
    property int padding: 0
    property int spacing: Tokens.spacing.small
    property color fgColour: Colours.palette.m3primary
    property color bgColour: Colours.palette.m3secondaryContainer
    property alias hasEndIndicator: dot.active

    property bool wavy: false
    property alias waveFrequency: wave.frequency
    property real waveAmplitude: 0.55
    property bool wavePaused
    property alias waveDuration: waveProgAnim.duration

    readonly property real size: Math.min(width, height)
    readonly property real waveAmpMul: wavy ? waveAmplitude : 0
    readonly property real arcRadius: Math.max(8,
        (size - padding - strokeWidth * (1 + waveAmpMul * 2)) / 2)
    property real clampedVal: Math.max(1 / 360, Math.min(1, isNaN(value) ? 0 : value)) // Not readonly for animations
    readonly property real gapAngle: ((spacing + strokeWidth) / (arcRadius || 1)) * (180 / Math.PI)
    readonly property real dotAngleRad: (startAngle + sweepAngle - gapAngle * (sweepAngle < 360 ? 0 : 1)) * Math.PI / 180

    readonly property real thickness: strokeWidth * (1 + waveAmpMul) * 2 // For consumers
    property real implicitSize

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    Shape {
        preferredRendererType: Shape.CurveRenderer
        asynchronous: true
        opacity: Math.min(1, remainingArc.sweepAngle)

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.bgColour
            strokeWidth: Math.min(1, remainingArc.sweepAngle) * root.strokeWidth
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                id: remainingArc

                radiusX: root.arcRadius
                radiusY: root.arcRadius
                centerX: root.size / 2
                centerY: root.size / 2
                startAngle: root.startAngle + root.clampedVal * root.sweepAngle + root.gapAngle
                sweepAngle: Math.max(1 / 360, root.sweepAngle * (1 - root.clampedVal) - root.gapAngle * (root.sweepAngle < 360 ? 1 : 2))
            }

            Behavior on strokeColor {
                CAnim {}
            }
        }
    }

    WavyLine {
        id: wave

        anchors.fill: parent
        anchors.margins: -lineWidth * amplitudeMultiplier

        lineWidth: root.strokeWidth
        color: root.fgColour
        pathType: WavyLine.Arc
        radius: root.arcRadius
        startAngle: root.startAngle
        fullAngle: root.sweepAngle
        value: root.clampedVal
        frequency: 8
        amplitudeMultiplier: root.waveAmpMul

        Anim on waveProgress {
            id: waveProgAnim
            running: true
            paused: !root.wavy || root.wavePaused || root.waveAmpMul <= 0
            from: 0
            to: 1
            duration: 2000
            easing.type: Easing.Linear
            loops: Animation.Infinite
        }

        Behavior on color {
            CAnim {}
        }
    }

    Loader {
        id: dot

        x: root.size / 2 + root.arcRadius * Math.cos(root.dotAngleRad) - width / 2
        y: root.size / 2 + root.arcRadius * Math.sin(root.dotAngleRad) - height / 2

        sourceComponent: StyledRect {
            radius: Tokens.rounding.full
            color: root.fgColour
            opacity: Math.min(1, remainingArc.sweepAngle)
            implicitWidth: Math.min(1, remainingArc.sweepAngle) * Math.min(4, root.strokeWidth)
            implicitHeight: Math.min(1, remainingArc.sweepAngle) * Math.min(4, root.strokeWidth)
        }
    }
}
