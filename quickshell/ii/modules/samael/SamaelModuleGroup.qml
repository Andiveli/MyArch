import QtQuick
import QtQuick.Layouts
import qs.modules.samael

Item {
    id: root
    default property alias content: innerLayout.data
    property int spacing: SamaelStyle.moduleRowSpacing
    property int cornerRadius: 15
        property bool chromeless: false
        /** 0..1 — widens row spacing + side padding with media dock expand */
        property real layoutExpand: 0
        property bool distributeWidth: false
        property int expandedSpacingMax: 16
        property int expandedPadExtra: 20
        readonly property int hPad: SamaelStyle.moduleGroupPadH
        readonly property int effectiveSpacing: distributeWidth
            ? Math.round(spacing + expandedSpacingMax * layoutExpand)
            : spacing
        readonly property int effectiveHPad: distributeWidth
            ? hPad + Math.round(expandedPadExtra * layoutExpand)
            : hPad
    readonly property int borderW: 2

    implicitWidth: innerLayout.implicitWidth + hPad * 2
    implicitHeight: innerLayout.implicitHeight
            + SamaelStyle.modulePaddingTop
            + SamaelStyle.modulePaddingBottom

    Rectangle {
        id: borderRing
        anchors.fill: parent
        radius: root.cornerRadius
        color: "transparent"
        border.width: root.chromeless ? 0 : root.borderW
        border.color: WallustColors.borderColor
    }

    Rectangle {
        anchors {
            left: borderRing.left
            right: borderRing.right
            top: borderRing.top
            bottom: borderRing.bottom
            bottomMargin: root.chromeless ? 0 : root.borderW
        }
        radius: root.cornerRadius
        color: root.chromeless ? "transparent" : WallustColors.moduleBackground
    }

    RowLayout {
        id: innerLayout
        z: 1
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            leftMargin: effectiveHPad
            rightMargin: effectiveHPad
            topMargin: SamaelStyle.modulePaddingTop
            bottomMargin: SamaelStyle.modulePaddingBottom
        }
        spacing: root.effectiveSpacing

        onChildrenChanged: root._syncChildAlignment()
    }

    function _syncChildAlignment() {
        for (let i = 0; i < innerLayout.children.length; i++) {
            const c = innerLayout.children[i]
            if (c && c.Layout)
                c.Layout.alignment = Qt.AlignVCenter
        }
    }

    Component.onCompleted: _syncChildAlignment()
}