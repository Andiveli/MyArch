import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs
import qs.modules.samael

Item {
    id: root
    property int barNavIndex: 5
    property bool expanded: false

    function barContentItem() {
        let p = root.parent
        while (p) {
            if (p.barScreenName !== undefined)
                return p
            p = p.parent
        }
        return null
    }

    function schedulePublish() {
        Qt.callLater(publishClockAnchor)
    }

    function toggleExpanded() {
        const opening = !root.expanded
        root.expanded = opening
        if (opening)
            schedulePublish()
        else
            GlobalStates.samaelClockAnchorValid = false
        GlobalStates.samaelClockDropOpen = opening
    }

    function setExpanded(on: bool) {
        if (on && root.expanded && GlobalStates.samaelClockDropOpen)
            return
        root.expanded = on
        if (on) {
            publishClockAnchor()
            GlobalStates.samaelClockDropOpen = true
        } else {
            GlobalStates.samaelClockAnchorValid = false
            GlobalStates.samaelClockDropOpen = false
        }
    }

    function publishClockAnchor() {
        if (!root.expanded || root.width <= 0) {
            GlobalStates.samaelClockAnchorValid = false
            return
        }
        const bar = barContentItem()
        if (!bar || !bar.barScreenName?.length) {
            GlobalStates.samaelClockAnchorValid = false
            return
        }
        const bottom = root.mapToItem(bar, root.width / 2, root.height)
        GlobalStates.samaelClockScreenName = bar.barScreenName
        GlobalStates.samaelClockDropTop = bar.barMarginTop + bottom.y + 4
        GlobalStates.samaelClockDropLeft = bar.barMarginLeft + bottom.x - root.width / 2
        GlobalStates.samaelClockDropCenterX = bar.barMarginLeft + bottom.x
        GlobalStates.samaelClockDropWidth = root.width
        GlobalStates.samaelClockAnchorValid = true
    }

    implicitWidth: timeText.implicitWidth + 8
    implicitHeight: timeText.implicitHeight + 8

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    readonly property bool barNavFocused: GlobalStates.samaelBarNavActive
        && GlobalStates.samaelBarFocus === barNavIndex

    Rectangle {
        anchors.fill: parent
        radius: 15
        border.width: 2
        border.color: barNavFocused ? WallustColors.workspaceActive : WallustColors.borderColor
        color: "transparent"
    }

    SamaelPaddedText {
        id: timeText
        anchors.centerIn: parent
        textColor: WallustColors.clockText
        text: " " + (root.expanded
            ? Qt.formatDateTime(clock.date, "dd/MM/yy HH:mm:ss")
            : Qt.formatDateTime(clock.date, "HH:mm:ss"))
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.toggleExpanded()
    }

    onWidthChanged: if (expanded) schedulePublish()
    onXChanged: if (expanded) schedulePublish()
    onExpandedChanged: if (expanded) schedulePublish()

    Component.onCompleted: SamaelBarNavHub.clock = root
    Component.onDestruction: {
        if (SamaelBarNavHub.clock === root)
            SamaelBarNavHub.clock = null
        GlobalStates.samaelClockDropOpen = false
        GlobalStates.samaelClockAnchorValid = false
    }
}