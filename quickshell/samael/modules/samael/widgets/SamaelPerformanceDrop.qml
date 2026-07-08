import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.samael
import qs.modules.samael.widgets

Scope {
    id: root

    readonly property int dropPanelWidth: 840

    Loader {
        id: perfLoader
        active: (GlobalStates.samaelPerformanceDropOpen || GlobalStates.samaelPerformanceClosing)
        && (!SamaelCenterSurface.effectiveSurface
        || SamaelCenterSurface.effectiveSurface === "idle"
        || SamaelCenterSurface.effectiveSurface !== "performance")
        sourceComponent: PanelWindow {
            id: perfPanelRoot
            readonly property string targetScreen: GlobalStates.samaelPerformanceScreenName
            readonly property var targetScreenObj: Quickshell.screens.find(s => s.name === targetScreen)
                ?? Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
                ?? Quickshell.screens[0]

            screen: targetScreenObj

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:samael:performanceDrop"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: GlobalStates.samaelPerformanceDropOpen
                ? WlrKeyboardFocus.OnDemand
                : WlrKeyboardFocus.None
            exclusiveZone: 0
            color: "transparent"

            anchors.top: true
            anchors.left: true
            margins.top: GlobalStates.samaelPerformanceDockTop > 0
                ? GlobalStates.samaelPerformanceDockTop
                : (Appearance?.sizes?.barHeight ?? 36) + 8
            property real pinnedCenterX: -1

            margins.left: {
                const sw = targetScreenObj?.width ?? 1920
                const cx = pinnedCenterX > 0
                    ? pinnedCenterX
                    : (GlobalStates.samaelPerformanceCenterX > 0
                        ? GlobalStates.samaelPerformanceCenterX
                        : sw / 2)
                return Math.max(8, Math.min(sw - root.dropPanelWidth - 8, cx - root.dropPanelWidth / 2))
            }

            readonly property color panelFill: SamaelStyle.menuPanelFill

            Item {
                id: dropRoot
                width: root.dropPanelWidth
                readonly property real bodyFullH: bodySlot.implicitHeight
                implicitHeight: bodyFullH
                height: implicitHeight

                property real offsetScale: 1
                readonly property real t: Math.min(1, Math.max(0, offsetScale))
                readonly property real labelOpacity: t > 0.55 ? 0 : Math.min(1, (0.55 - t) / 0.55)

                clip: true

                Behavior on offsetScale {
                    NumberAnimation {
                        duration: Appearance.animation.samaelMediaAttach.duration
                        easing.type: Appearance.animation.samaelMediaAttach.type
                        easing.bezierCurve: Appearance.animation.samaelMediaAttach.bezierCurve
                    }
                }

                Item {
                    id: bodyHost
                    width: parent.width
                    anchors.top: parent.top
                    clip: true
                    readonly property real fullH: dropRoot.bodyFullH
                    readonly property int bw: 2
                    readonly property int bodyR: 15
                    height: Math.max(0, fullH * (1 - dropRoot.t))

                    Rectangle {
                        anchors.fill: parent
                        color: panelFill
                        border.width: bodyHost.bw
                        border.color: WallustColors.borderColor
                        topLeftRadius: 0
                        topRightRadius: 0
                        bottomLeftRadius: bodyHost.bodyR
                        bottomRightRadius: bodyHost.bodyR
                    }

                    Item {
                        id: bodySlot
                        width: parent.width
                        implicitHeight: dropBody.implicitHeight
                        height: implicitHeight
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        anchors.topMargin: 8
                        anchors.bottomMargin: 10
                        opacity: dropRoot.labelOpacity

                        SamaelPerformanceDropBody {
                            id: dropBody
                            width: parent.width
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }

            implicitWidth: dropRoot.width
            implicitHeight: dropRoot.implicitHeight
            mask: Region { item: dropRoot }

            Component.onCompleted: Qt.callLater(() => { dropRoot.offsetScale = 0 })

            Connections {
                target: dropRoot
                function onOffsetScaleChanged() {
                        if (GlobalStates.samaelPerformanceDropOpen && dropRoot.offsetScale < 0.02)
                            Qt.callLater(() => dropBody.focusActiveTab())
                    if (GlobalStates.samaelPerformanceClosing && dropRoot.offsetScale >= 0.999) {
                        GlobalStates.samaelPerformanceClosing = false
                        Hyprland.dispatch("focuscurrent")
                    }
                }
            }

            Connections {
                target: GlobalStates
                function onSamaelPerformanceDropOpenChanged() {
                    if (GlobalStates.samaelPerformanceDropOpen) {
                        GlobalStates.samaelPerformanceClosing = false
                        perfPanelRoot.pinnedCenterX = GlobalStates.samaelPerformanceCenterX > 0
                            ? GlobalStates.samaelPerformanceCenterX
                            : ((targetScreenObj?.width ?? 1920) / 2)
                        GlobalFocusGrab.addDismissable(perfPanelRoot)
                        dropRoot.offsetScale = 0
                    } else if (!GlobalStates.samaelPerformanceClosing) {
                        perfPanelRoot.pinnedCenterX = -1
                        GlobalStates.samaelPerformanceClosing = true
                        dropBody.focus = false
                        dropBody.dropTabIndex = 0
                        GlobalFocusGrab.removeDismissable(perfPanelRoot)
                        dropRoot.offsetScale = 1
                    }
                }
            }

            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    if (GlobalStates.samaelPerformanceDropOpen)
                        GlobalStates.samaelPerformanceDropOpen = false
                }
            }
        }
    }
}