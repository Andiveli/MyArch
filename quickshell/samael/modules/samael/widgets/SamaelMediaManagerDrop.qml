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

    /** Match SamaelMediaManager compact effectiveDropWidth (~728) */
    readonly property int dropPanelWidth: 728

    Loader {
        id: mediaLoader
        active: (GlobalStates.mediaControlsOpen || GlobalStates.samaelMediaClosing)
        && (!SamaelCenterSurface.effectiveSurface
        || SamaelCenterSurface.effectiveSurface === "idle"
        || SamaelCenterSurface.effectiveSurface !== "media")
        sourceComponent: PanelWindow {
            id: mediaPanelRoot
            readonly property string targetScreen: GlobalStates.samaelMediaScreenName
            readonly property var targetScreenObj: Quickshell.screens.find(s => s.name === targetScreen)
                ?? Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
                ?? Quickshell.screens[0]

            screen: targetScreenObj

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:samael:mediaManager"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: GlobalStates.mediaControlsOpen
                ? WlrKeyboardFocus.OnDemand
                : WlrKeyboardFocus.None
            exclusiveZone: 0
            color: "transparent"

            anchors.top: true
            anchors.left: true
            margins.top: GlobalStates.samaelMediaDockTop > 0
                ? GlobalStates.samaelMediaDockTop
                : (Appearance?.sizes?.barHeight ?? 36) + 8
                property real pinnedCenterX: -1

                margins.left: {
                    const sw = targetScreenObj?.width ?? 1920
                    const cx = pinnedCenterX > 0
                        ? pinnedCenterX
                        : (GlobalStates.samaelMediaCenterX > 0
                            ? GlobalStates.samaelMediaCenterX
                            : sw / 2)
                    return Math.max(8, Math.min(sw - root.dropPanelWidth - 8, cx - root.dropPanelWidth / 2))
                }

            readonly property color panelFill: SamaelStyle.menuPanelFill

            Item {
                id: dropRoot
                width: root.dropPanelWidth
                readonly property real bodyFullH: mediaBodySlot.implicitHeight
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
                        id: mediaBodySlot
                        width: parent.width
                        implicitHeight: mediaManager.implicitHeight
                        height: implicitHeight
                        anchors.top: parent.top
                        opacity: dropRoot.labelOpacity

                        SamaelMediaManager {
                            id: mediaManager
                            width: root.dropPanelWidth
                            anchors.horizontalCenter: parent.horizontalCenter
                            embeddedInBar: true
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
                    if (GlobalStates.mediaControlsOpen && dropRoot.offsetScale < 0.02)
                        Qt.callLater(() => mediaManager.forceActiveFocus())
                    if (GlobalStates.samaelMediaClosing && dropRoot.offsetScale >= 0.999) {
                        GlobalStates.samaelMediaClosing = false
                        Hyprland.dispatch("focuscurrent")
                    }
                }
            }

            Connections {
                target: GlobalStates
                    function onMediaControlsOpenChanged() {
                        if (GlobalStates.mediaControlsOpen) {
                            GlobalStates.samaelMediaClosing = false
                            mediaPanelRoot.pinnedCenterX = GlobalStates.samaelMediaCenterX > 0
                                ? GlobalStates.samaelMediaCenterX
                                : ((targetScreenObj?.width ?? 1920) / 2)
                            GlobalFocusGrab.addDismissable(mediaPanelRoot)
                            dropRoot.offsetScale = 0
                        } else if (!GlobalStates.samaelMediaClosing) {
                            mediaPanelRoot.pinnedCenterX = -1
                        GlobalStates.samaelMediaClosing = true
                        mediaManager.focus = false
                        GlobalFocusGrab.removeDismissable(mediaPanelRoot)
                        dropRoot.offsetScale = 1
                    }
                }
            }

            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    if (GlobalStates.mediaControlsOpen)
                        GlobalStates.mediaControlsOpen = false
                }
            }
        }
    }
}
