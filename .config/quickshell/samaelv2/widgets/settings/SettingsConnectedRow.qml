import QtQuick
import "../../singletons"

/** Caelestia-style connected row group (shared radii). */
Rectangle {
    id: root

    property bool first: false
    property bool last: false
    property bool selected: false
    /** Keyboard focus in content panel (vim j/k). */
    property bool vimFocus: false
    property bool pressHighlight: false

    default property alias content: inner.data

    color: root.vimFocus
        ? Qt.rgba(WallustColors.accent.r, WallustColors.accent.g, WallustColors.accent.b, 0.14)
        : Qt.rgba(WallustColors.moduleBackground.r, WallustColors.moduleBackground.g, WallustColors.moduleBackground.b, 0.38)
    border.width: root.vimFocus ? 1 : 0
    border.color: root.vimFocus ? WallustColors.accent : "transparent"

    radius: ShellConfig.cornerRadius * 0.65
    topLeftRadius: first ? radius : 4
    topRightRadius: first ? radius : 4
    bottomLeftRadius: last ? radius : 4
    bottomRightRadius: last ? radius : 4

    width: parent && parent.width > 0 ? parent.width : implicitWidth
    implicitWidth: 280
    implicitHeight: Math.max(32, inner.implicitHeight + 12)

    Rectangle {
        z: 1
        width: 3
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 2
        anchors.topMargin: 4
        anchors.bottomMargin: 4
        radius: 2
        visible: root.selected || root.vimFocus
        color: WallustColors.accent
    }

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: 8
        anchors.leftMargin: 10
    }
}