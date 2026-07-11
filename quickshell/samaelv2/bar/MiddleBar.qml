import QtQuick
import "../singletons"
import "./WidgetHost.qml"

/**
 * Middle pill on overlay only (pill pattern). Root is Item — not inside BarSection RowLayout.
 */
Item {
    id: root

    property string surface: ""
    property bool morphFromRest: true
    /** Outer chrome size from reserve MiddleIdle (set before morph). */
    property real restOuterW: 0
    property real restOuterH: 0

    readonly property int padH: ShellConfig.innerMarginMiddleSides
    readonly property int padTop: ShellConfig.sectionPadTopCompact
    readonly property int padBottom: ShellConfig.sectionPadBottomCompact + ShellConfig.sectionBottomMargin
    readonly property int chromeRadius: ShellConfig.cornerRadius

    readonly property bool surfaceOpen: surface.length > 0
    /** True from close until dismiss — media stays clipped inside shrinking chrome (no early Loader unload). */
    property bool closeMorphActive: false
    readonly property bool showMediaDuringMorph: (surfaceOpen && surface === "media") || closeMorphActive
    readonly property bool atMiddleShape: closeMorphActive
        && morphRoot.height <= restH + 1.5
        && morphRoot.width <= restW + 1.5
    /** Text until chrome matches middle; handoff same frame as hide. */
    readonly property bool showMediaContent: showMediaDuringMorph
        && (!closeMorphActive || !atMiddleShape)
    property bool handoffDone: false
    readonly property string mode: surfaceOpen ? surface : "rest"
    readonly property real restW: {
        if (restOuterW > 0)
            return Math.max(restOuterW - padH * 2, 48)
        const inner = restMeasure.implicitWidth
        if (inner > 0)
            return inner
        return Math.max(ShellActions.middleRestWidth - padH * 2, 120)
    }
    readonly property real restH: {
        if (restOuterH > 0)
            return Math.max(restOuterH - padTop - padBottom, Style.chromeBandHeight)
        const inner = restMeasure.implicitHeight
        if (inner > 0)
            return inner
        const outer = ShellActions.middleRestHeight
        if (outer > 0)
            return Math.max(outer - padTop - padBottom, Style.chromeBandHeight)
        return Style.chromeBandHeight + ShellConfig.sectionBottomMargin
    }

    readonly property size targetSize: {
        if (mode === "rest")
            return Qt.size(restW, restH)
        const sz = ShellConfig.surfaceSize(mode)
        return Qt.size(sz.width, sz.height)
    }

    readonly property real morphCloseness: {
        const tw = targetSize.width
        const th = targetSize.height
        if (tw <= 0 || th <= 0)
            return 1
        const cw = Math.max(1, morphRoot.width)
        const ch = Math.max(1, morphRoot.height)
        return Math.min(1, Math.min(cw / tw, ch / th))
    }

    implicitWidth: morphRoot.width + padH * 2
    implicitHeight: morphRoot.height + padTop + padBottom

    width: implicitWidth
    height: implicitHeight
    clip: true

    signal dismissRequested()

    function finishCloseHandoff() {
        if (handoffDone || !closeMorphActive)
            return
        handoffDone = true
        closeMorphActive = false
        closeMorphGuard.stop()
        dismissRequested()
    }

    WidgetHost {
        id: restMeasure
        visible: false
        zone: "middle"
        widgetIds: ShellConfig.barMiddle
        spacing: 6
    }

    Rectangle {
        anchors.fill: parent
        radius: chromeRadius
        color: Qt.rgba(WallustColors.moduleBackground.r, WallustColors.moduleBackground.g,
                        WallustColors.moduleBackground.b, 0.92)
        border.width: 2
        border.color: WallustColors.borderColor
    }

    Item {
        id: morphRoot
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: padTop
        width: morphFromRest ? restW : targetSize.width
        height: morphFromRest ? restH : targetSize.height
        clip: true

        Behavior on width {
            NumberAnimation {
                duration: Motion.morph
                easing.type: Motion.easeMorph
                easing.bezierCurve: Motion.morphCurve
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: Motion.morph
                easing.type: Motion.easeMorph
                easing.bezierCurve: Motion.morphCurve
            }
        }

        onWidthChanged: if (root.atMiddleShape) root.finishCloseHandoff()
        onHeightChanged: if (root.atMiddleShape) root.finishCloseHandoff()

        Loader {
            active: root.showMediaDuringMorph
            anchors.fill: parent
            source: "../surfaces/MediaSurface.qml"
            onLoaded: bindMediaItem(item)
            onActiveChanged: {
                if (active && item)
                    bindMediaItem(item)
            }

            function bindMediaItem(mediaItem) {
                if (!mediaItem)
                    return
                mediaItem.open = Qt.binding(() => root.showMediaDuringMorph)
                mediaItem.contentShown = Qt.binding(() => root.showMediaContent)
                mediaItem.fadeWithMorph = Qt.binding(() => root.surfaceOpen)
                mediaItem.morphCloseness = Qt.binding(() => root.morphCloseness)
            }
        }
    }

    onAtMiddleShapeChanged: {
        if (atMiddleShape)
            finishCloseHandoff()
    }

    Timer {
        id: closeMorphGuard
        interval: Motion.morph + 80
        repeat: false
        onTriggered: {
            if (!root.surfaceOpen && root.closeMorphActive)
                root.finishCloseHandoff()
        }
    }

    onSurfaceOpenChanged: {
        if (!surfaceOpen) {
            handoffDone = false
            closeMorphActive = true
            closeMorphGuard.restart()
        } else {
            handoffDone = false
            closeMorphActive = false
            closeMorphGuard.stop()
        }
    }
}