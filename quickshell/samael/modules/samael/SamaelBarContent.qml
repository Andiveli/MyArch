import QtQuick
import qs
import qs.modules.common
import qs.services
import qs.modules.samael
import qs.modules.samael.widgets
import "../../../Singletons" as Pill

Item {
    id: root
    property string barScreenName: ""

    readonly property int barMarginTop: 3
    readonly property int barMarginLeft: 8

    // ── Test hooks (refs for structural testing) ──
    property alias idleModulesRef: modulesWrapper
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
readonly property real barRowH: Math.max(
        leftGroup.implicitHeight,
        centerModules.implicitHeight,
        rightGroup.implicitHeight)
    
readonly property real paintHeight: Math.max(barRowH, centerDock.y + centerDock.height)
implicitHeight: paintHeight

readonly property var centerDockRef: centerDock

    // ── Surface item tracking for keyboard routing ──
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
performance:      ldPerformance
        })[surfaceId] ?? null
    }

    function _syncSurfaceItemToHub() {
        const sid = centerDock.surface
        const ld = _getSurfaceLoader(sid === "idle" ? "" : sid)
        SamaelBarNavHub.currentSurfaceItem = ld?.item ?? null
    }

    Connections {
        target: centerDock
        function onSurfaceChanged() {
root._syncSurfaceItemToHub()
centerDock.scheduleKeyboardFocus()
        }
    }

    Component.onCompleted: _syncSurfaceItemToHub()





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
    
        // ── Reactive surface cascade (pill-aligned) ──
        // Precedence here mirrors SamaelCenterSurface (dock reads GlobalStates directly).
        function resolveCenterSurface() {
            if (GlobalStates.wallpaperSelectorOpen)
                return "wallpaper"
            if (GlobalStates.sessionOpen)
                return "power"
            if (GlobalStates.samaelNotificationsMenuOpen)
                return "notificationsMenu"
            if (GlobalStates.mediaControlsOpen || GlobalStates.samaelMediaClosing)
                return "media"
            if (GlobalStates.samaelPerformanceDropOpen || GlobalStates.samaelPerformanceClosing)
                return "performance"
            if (GlobalStates.samaelWifiMenuOpen)
                return "wifi"
            if (GlobalStates.samaelBluetoothMenuOpen)
                return "bluetooth"
            if (GlobalStates.samaelClockDropOpen)
                return "calendar"
            if (GlobalStates.samaelRecorderOpen)
                return "screenRecorder"
            return "idle"
        }

        readonly property string surface: resolveCenterSurface()
            readonly property bool surfaceOpen: surface !== "idle"
            readonly property bool expanded: surfaceOpen

                function tryFocusKeyboardPanel() {
                    if (!surfaceOpen)
                        return false
                    const ld = root._getSurfaceLoader(surface)
                    const item = ld?.item
                    if (!item)
                        return false
                    const panel = item.keyboardPanel ?? item
                    panel.forceActiveFocus()
                    return true
                }

                function stopKeyboardFocusRetry() {
                    keyboardFocusRetry.stop()
                }

                function scheduleKeyboardFocus() {
                    if (!surfaceOpen) {
                        keyboardFocusRetry.stop()
                        return
                    }
                    if (tryFocusKeyboardPanel())
                        keyboardFocusRetry.stop()
                    else
                        keyboardFocusRetry.start()
                }

                Timer {
                    id: keyboardFocusRetry
                    interval: 40
                    repeat: true
                    onTriggered: {
                        if (centerDock.tryFocusKeyboardPanel())
                            stop()
                    }
                }
        
            // ── Surface loader helper: activate on first read, never unload ──
        function surfaceItem(ld) {
            ld.active = true
            return ld.item
        }
    
        // ── Surfaces table: size thunks match pill/Pill.qml pattern ──
        readonly property var surfaces: ({
            calendar:          { size: () => { const it = surfaceItem(ldCalendar); return Qt.size(it.implicitWidth + 36, it.implicitHeight + 32); } },
            notificationsMenu: { size: () => { const it = surfaceItem(ldNotificationsMenu); return Qt.size(it.implicitWidth, it.implicitHeight); } },
            wifi:              { size: () => { const it = surfaceItem(ldWifi); return Qt.size(it.implicitWidth, it.implicitHeight); } },
            bluetooth:         { size: () => { const it = surfaceItem(ldBluetooth); return Qt.size(it.implicitWidth, it.implicitHeight); } },
            screenRecorder:    { size: () => { const it = surfaceItem(ldScreenRecorder); return Qt.size(it.implicitWidth, it.implicitHeight); } },
            wallpaper:         { size: () => { const it = surfaceItem(ldWallpaper); return Qt.size(it.implicitWidth, it.implicitHeight); } },
            power:             { size: () => { const it = surfaceItem(ldPower); return Qt.size(it.implicitWidth, it.implicitHeight); } },
            media:             { size: () => { const it = surfaceItem(ldMedia); return Qt.size(it.implicitWidth, it.implicitHeight); } },
            performance:       { size: () => { const it = surfaceItem(ldPerformance); return Qt.size(it.implicitWidth, it.implicitHeight); } }
        })
    
        readonly property var modeSize: ({
            idle: () => Qt.size(centerModules.implicitWidth, centerModules.implicitHeight)
        })
    
            readonly property size targetSize: {
                if (!surfaceOpen)
                    return Qt.size(centerModules.implicitWidth, centerModules.implicitHeight)
                const ld = root._getSurfaceLoader(surface)
                if (ld)
                    ld.active = true
                const it = ld?.item
                if (it && it.implicitWidth > 0 && it.implicitHeight > 0) {
                    const sf = surfaces[surface]
                    if (sf)
                        return sf.size()
                    return Qt.size(it.implicitWidth, it.implicitHeight)
                }
                const mins = surfaces[surface]
                if (mins) {
                    const ld2 = root._getSurfaceLoader(surface)
                    if (ld2?.item)
                        return mins.size()
                }
                return Qt.size(Math.max(centerModules.implicitWidth, 320),
                               Math.max(centerModules.implicitHeight, 280))
            }
            readonly property real targetW: targetSize.width
            readonly property real targetH: targetSize.height

            width: targetW
            height: targetH
        x: (root.width - width) / 2
        y: 0
        clip: false

        readonly property bool idleMorphHop: !surfaceOpen || surface === "idle"
        readonly property int morphDuration: idleMorphHop ? Pill.Motion.glide : Pill.Motion.morph

        Behavior on width { NumberAnimation { duration: centerDock.morphDuration; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: centerDock.morphDuration; easing.type: Easing.OutCubic } }

        // ── Morph closeness: syncs all content fade with the geometry morph ──
        readonly property real morphCloseness: {
            const d = Math.max(Math.abs(width - targetW), Math.abs(height - targetH))
            return 1 - Math.min(1, d / (110 * 1))
        }

        // ── Chrome: uniform rounded corners (no seam — drops are in-dock) ──
        readonly property int dockR: 15

        Rectangle {
            anchors.fill: parent
            visible: centerDock.surfaceOpen
            color: "transparent"
            border.width: 2
            border.color: WallustColors.borderColor
            radius: centerDock.dockR
        }

            Rectangle {
                anchors.fill: parent
                anchors.margins: centerDock.surfaceOpen ? 2 : 0
                visible: centerDock.surfaceOpen
                color: SamaelStyle.menuPanelFill
                radius: centerDock.dockR - 2
            }

            // ── Idle content (center modules) — fades out via morphCloseness ──
        // Matches pill's `rest` section exactly.
        Item {
            id: modulesWrapper
            anchors.fill: parent
            opacity: centerDock.expanded ? 0 : Math.pow(centerDock.morphCloseness, 1.5)
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: Pill.Motion.fast; easing.type: Easing.OutCubic } }

            /** Idle widgets stay on the bar row — not vertically re-centered as the dock grows. */
            Item {
                id: centerModulesBand
                anchors.top: parent.top
                width: parent.width
                height: root.barRowH

                SamaelModuleGroup {
                id: centerModules
                chromeless: false
                layoutExpand: clockModule.expanded ? 1 : 0
                width: implicitWidth
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

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

        // ── Surface loaders (pill-aligned) ──
        // Each starts inactive and is lazy-activated by surfaceItem() on first open.
        // Once activated, the loader stays active forever (never unloads).
        // No asynchronous flag: surfaceItem() needs synchronous load for exact size.

        Loader {
            id: ldCalendar
            anchors.fill: parent
            active: false
            z: 1
            sourceComponent: SamaelCalendarSurface {
                open: centerDock.surface === "calendar"
                morphCloseness: centerDock.morphCloseness
            }
        }

        Loader {
            id: ldNotificationsMenu
            anchors.fill: parent
            active: false
            z: 2
            sourceComponent: SamaelNotificationsMenuSurface {
                open: centerDock.surface === "notificationsMenu"
                morphCloseness: centerDock.morphCloseness
            }
        }

        Loader {
            id: ldWifi
            anchors.fill: parent
            active: false
            z: 3
            sourceComponent: SamaelWifiSurface {
                open: centerDock.surface === "wifi"
                morphCloseness: centerDock.morphCloseness
            }
        }

        Loader {
            id: ldBluetooth
            anchors.fill: parent
            active: false
            z: 4
            sourceComponent: SamaelBluetoothSurface {
                open: centerDock.surface === "bluetooth"
                morphCloseness: centerDock.morphCloseness
            }
        }

        Loader {
            id: ldScreenRecorder
            anchors.fill: parent
            active: false
            z: 5
            sourceComponent: SamaelScreenRecorderSurface {
                open: centerDock.surface === "screenRecorder"
                morphCloseness: centerDock.morphCloseness
            }
        }

        Loader {
            id: ldWallpaper
            anchors.fill: parent
            active: false
            z: 6
            sourceComponent: SamaelWallpaperSurface {
                open: centerDock.surface === "wallpaper"
                morphCloseness: centerDock.morphCloseness
            }
        }

        Loader {
            id: ldPower
            anchors.fill: parent
            active: false
            z: 7
            sourceComponent: SamaelSessionSurface {
                open: centerDock.surface === "power"
                morphCloseness: centerDock.morphCloseness
            }
        }

        Loader {
            id: ldMedia
            anchors.fill: parent
            active: false
            z: 8
            sourceComponent: SamaelMediaSurface {
                open: centerDock.surface === "media"
                morphCloseness: centerDock.morphCloseness
            }
        }

        Loader {
            id: ldPerformance
            anchors.fill: parent
            active: false
            z: 9
            sourceComponent: SamaelPerformanceSurface {
                open: centerDock.surface === "performance"
                morphCloseness: centerDock.morphCloseness
            }
        }

        // ── Preload hot surfaces after startup (pill pattern) ──
        Timer {
            interval: 2500
            running: GlobalStates.barOpen
            onTriggered: {
                ldMedia.active = true
                ldPerformance.active = true
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
