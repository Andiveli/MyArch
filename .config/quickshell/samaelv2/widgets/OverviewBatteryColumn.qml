import QtQuick
import "../singletons"

/** Vertical battery — wave travels left↔right; walls lift surface only on impact. */
Item {
    id: root

    property real level: 0.72
    property bool available: true
    property bool charging: false

    implicitWidth: 44
    implicitHeight: parent ? parent.height : 160

    readonly property color stopFull: WallustColors.teal
    readonly property color stopMid: WallustColors.yellow
    readonly property color stopEmpty: WallustColors.red

    /** Inverted vs load bars: high charge = teal, low = red (same Wallust stops as OverviewTrafficBar). */
    function chargeColorAt(level01) {
        const t = Math.max(0, Math.min(1, level01))
        if (t >= 0.5) {
            const u = (t - 0.5) / 0.5
            return Qt.rgba(
                stopMid.r + (stopFull.r - stopMid.r) * u,
                stopMid.g + (stopFull.g - stopMid.g) * u,
                stopMid.b + (stopFull.b - stopMid.b) * u, 1)
        }
        const u = t / 0.5
        return Qt.rgba(
            stopEmpty.r + (stopMid.r - stopEmpty.r) * u,
            stopEmpty.g + (stopMid.g - stopEmpty.g) * u,
            stopEmpty.b + (stopMid.b - stopEmpty.b) * u, 1)
    }

    readonly property color liquid: chargeColorAt(level01)
    readonly property color liquidDim: Qt.rgba(liquid.r, liquid.g, liquid.b, 0.88)
    readonly property color liquidHighlight: Qt.rgba(
        Math.min(1, liquid.r + 0.1), Math.min(1, liquid.g + 0.1), Math.min(1, liquid.b + 0.06), 0.5)

    readonly property real level01: {
        const l = level
        if (!isFinite(l))
            return 0
        if (l > 1)
            return Math.min(1, l / 100)
        return Math.max(0, Math.min(1, l))
    }
    readonly property real fillFrac: available ? level01 : 0
    readonly property color fillColor: charging
        ? Qt.rgba(Math.min(1, liquid.r + 0.06), Math.min(1, liquid.g + 0.04), liquid.b, 1)
        : liquidDim

    /** 0 = crest at left wall, 1 = crest at right wall (ping-pong). */
    property real travel: 0

    SequentialAnimation {
        running: root.available && root.fillFrac > 0.02
        loops: Animation.Infinite
        NumberAnimation {
            target: root
            property: "travel"
            from: 0
            to: 1
            duration: root.charging ? 3000 : 4500
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "travel"
            from: 1
            to: 0
            duration: root.charging ? 3000 : 4500
            easing.type: Easing.InOutSine
        }
    }

    Item {
        anchors.fill: parent
        anchors.topMargin: 6
        anchors.bottomMargin: 4

        Rectangle {
            id: cap
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: parent.width * 0.38
            height: 5
            radius: 2
            color: Qt.rgba(WallustColors.moduleText.r, WallustColors.moduleText.g,
                WallustColors.moduleText.b, 0.35)
        }

        Rectangle {
            id: shell
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: cap.bottom
            anchors.topMargin: 2
            anchors.bottom: parent.bottom
            radius: 8
            color: Qt.rgba(WallustColors.moduleBackground.r, WallustColors.moduleBackground.g,
                WallustColors.moduleBackground.b, 0.55)
            border.width: 2
            border.color: Qt.rgba(WallustColors.moduleText.r, WallustColors.moduleText.g,
                WallustColors.moduleText.b, 0.28)
        }

        Item {
            id: inner
            anchors.fill: shell
            anchors.margins: 5
            clip: true

            Canvas {
                id: liquidCanvas
                anchors.fill: parent

                readonly property real waveAmp: {
                    const base = root.charging ? 4.5 : 3.2
                    return base * Math.min(1, 0.4 + root.fillFrac * 0.75)
                }

                function rgba(c, a) {
                    return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255)
                        + "," + Math.round(c.b * 255) + "," + a + ")"
                }

                function gauss(x, cx, sigma) {
                    const d = (x - cx) / sigma
                    return Math.exp(-0.5 * d * d)
                }

                /**
                 * Main crest moves with `travel` (L→R→L).
                 * Vertical motion at walls only when crest is near that wall (splash).
                 */
                function surfaceY(x, w, fillTop, h) {
                    const amp = waveAmp
                    const crestX = root.travel * w
                    const sigma = Math.max(6, w * 0.2)

                    const main = gauss(x, crestX, sigma)
                    const echo = gauss(x, w - crestX, sigma * 0.85) * 0.35

                    let rise = amp * (main + echo)

                    const wallW = Math.min(10, w * 0.22)
                    const hitL = Math.max(0, 1 - crestX / wallW)
                    const hitR = Math.max(0, 1 - (w - crestX) / wallW)

                    if (x < wallW)
                        rise += hitL * amp * 0.45 * (1 - x / wallW)
                    if (x > w - wallW)
                        rise += hitR * amp * 0.45 * (1 - (w - x) / wallW)

                    const y = fillTop - rise
                    return Math.max(fillTop - amp * 1.1, Math.min(h, y))
                }

                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    const w = width
                    const h = height
                    if (w < 2 || h < 4 || root.fillFrac < 0.001)
                        return

                    const col = root.fillColor
                    const fillTop = h * (1 - root.fillFrac)

                    const g = ctx.createLinearGradient(0, fillTop, 0, h)
                    g.addColorStop(0, rgba(Qt.rgba(Math.min(1, col.r + 0.12),
                        Math.min(1, col.g + 0.08), col.b, 1), 1))
                    g.addColorStop(1, rgba(col, 1))

                    ctx.beginPath()
                    ctx.moveTo(0, h)
                    ctx.lineTo(w, h)
                    ctx.lineTo(w, surfaceY(w, w, fillTop, h))
                    for (let x = w; x >= 0; x -= 1)
                        ctx.lineTo(x, surfaceY(x, w, fillTop, h))
                    ctx.closePath()
                    ctx.fillStyle = g
                    ctx.fill()

                    ctx.beginPath()
                    for (let x = 0; x <= w; x += 1)
                        ctx.lineTo(x, surfaceY(x, w, fillTop, h))
                    ctx.strokeStyle = rgba(root.liquidHighlight, 0.5)
                    ctx.lineWidth = 1
                    ctx.stroke()
                }

                Connections {
                    target: root
                    function onTravelChanged() { liquidCanvas.requestPaint() }
                    function onFillFracChanged() { liquidCanvas.requestPaint() }
                    function onFillColorChanged() { liquidCanvas.requestPaint() }
                    function onLiquidChanged() { liquidCanvas.requestPaint() }
                }
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                Component.onCompleted: requestPaint()
            }

            Column {
                anchors.centerIn: parent
                z: 2
                spacing: 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.charging && root.available
                    text: "\uf0e7"
                    font.family: Style.fontFamily
                    font.pixelSize: 12
                    color: WallustColors.yellow
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.available ? Math.round(root.level01 * 100) + "%" : "—"
                    font.family: Style.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: WallustColors.moduleText
                    style: Text.Outline
                    styleColor: Qt.rgba(0, 0, 0, 0.55)
                }
            }
        }
    }
}