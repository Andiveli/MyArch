import QtQuick
import QtQuick.Layouts
import M3Shapes
import "../singletons"
import "./LockPasswordChar.qml"

/**
 * Caelestia PasswordInput + InputField — qs -c samael lock center.
 */
Item {
    id: fieldRoot

    required property var pamHost
    required property real contentScale
    required property real maxWidth

    readonly property real s: Math.max(0.85, Style.fontPixelSize / 11)
    readonly property real centerW: maxWidth * 0.8
    /** Caelestia: Tokens.font.body.medium.pointSize — compact dots in pill */
    readonly property int glyphRowH: Math.max(12, Math.round(Style.fontPixelSize * 0.88))
    readonly property int charGap: Math.round(4 * s)
    readonly property real sidePad: 8 * s
    readonly property real iconSlot: 28 * s
    readonly property real enterSlot: 36 * s

    property string buffer: ""

    readonly property list<int> shapeQueue: {
        const shapes = [
            MaterialShape.Slanted, MaterialShape.Arch, MaterialShape.Fan, MaterialShape.Arrow,
            MaterialShape.SemiCircle, MaterialShape.Triangle, MaterialShape.Diamond,
            MaterialShape.ClamShell, MaterialShape.Pentagon, MaterialShape.Gem,
            MaterialShape.Sunny, MaterialShape.VerySunny, MaterialShape.Cookie4Sided,
            MaterialShape.Ghostish, MaterialShape.SoftBurst
        ]
        for (let i = shapes.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1))
            const t = shapes[i]
            shapes[i] = shapes[j]
            shapes[j] = t
        }
        return shapes
    }

    readonly property string placeholderText: {
        if (pamHost.passwdActive)
            return "Loading…"
        if (pamHost.statusText.length && buffer.length === 0)
            return pamHost.statusText
        return "Enter your password"
    }

    readonly property int charRowFullWidth: {
        const n = buffer.length
        if (n === 0)
            return 0
        let w = (n - 1) * charGap
        for (let i = 0; i < charRow.children.length; i++) {
            const it = charRow.children[i]
            if (it && it.nonAnimWidthScale !== undefined)
                w += it.nonAnimWidthScale * glyphRowH
        }
        if (w < n * glyphRowH)
            w = n * glyphRowH + (n - 1) * charGap
        return w + glyphRowH
    }

    function bindCharRowWidth() {
        rowWidthBehavior.enabled = false
        charRow.width = Qt.binding(() => charRowFullWidth)
        rowWidthBehavior.enabled = true
    }

    Connections {
        target: pamHost
        function onBufferChanged() {
            const prev = fieldRoot.buffer.length
            const next = pamHost.buffer.length
            fieldRoot.buffer = pamHost.buffer
            if (next > prev)
                Qt.callLater(fieldRoot.bindCharRowWidth)
            else if (next === 0)
                charRow.width = charRowFullWidth
        }
    }

    TextMetrics {
        id: placeholderMetrics
        font.family: Style.fontFamily
        font.pixelSize: Math.round((Style.fontPixelSize + 1) * Math.max(0.95, contentScale))
        text: placeholderText
    }

    readonly property real compactInnerW: placeholderMetrics.width + iconSlot + enterSlot
        + inputRow.spacing * 2 + sidePad * 2

    implicitWidth: buffer.length > 0 ? centerW : Math.min(centerW, compactInnerW)
    implicitHeight: Math.max(glyphRowH, 40 * s) + sidePad * 2
    width: implicitWidth
    height: implicitHeight

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Motion.morph
            easing.type: Motion.easeMorph
            easing.bezierCurve: Motion.morphCurve
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Qt.rgba(WallustColors.buttonHover.r, WallustColors.buttonHover.g,
            WallustColors.buttonHover.b, 0.22)
        border.width: 0

        RowLayout {
            id: inputRow
            anchors.fill: parent
            anchors.margins: sidePad
            spacing: 10 * s

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: "\uf023"
                color: WallustColors.foreground
                font.family: Style.fontFamily
                font.pixelSize: Math.round(15 * s)
            }

            Item {
                id: fieldClip
                Layout.fillWidth: true
                Layout.preferredHeight: glyphRowH
                Layout.minimumHeight: glyphRowH
                clip: true

                Text {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 1
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: fieldRoot.placeholderText
                    color: WallustColors.foreground
                    font.family: Style.fontFamily
                    font.pixelSize: Math.round((Style.fontPixelSize + 1) * Math.max(0.95, contentScale))
                    opacity: buffer.length > 0 ? 0 : 1

                    Behavior on opacity {
                        NumberAnimation { duration: Motion.standard }
                    }
                }

                Row {
                    id: charRow
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: width > fieldClip.width
                        ? -(width - fieldClip.width) / 2 : 0
                    spacing: charGap
                    height: glyphRowH
                    width: charRowFullWidth
                    visible: buffer.length > 0

                    Behavior on width {
                        id: rowWidthBehavior
                        NumberAnimation {
                            duration: Motion.morph
                            easing.type: Motion.easeMorph
                            easing.bezierCurve: Motion.morphCurve
                        }
                    }

                    Repeater {
                        model: buffer.length
                        delegate: LockPasswordChar {
                            charIndex: index
                            rowHeight: fieldRoot.glyphRowH
                            shapeKind: fieldRoot.shapeQueue[index % fieldRoot.shapeQueue.length]
                        }
                    }
                }
            }

            Item {
                Layout.preferredWidth: enterSlot
                Layout.preferredHeight: enterSlot
                Layout.alignment: Qt.AlignVCenter

                property bool hasText: buffer.length > 0

                MaterialShape {
                    anchors.fill: parent
                    shape: parent.hasText ? MaterialShape.Arrow : MaterialShape.Circle
                    rotation: 90
                    color: parent.hasText
                        ? Qt.rgba(WallustColors.sky.r, WallustColors.sky.g, WallustColors.sky.b, 0.85)
                        : Qt.rgba(WallustColors.moduleBackground.r, WallustColors.moduleBackground.g,
                            WallustColors.moduleBackground.b, 0.55)
                    scale: parent.hasText
                        ? (enterMouse.pressed ? 0.6 : enterMouse.containsMouse ? 0.8 : 0.7)
                        : 1

                    Behavior on scale {
                        NumberAnimation { duration: Motion.fast }
                    }
                    Behavior on color {
                        ColorAnimation { duration: Motion.standard }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "\uf061"
                    color: WallustColors.foreground
                    font.family: Style.fontFamily
                    font.pixelSize: 13 * s
                    opacity: parent.hasText ? 0 : 1

                    Behavior on opacity {
                        NumberAnimation { duration: Motion.standard }
                    }
                }

                MouseArea {
                    id: enterMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: parent.hasText ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (parent.hasText)
                            pamHost.submitPassword()
                    }
                }
            }
        }
    }

    Component.onCompleted: buffer = pamHost.buffer
}