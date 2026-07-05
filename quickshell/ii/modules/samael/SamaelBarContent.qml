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
    readonly property int mediaPanelWidth: 680

    property real cachedCenterBarW: 0
    property real cachedMediaBodyH: 300

    readonly property real barRowH: Math.max(
        leftGroup.implicitHeight,
        centerModules.implicitHeight,
        rightGroup.implicitHeight)

    /** Bar row fixed; extra paint only while media slot open (no eased height — avoids bar bounce) */
    readonly property real paintHeight: barRowH + (centerDock.dockExpanded ? centerDock.bodyH : 0)

    implicitHeight: paintHeight

    function refreshMediaBodyCache() {
        const h = mediaManager.implicitHeight
        if (h > 80)
            cachedMediaBodyH = h
    }

    readonly property var centerDockRef: centerDock

    function focusMediaPanel() {
        if (GlobalStates.mediaControlsOpen)
            mediaManager.forceActiveFocus()
    }

    function releaseMediaKeyboard() {
        mediaManager.focus = false
        mediaManager.enabled = false
        Qt.callLater(() => {
        mediaManager.enabled = true
        Hyprland.dispatch("focuscurrent")
        })
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

    onWidthChanged: publishIslandAnchor()
    Component.onCompleted: publishIslandAnchor()

    Connections {
        target: GlobalStates
        function onMediaControlsOpenChanged() {
            if (GlobalStates.mediaControlsOpen) {
                const w = centerModules.implicitWidth
                if (w > 40)
                    root.cachedCenterBarW = w
                centerDock.mediaOffset = 1
                Qt.callLater(() => {
                    root.refreshMediaBodyCache()
                    centerDock.mediaOffset = 0
                })
                attachOpenDelay.restart()
            } else {
                centerDock.mediaOffset = 1
                mediaManager.focus = false
            }
        }
    }
    Connections {
        target: centerDock
        function onMediaOffsetChanged() {
            if (!GlobalStates.mediaControlsOpen)
                return
            if (centerDock.mediaOffset < 0.02)
                Qt.callLater(root.focusMediaPanel)
        }
    }
    Timer {
        id: attachOpenDelay
        interval: 50
        onTriggered: root.refreshMediaBodyCache()
    }

    Connections {
        target: centerDock
        function onWidthChanged() { root.publishIslandAnchor() }
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
        readonly property real bodyH: root.cachedMediaBodyH

        /** Caelestia offsetScale: 0 open, 1 closed */
        property real mediaOffset: 1
        readonly property real t: Math.min(1, Math.max(0, mediaOffset))
        /** Slide + layout only — clamp so easing never overshoots past open/closed */
        readonly property real tSlide: t
        readonly property real mediaExpand: 1 - tSlide
        readonly property bool slideActive: tSlide < 0.999
        /** Wide/tall slot while open or finishing close slide */
        readonly property bool dockExpanded: GlobalStates.mediaControlsOpen || slideActive
        readonly property bool layoutWide: dockExpanded

        width: layoutWide ? root.mediaPanelWidth : lerpBarW
        height: modulesH + (layoutWide ? bodyH : 0)
        x: (root.width - width) / 2
        y: (root.barRowH - modulesH) / 2
        clip: true

        Behavior on mediaOffset {
            NumberAnimation {
                duration: Appearance.animation.samaelMediaAttach.duration
                easing.type: Appearance.animation.samaelMediaAttach.type
                easing.bezierCurve: Appearance.animation.samaelMediaAttach.bezierCurve
            }
        }

        Rectangle {
            anchors.fill: parent
            visible: centerDock.dockExpanded
            radius: 15
            color: "transparent"
            border.width: 2
            border.color: WallustColors.borderColor
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: centerDock.dockExpanded ? 2 : 0
            visible: centerDock.dockExpanded
            radius: 13
            color: SamaelStyle.menuPanelFill
        }

        Column {
            anchors.fill: parent
            anchors.margins: centerDock.dockExpanded ? 2 : 0
            spacing: 0

                Item {
                    width: parent.width
                    height: centerModules.implicitHeight

                    SamaelModuleGroup {
                        id: centerModules
                        chromeless: centerDock.layoutWide
                        width: centerDock.layoutWide ? parent.width : implicitWidth
                        x: centerDock.layoutWide ? 0 : (parent.width - width) / 2
                        y: 0

                        NotificationIndicator {}
                CavaVisualizer {}
                Separator { variant: "dot-line" }
                ClockWidget {}
                Separator { variant: "line" }
                KanjiWorkspaces {}
                Separator { variant: "dot-line" }
                        IdleInhibitor {}
                    }
                }

                Item {
                    id: mediaBodyClip
                width: parent.width
                height: centerDock.layoutWide ? centerDock.bodyH : 0
                clip: true

                SamaelMediaManager {
                    id: mediaManager
                    width: root.mediaPanelWidth
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: -(centerDock.bodyH + 5) * centerDock.tSlide
                    embeddedInBar: true

                    onImplicitHeightChanged: if (GlobalStates.mediaControlsOpen) root.refreshMediaBodyCache()
                }
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