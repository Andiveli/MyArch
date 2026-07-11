import QtQuick
import "../singletons"

Canvas {
    id: root

    property var samples: []
    property color strokeColor: WallustColors.accent
    property color fillColor: Qt.rgba(strokeColor.r, strokeColor.g, strokeColor.b, 0.18)

    onSamplesChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const w = width
        const h = height
        const arr = samples || []
        if (arr.length < 2 || w < 4 || h < 4)
            return
        let maxV = 1
        for (let i = 0; i < arr.length; i++)
            maxV = Math.max(maxV, arr[i])
        const step = w / (arr.length - 1)
        ctx.beginPath()
        for (let i = 0; i < arr.length; i++) {
            const x = i * step
            const y = h - (arr[i] / maxV) * (h - 4) - 2
            if (i === 0)
                ctx.moveTo(x, y)
            else
                ctx.lineTo(x, y)
        }
        ctx.lineTo(w, h)
        ctx.lineTo(0, h)
        ctx.closePath()
        ctx.fillStyle = fillColor
        ctx.fill()
        ctx.beginPath()
        for (let i = 0; i < arr.length; i++) {
            const x = i * step
            const y = h - (arr[i] / maxV) * (h - 4) - 2
            if (i === 0)
                ctx.moveTo(x, y)
            else
                ctx.lineTo(x, y)
        }
        ctx.strokeStyle = strokeColor
        ctx.lineWidth = 1.5
        ctx.stroke()
    }
}