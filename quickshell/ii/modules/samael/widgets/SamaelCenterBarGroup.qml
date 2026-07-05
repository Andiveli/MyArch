import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.samael
import qs.modules.samael.widgets

// Center bar capsule + island body below the module row (same sizing model as SamaelModuleGroup).
Item {
    id: root
    default property alias content: modulesRow.data

    readonly property int hPad: SamaelStyle.moduleGroupPadH
    readonly property int borderW: 2
    readonly property int cornerRadius: 15

    property int islandPulse: 0

    readonly property int rowW: modulesRow.implicitWidth
    readonly property int stackH: modulesRow.implicitHeight + islandBody.implicitHeight

    implicitWidth: Math.max(rowW, 1) + hPad * 2
    implicitHeight: stackH
        + SamaelStyle.modulePaddingTop
        + SamaelStyle.modulePaddingBottom

    Rectangle {
        id: borderRing
        anchors.fill: parent
        radius: root.cornerRadius
        color: "transparent"
        border.width: borderW
        border.color: islandBody.active ? WallustColors.workspaceActive : WallustColors.borderColor
        opacity: islandBody.active ? 0.55 + islandPulse * 0.45 : 1

        Behavior on opacity {
            NumberAnimation { duration: 220 }
        }
        Behavior on border.color {
            ColorAnimation { duration: 220 }
        }
    }

    Rectangle {
        anchors {
            left: borderRing.left
            right: borderRing.right
            top: borderRing.top
            bottom: borderRing.bottom
            bottomMargin: borderW
        }
        radius: cornerRadius
        color: WallustColors.moduleBackground
    }

    Column {
        id: stack
        z: 1
        spacing: 0
        width: root.rowW
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: SamaelStyle.modulePaddingTop
            bottomMargin: SamaelStyle.modulePaddingBottom
        }

        RowLayout {
            id: modulesRow
            width: implicitWidth
            spacing: SamaelStyle.moduleRowSpacing

            Component.onCompleted: root._syncChildAlignment()
            onChildrenChanged: root._syncChildAlignment()
            onImplicitWidthChanged: stack.width = Math.max(implicitWidth, 1)
        }

        SamaelIslandBody {
            id: islandBody
            width: stack.width
            lineWidth: stack.width
        }
    }

    function _syncChildAlignment() {
        for (let i = 0; i < modulesRow.children.length; i++) {
            const c = modulesRow.children[i]
            if (c && c.Layout)
                c.Layout.alignment = Qt.AlignVCenter
        }
    }

    Connections {
        target: Notifications
        function onNotify() {
            root.islandPulse = 1
            pulseDecay.restart()
        }
    }

    Timer {
        id: pulseDecay
        interval: 420
        onTriggered: root.islandPulse = 0
    }
}