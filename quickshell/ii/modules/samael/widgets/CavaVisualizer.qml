import QtQuick
import qs.modules.samael
import qs.modules.samael.widgets

Item {
    id: root
    readonly property int barCount: 24
    property int barWidth: 3
    property int barSpacing: 1
    property int barHeight: SamaelStyle.barContentHeight - 4
    property color barColor: WallustColors.buttonColor
    property list<double> bars: CavaService.bars

    implicitWidth: barCount * (barWidth + barSpacing) - barSpacing
    implicitHeight: barHeight

    Canvas {
        id: canvas
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.fillStyle = root.barColor
            const n = Math.max(root.bars.length, root.barCount)
            for (let i = 0; i < root.barCount; i++) {
                const v = i < root.bars.length ? root.bars[i] : 0
                const h = Math.max(1, v * root.barHeight)
                ctx.fillRect(
                    i * (root.barWidth + root.barSpacing),
                    root.barHeight - h,
                    root.barWidth,
                    h
                )
            }
        }
    }

    Connections {
        target: CavaService
        function onBarsChanged() {
            canvas.requestPaint()
        }
    }

    Component.onCompleted: canvas.requestPaint()
}