import QtQuick
import "../singletons"

/**
 * Speedometer: 270° track, tick marks, needle; Wallust traffic gradient (same as OverviewTrafficBar).
 */
Item {
    id: root

    property real value: 0
    property string centerGlyph: "\uf2db"
    property int centerGlyphSize: 13
    property color trackColor: Qt.rgba(WallustColors.moduleText.r, WallustColors.moduleText.g,
        WallustColors.moduleText.b, 0.12)
    property real lineWidth: 5
    property real startAngle: 135
    property real spanAngle: 270

    implicitWidth: 80
    implicitHeight: 70

    readonly property real value01: Math.max(0, Math.min(1, isNaN(value) ? 0 : value))

    property real displayValue: value01

    readonly property color stopGreen: WallustColors.teal
    readonly property color stopYellow: WallustColors.yellow
    readonly property color stopRed: WallustColors.red

    /** Color at load fraction 0…1 (matches OverviewTrafficBar). */
    function trafficAt(f) {
        const t = Math.max(0, Math.min(1, f))
        if (t <= 0.5) {
            const u = t / 0.5
            return Qt.rgba(
                stopGreen.r + (stopYellow.r - stopGreen.r) * u,
                stopGreen.g + (stopYellow.g - stopGreen.g) * u,
                stopGreen.b + (stopYellow.b - stopGreen.b) * u, 1)
        }
        const u = (t - 0.5) / 0.5
        return Qt.rgba(
            stopYellow.r + (stopRed.r - stopYellow.r) * u,
            stopYellow.g + (stopRed.g - stopYellow.g) * u,
            stopYellow.b + (stopRed.b - stopYellow.b) * u, 1)
    }

    readonly property color trafficColor: trafficAt(displayValue)

    Behavior on displayValue {
        NumberAnimation {
            duration: 520
            easing.type: Easing.OutCubic
        }
    }

    onValue01Changed: displayValue = value01

    readonly property real _cx: width / 2
    readonly property real _cy: height * 0.62
    readonly property real _r: Math.min(width * 0.42, height * 0.5)

    Canvas {
        id: canvas
        anchors.fill: parent
        z: 1

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const w = width
            const h = height
            if (w < 4 || h < 4)
                return

            const cx = root._cx
            const cy = root._cy
            const r = root._r
            const v = Math.max(0, Math.min(1, root.displayValue))
            const tickColor = Qt.rgba(WallustColors.moduleText.r, WallustColors.moduleText.g,
                WallustColors.moduleText.b, 0.42)

            drawTicks(ctx, cx, cy, r, tickColor)
            drawArc(ctx, cx, cy, r, root.startAngle, root.spanAngle, root.trackColor, root.lineWidth)

            if (v > 0.002)
                drawGradientArc(ctx, cx, cy, r, root.startAngle, root.spanAngle * v, root.lineWidth)

            const angleDeg = root.startAngle + root.spanAngle * v
            const rad = angleDeg * Math.PI / 180
            const tipR = r * 0.88
            const tipX = cx + tipR * Math.cos(rad)
            const tipY = cy + tipR * Math.sin(rad)
            const needleCol = root.trafficAt(v)

            ctx.beginPath()
            ctx.moveTo(cx, cy)
            ctx.lineTo(tipX, tipY)
            ctx.strokeStyle = needleCol
            ctx.lineWidth = 2.2
            ctx.lineCap = "round"
            ctx.stroke()

            ctx.beginPath()
            ctx.arc(cx, cy, 3.5, 0, Math.PI * 2)
            ctx.fillStyle = Qt.rgba(WallustColors.moduleText.r, WallustColors.moduleText.g,
                WallustColors.moduleText.b, 0.35)
            ctx.fill()
            ctx.strokeStyle = needleCol
            ctx.lineWidth = 1.2
            ctx.stroke()
        }

        function degToRad(d) { return d * Math.PI / 180 }

        function drawTicks(ctx, cx, cy, r, color) {
            const start = root.startAngle
            const span = root.spanAngle
            const minorStep = 0.05
            const majorEvery = 0.1
            ctx.strokeStyle = color
            ctx.lineCap = "butt"

            for (let f = 0; f <= 1.001; f += minorStep) {
                const isMajor = Math.abs(f / majorEvery - Math.round(f / majorEvery)) < 0.001
                    || f < 0.001 || f > 0.999
                const ang = start + span * f
                const rad = degToRad(ang)
                const inner = r - (isMajor ? 7 : 4)
                const outer = r + 2
                ctx.beginPath()
                ctx.lineWidth = isMajor ? 1.4 : 0.8
                ctx.moveTo(cx + inner * Math.cos(rad), cy + inner * Math.sin(rad))
                ctx.lineTo(cx + outer * Math.cos(rad), cy + outer * Math.sin(rad))
                ctx.stroke()
            }
        }

        function drawArc(ctx, cx, cy, r, startDeg, sweepDeg, color, lw) {
            ctx.beginPath()
            ctx.lineWidth = lw
            ctx.lineCap = "round"
            ctx.strokeStyle = color
            const start = startDeg * Math.PI / 180
            const end = (startDeg + sweepDeg) * Math.PI / 180
            ctx.arc(cx, cy, r, start, end, false)
            ctx.stroke()
        }

        /** Filled sweep colored by load fraction along full gauge range (0…1). */
        function drawGradientArc(ctx, cx, cy, r, startDeg, sweepDeg, lw) {
            const steps = Math.max(8, Math.ceil(Math.abs(sweepDeg) / 6))
            const stepSweep = sweepDeg / steps
            const fullSpan = root.spanAngle
            for (let i = 0; i < steps; i++) {
                const segStart = startDeg + stepSweep * i
                const loadFrac = (segStart + stepSweep * 0.5 - root.startAngle) / fullSpan
                const col = root.trafficAt(Math.max(0, Math.min(1, loadFrac)))
                drawArc(ctx, cx, cy, r, segStart, stepSweep, col, lw)
            }
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Connections {
            target: root
            function onDisplayValueChanged() { canvas.requestPaint() }
            function onTrafficColorChanged() { canvas.requestPaint() }
        }
    }

    Text {
        z: 2
        anchors.horizontalCenter: parent.horizontalCenter
        y: root._cy + 10
        text: root.centerGlyph
        font.family: Style.fontFamily
        font.pixelSize: root.centerGlyphSize
        color: WallustColors.moduleText
        opacity: 0.9
    }
}