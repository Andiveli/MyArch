import QtQuick
import "../singletons"

Item {
    id: root

    readonly property int barCount: 24
    property int barWidth: 3
    property int barSpacing: 1
    property int barHeight: Style.barContentHeight - 4
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