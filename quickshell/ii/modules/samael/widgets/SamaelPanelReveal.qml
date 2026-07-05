import QtQuick
import qs.modules.common

/**
 * Caelestia-style panel reveal: fade + vertical scale from the attach edge.
 */
Item {
    id: root

    property real openProgress: 0
    property real scaleOriginY: 0
    property real scaleOriginX: 0.5

    readonly property real panelOpacity: openProgress
    readonly property real panelScale: 0.88 + 0.12 * openProgress

    default property alias content: contentHost.data

    implicitWidth: contentHost.implicitWidth > 0 ? contentHost.implicitWidth : contentHost.childrenRect.width
    implicitHeight: contentHost.implicitHeight > 0 ? contentHost.implicitHeight : contentHost.childrenRect.height
    width: implicitWidth
    height: implicitHeight

    opacity: panelOpacity
    transform: Scale {
        origin.x: root.width * root.scaleOriginX
        origin.y: root.height * root.scaleOriginY
        xScale: root.panelScale
        yScale: root.panelScale
    }

    Item {
        id: contentHost
    }

    function playOpen() {
        openProgress = 0
        openAnim.restart()
    }

    function playClose(onFinished) {
        closeFinishedHandler = onFinished || null
        closeAnim.restart()
    }

    property var closeFinishedHandler: null

    NumberAnimation {
        id: openAnim
        target: root
        property: "openProgress"
        from: 0
        to: 1
        duration: Appearance.animation.elementMoveEnter.duration
        easing.type: Appearance.animation.elementMoveEnter.type
        easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
    }

    NumberAnimation {
        id: closeAnim
        target: root
        property: "openProgress"
        to: 0
        duration: Appearance.animation.elementMoveExit.duration
        easing.type: Appearance.animation.elementMoveExit.type
        easing.bezierCurve: Appearance.animation.elementMoveExit.bezierCurve
        onFinished: {
            if (root.closeFinishedHandler)
                root.closeFinishedHandler()
            root.closeFinishedHandler = null
        }
    }
}