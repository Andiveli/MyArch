import QtQuick
import Caelestia.Services
import "../singletons"

/**
 * Current line: words highlight over the line duration (even split).
 * Not Apple syllable-level — Caelestia only exposes line LRC timestamps.
 */
Item {
    id: root

    property string lineText: ""
    property int lineIndex: -1
    property bool isCurrent: false
    property real playbackSec: 0
    property int lineCount: 0
    property var playerRef: null

    readonly property real lineStart: lineIndex >= 0 ? Lyrics.timeForIndex(lineIndex) : -1
    readonly property real lineEnd: {
        if (lineIndex < 0)
            return -1
        if (lineIndex + 1 < lineCount)
            return Lyrics.timeForIndex(lineIndex + 1)
        const p = playerRef
        return p && p.length > 0 ? p.length : lineStart + 4
    }

    readonly property real lineProgress: {
        if (!isCurrent || lineStart < 0 || lineEnd <= lineStart)
            return isCurrent ? 1 : 0
        const t = playbackSec - lineStart
        const d = lineEnd - lineStart
        return Math.max(0, Math.min(1, t / d))
    }

    readonly property var words: {
        const s = (lineText || "").trim()
        if (!s.length)
            return [""]
        return s.split(/\s+/).filter(w => w.length > 0)
    }

    readonly property int activeWordCount: {
        const n = words.length
        if (!isCurrent || n === 0)
            return 0
        const p = lineProgress * n
        return Math.max(0, Math.min(n, Math.ceil(p - 0.05)))
    }

    width: parent ? parent.width : implicitWidth
    implicitHeight: flow.implicitHeight + 8
    height: implicitHeight

    Flow {
        id: flow
        width: parent.width
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        Repeater {
            model: root.words

            Text {
                required property int index
                required property string modelData

                text: modelData
                font.family: Style.fontFamily
                font.pixelSize: root.isCurrent ? Style.fontPixelSize + 2 : Style.fontPixelSize - 1
                font.bold: root.isCurrent && index < root.activeWordCount
                color: {
                    if (!root.isCurrent)
                        return WallustColors.buttonHover
                    if (index < root.activeWordCount)
                        return WallustColors.sky
                    if (index === root.activeWordCount)
                        return Qt.rgba(WallustColors.sky.r, WallustColors.sky.g, WallustColors.sky.b, 0.55)
                    return WallustColors.buttonHover
                }
                opacity: root.isCurrent ? (index <= root.activeWordCount ? 1 : 0.45) : 0.72

                Behavior on color {
                    ColorAnimation { duration: 120; easing.type: Easing.OutCubic }
                }
                Behavior on opacity {
                    NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                }

                scale: root.isCurrent && index === root.activeWordCount ? 1.06 : 1
                Behavior on scale {
                    NumberAnimation { duration: 160; easing.type: Easing.OutBack }
                }
            }
        }
    }
}