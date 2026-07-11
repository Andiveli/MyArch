import QtQuick
import "../singletons"

/** Download + upload on one chart (shared scale). */
Canvas {
    id: root

    property var downSamples: []
    property var upSamples: []
    property color downColor: WallustColors.accent
    property color upColor: Qt.rgba(0.55, 0.75, 0.95, 1)

    onDownSamplesChanged: requestPaint()
    onUpSamplesChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    function drawSeries(ctx, arr, w, h, maxV, color) {
        if (!arr || arr.length < 2)
            return
        const step = w / (arr.length - 1)
        ctx.beginPath()
        for (let i = 0; i < arr.length; i++) {
            const x = i * step
            const y = h - (arr[i] / maxV) * (h - 6) - 3
            if (i === 0)
                ctx.moveTo(x, y)
            else
                ctx.lineTo(x, y)
        }
        ctx.strokeStyle = color
        ctx.lineWidth = 1.5
        ctx.stroke()
    }

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const w = width
        const h = height
        const down = downSamples || []
        const up = upSamples || []
        if (w < 4 || h < 4)
            return
        let maxV = 1024
        for (let i = 0; i < down.length; i++)
            maxV = Math.max(maxV, down[i])
        for (let i = 0; i < up.length; i++)
            maxV = Math.max(maxV, up[i])
        if (down.length < 2 && up.length < 2)
            return
        drawSeries(ctx, down, w, h, maxV, downColor)
        drawSeries(ctx, up, w, h, maxV, upColor)
    }
}