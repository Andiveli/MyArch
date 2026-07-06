import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs
import qs.modules.common
import qs.services
import qs.modules.samael
import qs.modules.samael.widgets

Item {
    id: root
    property string barScreenName: ""

    readonly property int barMarginTop: 3
    readonly property int barMarginLeft: 8
    /** Match SamaelMediaManagerDrop / compact media row */
    readonly property int mediaPanelWidth: 728
    readonly property int performancePanelWidth: 840

    property real cachedCenterBarW: 0

    readonly property real barRowH: Math.max(
        leftGroup.implicitHeight,
        centerModules.implicitHeight,
        rightGroup.implicitHeight)

    readonly property real paintHeight: barRowH
    implicitHeight: paintHeight

    readonly property var centerDockRef: centerDock

        function publishPerformanceDockAnchor() {
            if (GlobalStates.samaelPerformanceDropOpen || GlobalStates.samaelPerformanceClosing)
                return
            if (!barScreenName.length || centerDock.width <= 0)
                return
            const focused = Hyprland.focusedMonitor?.name ?? ""
            if (focused.length && focused !== barScreenName)
                return
            const seam = centerDock.mapToItem(root, centerDock.width / 2, centerDock.modulesH)
            GlobalStates.samaelPerformanceScreenName = barScreenName
            GlobalStates.samaelPerformanceCenterX = barMarginLeft + seam.x
            GlobalStates.samaelPerformanceDockTop = barMarginTop + seam.y
            GlobalStates.samaelPerformanceDockLeft = barMarginLeft + seam.x - centerDock.width / 2
            GlobalStates.samaelPerformanceDockWidth = centerDock.width
        }

        function publishMediaDockAnchor() {
        if (GlobalStates.mediaControlsOpen || GlobalStates.samaelMediaClosing)
            return
        if (!barScreenName.length || centerDock.width <= 0)
            return
        const focused = Hyprland.focusedMonitor?.name ?? ""
        if (focused.length && focused !== barScreenName)
            return
        const seam = centerDock.mapToItem(root, centerDock.width / 2, centerDock.modulesH)
        GlobalStates.samaelMediaScreenName = barScreenName
        GlobalStates.samaelMediaCenterX = barMarginLeft + seam.x
        GlobalStates.samaelMediaDockTop = barMarginTop + seam.y
        GlobalStates.samaelMediaDockLeft = barMarginLeft + seam.x - centerDock.width / 2
        GlobalStates.samaelMediaDockWidth = centerDock.width
    }

    function publishIslandAnchor() {
        if (!barScreenName.length || centerModules.width <= 0)
            return
        const focused = Hyprland.focusedMonitor?.name ?? ""
        if (focused.length && focused !== barScreenName)
            return
        const bottom = centerDock.mapToItem(root, centerDock.width / 2, centerDock.modulesH)
        GlobalStates.samaelIslandScreenName = barScreenName
        GlobalStates.samaelIslandTop = barMarginTop + bottom.y - 1
        GlobalStates.samaelIslandLeft = barMarginLeft + bottom.x - centerDock.width / 2
        GlobalStates.samaelIslandWidth = centerDock.width
        GlobalStates.samaelIslandAnchorValid = true
    }

    onWidthChanged: {
        publishIslandAnchor()
        publishMediaDockAnchor()
        publishPerformanceDockAnchor()
    }
    Component.onCompleted: {
        publishIslandAnchor()
        publishMediaDockAnchor()
        publishPerformanceDockAnchor()
    }

    Connections {
        target: GlobalStates
        function onMediaControlsOpenChanged() {
            if (GlobalStates.mediaControlsOpen) {
                GlobalStates.samaelMediaClosing = false
                const w = centerModules.implicitWidth
                if (w > 40)
                    root.cachedCenterBarW = w
                const seam = centerDock.mapToItem(root, centerDock.width / 2, centerDock.modulesH)
                GlobalStates.samaelMediaScreenName = barScreenName
                GlobalStates.samaelMediaCenterX = barMarginLeft + seam.x
                GlobalStates.samaelMediaDockTop = barMarginTop + seam.y
                GlobalStates.samaelMediaDockLeft = barMarginLeft + seam.x - centerDock.width / 2
                GlobalStates.samaelMediaDockWidth = centerDock.width
            } else {
                publishMediaDockAnchor()
            }
        }
        function onSamaelPerformanceDropOpenChanged() {
            if (GlobalStates.samaelPerformanceDropOpen) {
                GlobalStates.samaelPerformanceClosing = false
                const w = centerModules.implicitWidth
                if (w > 40)
                    root.cachedCenterBarW = w
                const seam = centerDock.mapToItem(root, centerDock.width / 2, centerDock.modulesH)
                GlobalStates.samaelPerformanceScreenName = barScreenName
                GlobalStates.samaelPerformanceCenterX = barMarginLeft + seam.x
                GlobalStates.samaelPerformanceDockTop = barMarginTop + seam.y
                GlobalStates.samaelPerformanceDockLeft = barMarginLeft + seam.x - centerDock.width / 2
                GlobalStates.samaelPerformanceDockWidth = centerDock.width
            } else {
                publishPerformanceDockAnchor()
            }
        }
    }

    Connections {
        target: centerDock
        function onWidthChanged() {
            root.publishIslandAnchor()
            root.publishMediaDockAnchor()
            root.publishPerformanceDockAnchor()
        }
    }
    Connections {
        target: Notifications
        function onNotify() {
            root.publishIslandAnchor()
            GlobalStates.samaelIslandPulse = 1
            islandPulseDecay.restart()
        }
        function onListChanged() { root.publishIslandAnchor() }
    }
    Timer {
        id: islandPulseDecay
        interval: 500
        onTriggered: GlobalStates.samaelIslandPulse = 0
    }

    SamaelModuleGroup {
        id: leftGroup
        anchors {
            left: parent.left
            verticalCenter: barRowAnchor.verticalCenter
        }
        AppDrawerGroup {}
        Separator { variant: "dot-line" }
        MotherboardGroup {
            id: motherboardGroup
            Component.onCompleted: SamaelBarNavHub.motherboard = motherboardGroup
            Component.onDestruction: {
                if (SamaelBarNavHub.motherboard === motherboardGroup)
                    SamaelBarNavHub.motherboard = null
            }
        }
        Separator { variant: "line" }
        WeatherWidget {}
    }

    Item {
        id: barRowAnchor
        anchors.left: parent.left
        anchors.right: parent.right
        height: barRowH
        y: 0
    }

    Item {
        id: centerDock
        readonly property real barW: centerModules.implicitWidth
        readonly property real lerpBarW: root.cachedCenterBarW > 40 ? root.cachedCenterBarW : barW
        readonly property real modulesH: centerModules.implicitHeight
        readonly property bool dockExpanded: GlobalStates.mediaControlsOpen
                || GlobalStates.samaelMediaClosing
                || GlobalStates.samaelPerformanceDropOpen
                || GlobalStates.samaelPerformanceClosing

        width: GlobalStates.mediaControlsOpen
            ? root.mediaPanelWidth
            : (GlobalStates.samaelPerformanceDropOpen ? root.performancePanelWidth : lerpBarW)
        height: modulesH
        x: (root.width - width) / 2
        y: (root.barRowH - modulesH) / 2
        clip: true

        Behavior on width {
            NumberAnimation {
                duration: Appearance.animation.samaelMediaAttach.duration
                easing.type: Appearance.animation.samaelMediaAttach.type
                easing.bezierCurve: Appearance.animation.samaelMediaAttach.bezierCurve
            }
        }

        /** Seam to media drop: flat bottom, rounded top only */
        readonly property int dockChromeR: 15
        readonly property int dockFillR: 13

        Rectangle {
            anchors.fill: parent
            visible: centerDock.dockExpanded
            color: "transparent"
            border.width: 2
            border.color: WallustColors.borderColor
            topLeftRadius: centerDock.dockChromeR
            topRightRadius: centerDock.dockChromeR
            bottomLeftRadius: 0
            bottomRightRadius: 0
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: centerDock.dockExpanded ? 2 : 0
            anchors.bottomMargin: centerDock.dockExpanded ? 0 : 0
            visible: centerDock.dockExpanded
            color: SamaelStyle.menuPanelFill
            topLeftRadius: centerDock.dockFillR
            topRightRadius: centerDock.dockFillR
            bottomLeftRadius: 0
            bottomRightRadius: 0
        }

        Item {
            width: parent.width
            height: centerModules.implicitHeight
            anchors.verticalCenter: parent.verticalCenter

            SamaelModuleGroup {
                id: centerModules
                chromeless: centerDock.dockExpanded
                layoutExpand: clockModule.expanded ? 1 : 0
                width: centerDock.dockExpanded ? parent.width : implicitWidth
                x: centerDock.dockExpanded ? 0 : (parent.width - width) / 2
                y: 0

                NotificationIndicator {}
                CavaVisualizer {}
                Separator { variant: "dot-line" }
                ClockWidget { id: clockModule }
                Separator { variant: "line" }
                KanjiWorkspaces {}
                Separator { variant: "dot-line" }
                IdleInhibitor {}
            }
        }
    }

    SamaelModuleGroup {
        id: rightGroup
        anchors {
            right: parent.right
            verticalCenter: barRowAnchor.verticalCenter
        }
        NetworkSpeed {}
        ConnectionsGroup {}
        Separator { variant: "line" }
        SysTrayWidget {}
        MediaWidget {}
        AudioGroup {}
        Separator { variant: "dot-line" }
        StatusGroup {}
    }
}
