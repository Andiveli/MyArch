import QtQuick
import "../singletons"

/**
 * Speedometer: 270° track, tick marks, needle; traffic color (33% / 66%).
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

    readonly property color trafficColor: {
        const p = displayValue
        if (p < 0.33)
            return Qt.rgba(0.42, 0.82, 0.52, 1)
        if (p < 0.66)
            return Qt.rgba(0.95, 0.78, 0.22, 1)
        return Qt.rgba(0.92, 0.32, 0.28, 1)
    }

    Behavior on displayValue {
        NumberAnimation {
            duration: 520
            easing.type: Easing.OutCubic
        }
    }

    onValue01Changed: displayValue = value01

    /** Pivot lifted so the full arc fits above the icon. */
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
            const col = root.trafficColor
            const tickColor = Qt.rgba(WallustColors.moduleText.r, WallustColors.moduleText.g,
                WallustColors.moduleText.b, 0.42)

            drawTicks(ctx, cx, cy, r, tickColor)

            drawArc(ctx, cx, cy, r, root.startAngle, root.spanAngle, root.trackColor, root.lineWidth)
            if (v > 0.002)
                drawArc(ctx, cx, cy, r, root.startAngle, root.spanAngle * v, col, root.lineWidth)

            const angleDeg = root.startAngle + root.spanAngle * v
            const rad = angleDeg * Math.PI / 180
            const tipR = r * 0.88
            const tipX = cx + tipR * Math.cos(rad)
            const tipY = cy + tipR * Math.sin(rad)

            ctx.beginPath()
            ctx.moveTo(cx, cy)
            ctx.lineTo(tipX, tipY)
            ctx.strokeStyle = col
            ctx.lineWidth = 2.2
            ctx.lineCap = "round"
            ctx.stroke()

            ctx.beginPath()
            ctx.arc(cx, cy, 3.5, 0, Math.PI * 2)
            ctx.fillStyle = Qt.rgba(WallustColors.moduleText.r, WallustColors.moduleText.g,
                WallustColors.moduleText.b, 0.35)
            ctx.fill()
            ctx.strokeStyle = col
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