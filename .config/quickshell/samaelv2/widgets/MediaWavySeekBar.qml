import QtQuick
import "../singletons"

/**
 * Port of Caelestia StyledSlider (wavy mode) — no external QML deps.
 * Reference: vendor caelestia-shell/components/controls/StyledSlider.qml
 */
Item {
    id: root

    property real value: 0
    property bool enabled: true
    property bool animateWave: false
    property int waveFrequency: 5
    property int waveDuration: 2000
    property int barHeight: 12
    property color fgColor: WallustColors.sky
    property color bgColor: Qt.rgba(WallustColors.buttonColor.r, WallustColors.buttonColor.g,
                                    WallustColors.buttonColor.b, 0.55)

    signal seeked(real fraction)

    implicitWidth: 200
    implicitHeight: barHeight + 6

    property bool dragging: false
    readonly property bool draggingProp: dragging
    readonly property real pos: Math.max(0, Math.min(1, dragging ? dragFraction : value))
    property real dragFraction: 0

    readonly property int handleW: 4
    readonly property int handleMargin: 4
    readonly property real travelW: Math.max(1, width - handleW - handleMargin)
    readonly property real filledWidth: travelW * pos

    readonly property real remainingOpacity: Math.min(1, (width - filledWidth - handleW) / 12)

    Rectangle {
        id: remaining
        anchors.left: handle.right
        anchors.leftMargin: handleMargin
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: barHeight * (barHeight <= 12 ? remainingOpacity : Math.min(remainingOpacity * 2, 1))
        opacity: remainingOpacity
        radius: 6
        topLeftRadius: 2
        bottomLeftRadius: 2
        color: root.bgColor
    }

    Rectangle {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 4 * remainingOpacity
        width: height
        height: 4 * remainingOpacity
        opacity: remainingOpacity
        radius: width / 2
        color: root.fgColor
        visible: root.enabled
    }

    Rectangle {
        id: handle
        anchors.left: filledClip.right
        anchors.leftMargin: handleMargin
        anchors.verticalCenter: parent.verticalCenter
        width: handleW
        height: barHeight * (dragging ? 1.15 : 1)
        radius: width / 2
        color: root.fgColor
        opacity: root.enabled ? 1 : 0.38
        Behavior on height { NumberAnimation { duration: Motion.fast; easing.type: Easing.OutCubic } }
    }

    Item {
        id: filledClip
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, root.filledWidth)
        height: root.implicitHeight
        clip: true

        Canvas {
            id: waveFill
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(handleW, root.filledWidth)
            height: barHeight * 2.2
            property real waveProgress: 0
            property real lineW: barHeight * 0.7
            property real ampMul: 0.5

            onWidthChanged: requestPaint()
            onWaveProgressChanged: requestPaint()
            Component.onCompleted: requestPaint()

            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                if (width < 1)
                    return
                const lw = lineW
                const amp = lw * ampMul
                const cy = height / 2
                const len = root.travelW
                const phase = waveProgress * 2 * Math.PI
                const freq = root.waveFrequency
                const end = width - lw / 2
                ctx.lineWidth = lw
                ctx.lineCap = "round"
                ctx.strokeStyle = root.fgColor
                ctx.beginPath()
                let first = true
                for (let x = lw / 2; x <= end; x++) {
                    const theta = freq * 2 * Math.PI * x / len + phase
                    const y = cy + amp * Math.sin(theta)
                    if (first) {
                        ctx.moveTo(x, y)
                        first = false
                    } else
                        ctx.lineTo(x, y)
                }
                ctx.stroke()
            }

            Timer {
                running: root.animateWave && root.enabled
                interval: 16
                repeat: true
                onTriggered: {
                    const step = 16 / root.waveDuration
                    waveFill.waveProgress = (waveFill.waveProgress + step) % 1
                }
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: Math.max(barHeight * 2.5, 22)
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        preventStealing: true

        property real pressStartX: 0
        property real pressStartPos: 0

        onPressed: e => {
            pressStartX = e.x
            pressStartPos = root.pos
            root.dragging = true
            root.dragFraction = clamp01(e.x / root.width)
        }
        onPositionChanged: e => {
            if (!pressed)
                return
            const drag = (e.x - pressStartX) / root.width
            root.dragFraction = clamp01(pressStartPos + drag)
        }
        onReleased: e => {
            const click = clamp01(e.x / root.width)
            const finalPos = (e.x - pressStartX) !== 0 ? root.dragFraction : click
            root.dragging = false
            root.seeked(finalPos)
        }

        function clamp01(v) { return Math.max(0, Math.min(1, v)) }
    }

    onValueChanged: if (!dragging) waveFill.requestPaint()
    onPosChanged: waveFill.requestPaint()
}