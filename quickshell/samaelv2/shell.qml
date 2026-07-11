//@ pragma UseQApplication

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "singletons"
import "bar"

ShellRoot {
    id: root

    Component.onCompleted: {
        ShellActions.toggleMedia = () => root.toggleSurface("", "media")
        ShellActions.toggleNotifications = () => root.toggleSurface("", "notifications")
        ShellActions.toggleWifi = () => root.toggleSurface("", "wifi")
        ShellActions.toggleBluetooth = () => root.toggleSurface("", "bluetooth")
        ShellActions.toggleOverview = () => root.toggleRightSurface("", "overview")
        ShellActions.closeMiddleSurface = () => root.closeMiddleOnly()
        ShellActions.closeRightSurface = () => root.closeRightOnly()
    }

    property string openMon: ""
    property string openSurface: ""
    property string openLeftMon: ""
    property string openLeftSurface: ""
    property string openRightMon: ""
    property string openRightSurface: ""
    property string hyprFocusBeforePill: ""

    function captureHyprClientFocus() {
        const addr = Hyprland.activeToplevel?.lastIpcObject?.address
        if (addr)
            root.hyprFocusBeforePill = String(addr)
    }

    function restoreHyprClientFocus() {
        const addr = root.hyprFocusBeforePill
        root.hyprFocusBeforePill = ""
        if (addr.length === 0)
            return
        const cmd = `hl.dsp.focus({ window = "address:${addr}" })`
        Hyprland.dispatch(cmd)
        Qt.callLater(() => Hyprland.dispatch(cmd))
    }

    function _focusedMon() {
        return Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
    }

    function toggleSurface(mon, surface) {
        if (!mon || mon.length === 0)
            mon = _focusedMon()
        if (root.openMon === mon && root.openSurface === surface) {
            root.close()
            return
        }
        root.captureHyprClientFocus()
        root.openMon = mon
        root.openSurface = surface
    }

    function toggleLeftSurface(mon, surface) {
        if (!mon || mon.length === 0)
            mon = _focusedMon()
        if (root.openLeftMon === mon && root.openLeftSurface === surface) {
            root.openLeftSurface = ""
            root.openLeftMon = ""
            Qt.callLater(root.restoreHyprClientFocus)
            return
        }
        root.captureHyprClientFocus()
        root.openLeftMon = mon
        root.openLeftSurface = surface
    }

    function closeMiddleOnly() {
        root.openMon = ""
        root.openSurface = ""
        if (!root.openRightSurface.length && !root.openLeftSurface.length)
Qt.callLater(root.restoreHyprClientFocus)
    }

    function closeRightOnly() {
        root.openRightMon = ""
        root.openRightSurface = ""
        if (!root.openSurface.length && !root.openLeftSurface.length)
Qt.callLater(root.restoreHyprClientFocus)
    }

    function close() {
        root.openMon = ""
        root.openSurface = ""
        root.openLeftMon = ""
        root.openLeftSurface = ""
        root.openRightMon = ""
        root.openRightSurface = ""
        Qt.callLater(root.restoreHyprClientFocus)
    }

    function toggleRightSurface(mon, surface) {
        if (!mon || mon.length === 0)
mon = _focusedMon()
        if (root.openRightMon === mon && root.openRightSurface === surface) {
root.closeRightOnly()
return
        }
        root.captureHyprClientFocus()
        root.openRightMon = mon
        root.openRightSurface = surface
    }

    function toggleWallpaper() {
        root.toggleSurface("", "wallpaper")
    }

    function wallpaperRandom() {
        const dir = ShellConfig.wallpaperDir.replace(/"/g, "\\\"")
        randomWallProc.command = ["bash", "-c",
        'd="' + dir + '"; mapfile -t a < <(find -L "$d" -type f \\( -iname \'*.jpg\' -o -iname \'*.jpeg\' -o -iname \'*.png\' -o -iname \'*.webp\' \\) 2>/dev/null); ' +
        '[[ ${#a[@]} -gt 0 ]] && bash "$HOME/.config/hypr/scripts/samael-wallpaper.sh" "${a[$RANDOM % ${#a[@]}]}"']
        randomWallProc.running = true
    }

    GlobalShortcut {
        name: "mediaControlsToggle"
        description: "samaelv2 media pill (middle)"
        onPressed: root.toggleSurface("", "media")
    }

    GlobalShortcut {
        name: "samaelNotificationsMenuToggle"
        description: "samaelv2 notifications menu (middle) — Hypr SUPER+SHIFT+N"
        onPressed: root.toggleSurface("", "notifications")
    }

    GlobalShortcut {
        name: "samaelWifiMenuToggle"
        description: "samaelv2 Wi-Fi menu (middle) — Hypr SUPER+SHIFT+W"
        onPressed: root.toggleSurface("", "wifi")
    }

    GlobalShortcut {
        name: "samaelBluetoothMenuToggle"
        description: "samaelv2 Bluetooth menu (middle) — Hypr SUPER+SHIFT+B"
        onPressed: root.toggleSurface("", "bluetooth")
    }

    GlobalShortcut {
        name: "samaelOverviewToggle"
        description: "samaelv2 system overview (right pill) — Hypr SUPER+SHIFT+O"
        onPressed: root.toggleRightSurface("", "overview")
    }

    GlobalShortcut {
        name: "wallpaperSelectorToggle"
        description: "samaelv2 wallpaper filmstrip (SUPER+W)"
        onPressed: root.toggleWallpaper()
    }

    GlobalShortcut {
        name: "wallpaperSelectorRandom"
        description: "samaelv2 random wallpaper"
        onPressed: root.wallpaperRandom()
    }

    Process { id: randomWallProc }

    IpcHandler {
        target: "samaelv2"
        function openMedia(): void { root.toggleSurface("", "media") }
        function openNotifications(): void { root.toggleSurface("", "notifications") }
        function openWifi(): void { root.toggleSurface("", "wifi") }
        function wifi(): void { root.toggleSurface("", "wifi") }
        function openBluetooth(): void { root.toggleSurface("", "bluetooth") }
        function bluetooth(): void { root.toggleSurface("", "bluetooth") }
            function openOverview(): void { root.toggleRightSurface("", "overview") }
            function overview(): void { root.toggleRightSurface("", "overview") }
        function media(mon: string): void { root.toggleSurface(mon, "media") }
        function notifications(mon: string): void { root.toggleSurface(mon, "notifications") }
        function hide(): void { root.close() }
        function page(mon: string, name: string): void { root.toggleSurface(mon, name) }
        function wallpaper(): void { root.toggleWallpaper() }
    }

    IpcHandler {
        target: "wallpaperSelector"
        function toggle(): void { root.toggleWallpaper() }
        function random(): void { root.wallpaperRandom() }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: reserve
            required property var modelData
            visible: ShellConfig.barEnabled
            screen: modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Normal
            aboveWindows: true
            WlrLayershell.namespace: "quickshell:samaelv2:reserve"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors { top: true; left: true; right: true }

            margins {
                top: 0
                bottom: 2
                left: 0
                right: 0
            }

            readonly property bool leftOpen: root.openLeftMon === modelData.name && root.openLeftSurface.length > 0

            readonly property int barPaintHeight: ShellConfig.barMarginTop
                    + Style.barContentHeight
                    + ShellConfig.sectionBottomMargin
                    + Style.barReserveSlop
                    + margins.top
                    + margins.bottom

            implicitWidth: modelData.width
            implicitHeight: barPaintHeight
            exclusiveZone: ShellConfig.barEnabled ? barPaintHeight : 0

            TopBar {
                width: parent.width
                barScreen: modelData
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: overlay
            required property var modelData
            readonly property string surface: root.openMon === modelData.name ? root.openSurface : ""
            readonly property bool middleOpen: surface.length > 0
            readonly property bool rightOpen: root.openRightMon === modelData.name && root.openRightSurface.length > 0
            readonly property bool leftOpen: root.openLeftMon === modelData.name && root.openLeftSurface.length > 0
            readonly property bool modal: middleOpen || leftOpen || rightOpen

            visible: ShellConfig.barEnabled
            screen: modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell:samaelv2:overlay"
            WlrLayershell.keyboardFocus: modal ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand

            anchors { top: true; left: true; right: true; bottom: true }

            mask: overlay.modal ? fullRegion : unionPillRegion
            Region { id: fullRegion; width: overlay.width; height: overlay.height }
            Region {
                id: middlePillRegion
                x: middlePill.x
                y: middlePill.y
                width: middlePill.width
                height: middlePill.height
            }
                Region {
                    id: leftPillRegion
                    x: leftPill.x
                    y: leftPill.y
                    width: leftPill.width
                    height: leftPill.height
                }
                Region {
                    id: rightPillRegion
                    x: rightPill.x
                    y: rightPill.y
                    width: rightPill.width
                    height: rightPill.height
                }
                Region {
                    id: unionPillRegion
                    x: Math.min(middlePillRegion.x, Math.min(leftPillRegion.x, rightPillRegion.x))
                    y: Math.min(middlePillRegion.y, Math.min(leftPillRegion.y, rightPillRegion.y))
                    width: Math.max(middlePillRegion.x + middlePillRegion.width,
                                   Math.max(leftPillRegion.x + leftPillRegion.width,
                                            rightPillRegion.x + rightPillRegion.width)) - x
                    height: Math.max(middlePillRegion.y + middlePillRegion.height,
                                    Math.max(leftPillRegion.y + leftPillRegion.height,
                                             rightPillRegion.y + rightPillRegion.height)) - y
                }

            FocusScope {
                id: focusScope
                anchors.fill: parent
                focus: overlay.modal

                    Keys.onPressed: event => {
                        if (!overlay.modal || event.key !== Qt.Key_Escape)
                            return
                        // Wallpaper picker owns Esc (field → strip → clear → close)
                        if (overlay.surface === "wallpaper" || overlay.surface === "notifications" || overlay.surface === "wifi" || overlay.surface === "bluetooth")
                            return
                        root.close()
                        event.accepted = true
                    }

                readonly property int barStripHeight: Style.barContentHeight
                        + ShellConfig.sectionBottomMargin
                        + Style.barReserveSlop
                readonly property real middleRestSlotH: Math.max(ShellActions.middleRestHeight,
                    Style.chromeBandHeight + ShellConfig.sectionBottomMargin)
                readonly property real rightRestSlotH: Math.max(ShellActions.rightRestHeight,
                    Style.chromeBandHeight + ShellConfig.sectionBottomMargin)
                readonly property real leftRestSlotH: Math.max(ShellActions.leftRestHeight,
                    Style.chromeBandHeight + ShellConfig.sectionBottomMargin)
                readonly property real middleY: {
                        if (overlay.surface === "wallpaper")
                            return ShellConfig.barMarginTop
                        return ShellConfig.barMarginTop
                            + (barStripHeight - middleRestSlotH) / 2
                    }
                    readonly property real rightY: rightPill.overviewVisible
                                ? ShellConfig.barMarginTop
                                : ShellConfig.barMarginTop + (barStripHeight - rightRestSlotH) / 2
                    readonly property real leftY: ShellConfig.barMarginTop
                            + (barStripHeight - leftRestSlotH) / 2

                    LeftPill {
                        id: leftPill
                        barScreen: modelData
                        surface: root.openLeftMon === modelData.name ? root.openLeftSurface : ""
                        x: ShellConfig.barMarginLeft
                        y: focusScope.leftY
                    }

                    MiddlePill {
                    id: middlePill
                    x: Math.max(0, (focusScope.width - width) / 2)
                    y: focusScope.middleY
                    surface: overlay.surface
                }

                RightPill {
                    id: rightPill
                    screenName: modelData.name
                    surface: root.openRightMon === modelData.name ? root.openRightSurface : ""
                    x: Math.max(0, focusScope.width - width - ShellConfig.barMarginRight)
                    y: focusScope.rightY
                }

            }

            onModalChanged: {
                if (modal)
                    focusScope.forceActiveFocus()
                else
                    focusScope.focus = false
            }
        }
    }
}