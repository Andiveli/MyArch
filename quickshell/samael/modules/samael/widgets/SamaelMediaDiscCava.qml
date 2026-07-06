import QtQuick
import qs.modules.samael

/** Circular cava ring hugging the disc edge (CavaService, same as bar). */
Item {
    id: root

    property int discDiameter: 200
    /** Max outward extent of bars from disc edge (px). */
    property int ringExtent: 34
    property int ringGap: 1
    property int barCount: 40
    property real barThickness: 4
    property real barGain: 2.2
    property color barColor: WallustColors.sapphire
    /** When false, ring stays drawn but dimmed (no layout change). */
    property bool playing: true
    property list<double> bars: CavaService.bars

    readonly property real outerSize: discDiameter + ringExtent * 2

    implicitWidth: outerSize
    implicitHeight: outerSize

    readonly property real centerX: width / 2
    readonly property real centerY: height / 2
    readonly property real discRadius: discDiameter / 2
    readonly property real barInnerRadius: discRadius + ringGap
    readonly property real barMaxLen: ringExtent - 2

    default property alias discContent: discHost.data

    Item {
        id: discHost
        width: root.discDiameter
        height: root.discDiameter
        anchors.centerIn: parent
        clip: true
        z: 2
    }

    Canvas {
        id: ringCanvas
        anchors.fill: parent
        antialiasing: true
        z: 1

        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            const n = root.barCount
            const cx = root.centerX
            const cy = root.centerY
            const inner = root.barInnerRadius
            const maxLen = Math.max(8, root.barMaxLen)
            ctx.lineCap = "round"
            ctx.strokeStyle = root.barColor

            for (let i = 0; i < n; i++) {
                const srcIdx = root.bars.length > 0
                    ? Math.floor(i * root.bars.length / n) % root.bars.length
                    : 0
                const raw = root.bars.length > 0 ? root.bars[srcIdx] : 0
                const v = Math.min(1, raw * root.barGain + 0.06)
                const angle = (i / n) * Math.PI * 2 - Math.PI / 2
                const len = Math.max(4, v * maxLen)
                const x0 = cx + Math.cos(angle) * inner
                const y0 = cy + Math.sin(angle) * inner
                const x1 = cx + Math.cos(angle) * (inner + len)
                const y1 = cy + Math.sin(angle) * (inner + len)
                ctx.lineWidth = root.barThickness
                const playMul = root.playing ? 1 : 0.42
                ctx.globalAlpha = (0.35 + v * 0.65) * playMul
                ctx.beginPath()
                ctx.moveTo(x0, y0)
                ctx.lineTo(x1, y1)
                ctx.stroke()
            }
            ctx.globalAlpha = 1
        }
    }

    Connections {
        target: CavaService
        function onBarsChanged() {
            ringCanvas.requestPaint()
        }
    }

    onBarsChanged: ringCanvas.requestPaint()
    onBarColorChanged: ringCanvas.requestPaint()
    onBarGainChanged: ringCanvas.requestPaint()
    Component.onCompleted: ringCanvas.requestPaint()
}