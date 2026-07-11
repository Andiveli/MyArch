import QtQuick
import QtQuick.Shapes
import "../singletons"

/**
 * Port of Caelestia CircularProgress (wavy arc) — Shape + Canvas only.
 * Reference: vendor caelestia-shell/components/controls/CircularProgress.qml
 */
Item {
    id: root

    property real value: 0
    property int startAngle: -90
    property int sweepAngle: 180
    property real strokeWidth: 5
    property int spacing: 4
    property color fgColor: WallustColors.sky
    property color bgColor: Qt.rgba(fgColor.r, fgColor.g, fgColor.b, 0.28)

    property bool waveActive: false
    property int waveFrequency: 8
    property real waveAmplitude: 0.65
    property int waveDuration: 2000

    width: 200
    height: 200

    readonly property real size: Math.min(width, height)
    readonly property real waveAmpMul: waveActive ? waveAmplitude : 0
    readonly property real arcRadius: Math.max(8,
        (size - strokeWidth * (1 + waveAmpMul * 2)) / 2)
    readonly property real clampedVal: Math.max(1 / 360, Math.min(1, isNaN(value) ? 0 : value))
    readonly property real gapAngle: ((spacing + strokeWidth) / (arcRadius || 1)) * (180 / Math.PI)
    readonly property real dotAngleRad: (startAngle + sweepAngle - gapAngle * (sweepAngle < 360 ? 0 : 1)) * Math.PI / 180

    Shape {
        preferredRendererType: Shape.CurveRenderer
        anchors.fill: parent
        opacity: Math.min(1, remainingArc.sweepAngle)

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.bgColor
            strokeWidth: Math.min(1, remainingArc.sweepAngle) * root.strokeWidth
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                id: remainingArc
                radiusX: root.arcRadius
                radiusY: root.arcRadius
                centerX: root.size / 2
                centerY: root.size / 2
                startAngle: root.startAngle + root.clampedVal * root.sweepAngle + root.gapAngle
                sweepAngle: Math.max(1 / 360, root.sweepAngle * (1 - root.clampedVal)
                    - root.gapAngle * (root.sweepAngle < 360 ? 1 : 2))
            }
        }
    }

    Canvas {
        id: waveArc
        anchors.fill: parent
        property real waveProgress: 0

        onWaveProgressChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            if (root.clampedVal <= 0)
                return
            if (root.waveAmpMul > 0)
                drawWavyArc(ctx)
            else
                drawPlainArc(ctx)
        }

        function drawPlainArc(ctx) {
            const cx = root.size / 2
            const cy = root.size / 2
            const r = root.arcRadius
            const start = root.startAngle * Math.PI / 180
            const span = root.sweepAngle * root.clampedVal * Math.PI / 180
            ctx.strokeStyle = root.fgColor
            ctx.lineWidth = root.strokeWidth
            ctx.lineCap = "round"
            ctx.beginPath()
            ctx.arc(cx, cy, r, start, start + span, false)
            ctx.stroke()
        }

        function drawWavyArc(ctx) {
            const cx = root.size / 2
            const cy = root.size / 2
            const radius = root.arcRadius
            const startRad = root.startAngle * Math.PI / 180
            const drawAngleRad = root.sweepAngle * Math.PI / 180 * root.clampedVal
            if (drawAngleRad <= 0)
                return
            const phase = waveProgress * 2 * Math.PI
            const amp = root.strokeWidth * root.waveAmpMul
            const len = root.arcRadius * root.sweepAngle * Math.PI / 180
            const N = Math.max(64, Math.ceil(radius * drawAngleRad))
            const dTheta = drawAngleRad / N
            ctx.strokeStyle = root.fgColor
            ctx.lineWidth = root.strokeWidth
            ctx.lineCap = "round"
            ctx.beginPath()
            for (let i = 0; i <= N; i++) {
                const theta = startRad + i * dTheta
                const s = i * dTheta * radius
                const phi = root.waveFrequency * 2 * Math.PI * s / len + phase
                const rr = radius + amp * Math.sin(phi)
                const px = cx + rr * Math.cos(theta)
                const py = cy + rr * Math.sin(theta)
                if (i === 0)
                    ctx.moveTo(px, py)
                else
                    ctx.lineTo(px, py)
            }
            ctx.stroke()
        }

        onWidthChanged: requestPaint()
        Component.onCompleted: requestPaint()
    }

    Rectangle {
        x: root.size / 2 + root.arcRadius * Math.cos(root.dotAngleRad) - width / 2
        y: root.size / 2 + root.arcRadius * Math.sin(root.dotAngleRad) - height / 2
        width: Math.min(4, root.strokeWidth)
        height: width
        radius: width / 2
        color: root.fgColor
        visible: root.clampedVal > 0.01
    }

    Timer {
        running: root.waveActive
        interval: 16
        repeat: true
        onTriggered: {
            waveArc.waveProgress = (waveArc.waveProgress + 16 / root.waveDuration) % 1
            waveArc.requestPaint()
        }
    }

    function repaint() {
        waveArc.requestPaint()
    }

    onValueChanged: repaint()
    onWaveActiveChanged: repaint()
}