import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs
import qs.modules.common
import qs.services
import qs.modules.samael
import qs.modules.samael.widgets
import "../../../pill/Singletons" as Pill

Item {
    id: root
    property string barScreenName: ""

    readonly property int barMarginTop: 3
    readonly property int barMarginLeft: 8

    property real cachedCenterBarW: 0

    // ── Test hooks (refs for structural testing) ──
    property alias centerDockModulesRef: centerDockModules
    property alias surfaceStackRef: surfaceStack
    property alias centerModulesRef: centerModules
    property alias ldCalendarRef: ldCalendar
    property alias ldNotificationsMenuRef: ldNotificationsMenu
    property alias ldWifiRef: ldWifi
    property alias ldBluetoothRef: ldBluetooth
    property alias ldScreenRecorderRef: ldScreenRecorder
    property alias ldWallpaperRef: ldWallpaper
    property alias ldPowerRef: ldPower
    property alias ldMediaRef: ldMedia
    property alias ldPerformanceRef: ldPerformance
    property alias ldPopupIslandRef: ldPopupIsland

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

    // ── Surface item tracking for keyboard routing ──
    // Uses a function instead of a readonly property to avoid forward-id
    // issues: the value is resolved at call time, not during construction.
    function _getSurfaceLoader(surfaceId) {
        return ({
idle:             null,
calendar:         ldCalendar,
notificationsMenu:ldNotificationsMenu,
wifi:             ldWifi,
bluetooth:        ldBluetooth,
screenRecorder:   ldScreenRecorder,
wallpaper:        ldWallpaper,
power:            ldPower,
media:            ldMedia,
performance:      ldPerformance,
popupIsland:      ldPopupIsland
        })[surfaceId] ?? null
    }
    
    Connections {
        target: SamaelCenterSurface
        function onEffectiveSurfaceChanged() {
const ld = root._getSurfaceLoader(SamaelCenterSurface.effectiveSurface)
SamaelBarNavHub.currentSurfaceItem = ld?.item ?? null
        }
    }
    
    Component.onCompleted: {
        const ld = _getSurfaceLoader(SamaelCenterSurface.effectiveSurface)
        SamaelBarNavHub.currentSurfaceItem = ld?.item ?? null
        publishIslandAnchor()
        publishMediaDockAnchor()
        publishPerformanceDockAnchor()
    }
    onWidthChanged: {
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

    // ── Center surface controller (per-bar geometry from surfaces table) ──
    readonly property QtObject controller: QtObject {
        readonly property var surfaces: ({
        idle:             { size: () => Qt.size(centerModules.implicitWidth, centerModules.implicitHeight) },
        calendar:         SamaelCenterSurface.surfaceEntry("calendar", root.barScreenName),
        notificationsMenu:SamaelCenterSurface.surfaceEntry("notificationsMenu", root.barScreenName),
        wifi:             SamaelCenterSurface.surfaceEntry("wifi", root.barScreenName),
        bluetooth:        SamaelCenterSurface.surfaceEntry("bluetooth", root.barScreenName),
        screenRecorder:   SamaelCenterSurface.surfaceEntry("screenRecorder", root.barScreenName),
        wallpaper:        SamaelCenterSurface.surfaceEntry("wallpaper", root.barScreenName),
        power:            SamaelCenterSurface.surfaceEntry("power", root.barScreenName),
        media:            SamaelCenterSurface.surfaceEntry("media", root.barScreenName),
        performance:      SamaelCenterSurface.surfaceEntry("performance", root.barScreenName),
        popupIsland:      SamaelCenterSurface.surfaceEntry("popupIsland", root.barScreenName)
        })

        readonly property size targetSize: {
        const entry = surfaces[SamaelCenterSurface.effectiveSurface]
        return entry ? entry.size() : Qt.size(centerModules.implicitWidth, centerModules.implicitHeight)
        }

        readonly property real targetW: targetSize.width
        readonly property real targetH: targetSize.height
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
        readonly property real modulesH: centerModules.implicitHeight
        readonly property bool dockExpanded: SamaelCenterSurface.effectiveSurface !== "idle"
        /// [0,1] how close the dock is to its target size. 1 = fully morphed.
        readonly property real morphCloseness: SamaelCenterSurface.computeMorphCloseness(
            width, height, controller.targetW, controller.targetH, 1)

        width: controller.targetW
        height: controller.targetH
        x: (root.width - width) / 2
        y: (root.barRowH - modulesH) / 2
        clip: true

        Behavior on width {
            enabled: centerDock.dockExpanded
            NumberAnimation {
                duration: Pill.Motion.morph
                easing.type: Pill.Motion.easeMorph
                easing.bezierCurve: Pill.Motion.morphCurve
            }
        }

        Behavior on height {
            enabled: centerDock.dockExpanded
            NumberAnimation {
                duration: Pill.Motion.morph
                easing.type: Pill.Motion.easeMorph
                easing.bezierCurve: Pill.Motion.morphCurve
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

        // ── Center modules — fade out when a surface opens ──
        Item {
            id: centerDockModules
            width: parent.width
            height: parent.height

            SamaelModuleGroup {
                id: centerModules
                chromeless: centerDock.dockExpanded
                layoutExpand: clockModule.expanded ? 1 : 0
                // Cross-fade: hide modules when a user surface is open.
                // Defensive: if effectiveSurface is empty/unset, keep modules visible.
                opacity: {
                    const s = SamaelCenterSurface.effectiveSurface
                    if (!s || s === "idle" || s === "popupIsland") return 1
                    return 0
                }
                Behavior on opacity { NumberAnimation { duration: Pill.Motion.standard } }
                width: centerDock.dockExpanded ? parent.width : implicitWidth
                x: centerDock.dockExpanded ? 0 : (parent.width - width) / 2
                y: (parent.height - height) / 2

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

        // ── Surface stack (faded when a surface is open) ──
        Item {
            id: surfaceStack
            width: parent.width
            height: parent.height
            opacity: SamaelCenterSurface.effectiveSurface !== "idle" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Pill.Motion.standard } }

                Loader {
                    id: ldPopupIsland
                    anchors.fill: parent
                    active: Notifications.popupList.length > 0 && !GlobalStates.screenLocked
                    asynchronous: true
                    z: 0
                    sourceComponent: Component {
                        SamaelPillSurface {
                            anchors.fill: parent
                            open: true
                            morphCloseness: centerDock.morphCloseness
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 4
                                color: "#F39C12"
                                Text {
                                    anchors.centerIn: parent
                                    text: "Notifications Popup"
                                    color: "white"
                                    font.pixelSize: 14
                                }
                            }
                        }
                    }
                }

                Loader {
                    id: ldCalendar
                    anchors.fill: parent
                    active: GlobalStates.samaelClockDropOpen
                    asynchronous: true
                    z: 1
                    sourceComponent: SamaelCalendarSurface {
                        open: true
                        morphCloseness: centerDock.morphCloseness
                    }
                }

                Loader {
                    id: ldNotificationsMenu
                    anchors.fill: parent
                    active: GlobalStates.samaelNotificationsMenuOpen
                    asynchronous: true
                    z: 2
                    sourceComponent: SamaelNotificationsMenuSurface {
                        open: true
                        morphCloseness: centerDock.morphCloseness
                    }
                }

                Loader {
                    id: ldWifi
                    anchors.fill: parent
                    active: GlobalStates.samaelWifiMenuOpen
                    asynchronous: true
                    z: 3
                    sourceComponent: SamaelWifiSurface {
                        open: true
                        morphCloseness: centerDock.morphCloseness
                    }
                }

                Loader {
                    id: ldBluetooth
                    anchors.fill: parent
                    active: GlobalStates.samaelBluetoothMenuOpen
                    asynchronous: true
                    z: 4
                    sourceComponent: SamaelBluetoothSurface {
                        open: true
                        morphCloseness: centerDock.morphCloseness
                    }
                }

                Loader {
                    id: ldScreenRecorder
                    anchors.fill: parent
                    active: GlobalStates.samaelRecorderOpen
                    asynchronous: true
                    z: 5
                    sourceComponent: SamaelScreenRecorderSurface {
                        open: true
                        morphCloseness: centerDock.morphCloseness
                    }
                }

                Loader {
                    id: ldWallpaper
                    anchors.fill: parent
                    active: GlobalStates.wallpaperSelectorOpen
                    asynchronous: true
                    z: 6
                    sourceComponent: SamaelWallpaperSurface {
                        open: true
                        morphCloseness: centerDock.morphCloseness
                    }
                }

                Loader {
                    id: ldPower
                    anchors.fill: parent
                    active: GlobalStates.sessionOpen
                    asynchronous: true
                    z: 7
                    sourceComponent: SamaelSessionSurface {
                        open: true
                        morphCloseness: centerDock.morphCloseness
                    }
                }

                Loader {
                    id: ldMedia
                    anchors.fill: parent
                    active: GlobalStates.mediaControlsOpen || GlobalStates.samaelMediaClosing
                    asynchronous: true
                    z: 8
                    sourceComponent: SamaelMediaSurface {
                        open: true
                        morphCloseness: centerDock.morphCloseness
                    }
                }

                Loader {
                    id: ldPerformance
                    anchors.fill: parent
                    active: GlobalStates.samaelPerformanceDropOpen || GlobalStates.samaelPerformanceClosing
                    asynchronous: true
                    z: 9
                    sourceComponent: SamaelPerformanceSurface {
                        open: true
                        morphCloseness: centerDock.morphCloseness
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
