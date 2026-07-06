import QtQuick
import qs.modules.common

/**
 * Caelestia attach motion (sidebar / dashboard / popout slide):
 * offsetScale 0 = open, 1 = closed.
 * Slide + optional fade; no scale-reveal (not SamaelPanelReveal).
 */
Item {
    id: root

    required property real offsetScale

    /** "top" | "right" */
    property string edge: "top"
    property bool fade: true

    readonly property real t: Math.min(1, Math.max(0, offsetScale))

    default property alias content: body.data

    implicitWidth: body.implicitWidth > 0 ? body.implicitWidth : body.childrenRect.width
    implicitHeight: body.implicitHeight > 0 ? body.implicitHeight : body.childrenRect.height
    width: implicitWidth
    height: implicitHeight

    opacity: fade ? (1 - t) : 1

    Item {
        id: body
        width: root.implicitWidth
        height: root.implicitHeight
        anchors.top: parent.top
        anchors.right: edge === "right" ? parent.right : undefined
        anchors.horizontalCenter: edge === "top" ? parent.horizontalCenter : undefined
        anchors.topMargin: edge === "top" ? -(root.implicitHeight + 5) * t : 0
        anchors.rightMargin: edge === "right" ? -(root.implicitWidth + 5) * t : 0
    }
}