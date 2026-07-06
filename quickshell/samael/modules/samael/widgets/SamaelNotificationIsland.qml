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

    readonly property bool active: Notifications.popupList.length > 0 && !GlobalStates.screenLocked
    readonly property bool anchorOk: GlobalStates.samaelIslandAnchorValid && GlobalStates.samaelIslandWidth > 0

    Loader {
        active: root.active && root.anchorOk
        sourceComponent: PanelWindow {
            readonly property string targetScreen: GlobalStates.samaelIslandScreenName
            screen: Quickshell.screens.find(s => s.name === targetScreen)
                ?? Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
                ?? null

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:samael:notificationIsland"
            WlrLayershell.layer: WlrLayer.Overlay
            exclusiveZone: 0
            color: "transparent"

            anchors.top: true
            anchors.left: true
            margins.top: GlobalStates.samaelIslandTop - 1
            margins.left: GlobalStates.samaelIslandLeft

            Item {
                id: dropRoot
                width: GlobalStates.samaelIslandWidth
                readonly property real bodyFullH: Math.max(
                    islandBody.implicitHeight
                        + SamaelStyle.modulePaddingTop
                        + SamaelStyle.modulePaddingBottom,
                    1)
                implicitHeight: stem.height + bodyFullH
                height: implicitHeight
                clip: true

                property real offsetScale: 1
                readonly property real t: Math.min(1, Math.max(0, offsetScale))

                Behavior on offsetScale {
                    NumberAnimation {
                        duration: Appearance.animation.samaelMediaAttach.duration
                        easing.type: Appearance.animation.samaelMediaAttach.type
                        easing.bezierCurve: Appearance.animation.samaelMediaAttach.bezierCurve
                    }
                }

                Component.onCompleted: Qt.callLater(() => { dropRoot.offsetScale = 0 })

                Rectangle {
                    id: stem
                    width: parent.width
                    height: 4
                    anchors.top: parent.top
                    color: SamaelStyle.menuPanelFill
                    opacity: dropRoot.t < 0.92 ? 1 : 0
                }

                Item {
                    id: bodyHost
                    width: parent.width
                    anchors.top: stem.bottom
                    anchors.topMargin: -1
                    clip: true
                    readonly property real fullH: dropRoot.bodyFullH
                    height: Math.max(0, fullH * (1 - dropRoot.t))

                    Rectangle {
                        anchors.fill: parent
                        radius: 15
                        color: SamaelStyle.menuPanelFill
                        border.width: 2
                        border.color: WallustColors.borderColor
                    }

                    Item {
                        id: bodySlot
                        width: parent.width
                        height: bodyHost.fullH
                        anchors.top: parent.top

                        SamaelIslandBody {
                            id: islandBody
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                leftMargin: SamaelStyle.moduleGroupPadH
                                rightMargin: SamaelStyle.moduleGroupPadH
                                topMargin: SamaelStyle.modulePaddingTop
                            }
                            width: parent.width - SamaelStyle.moduleGroupPadH * 2
                            lineWidth: width
                            revealProgress: 1 - dropRoot.t
                        }
                    }
                }
            }

            implicitWidth: dropRoot.width
            implicitHeight: dropRoot.implicitHeight
            mask: Region { item: dropRoot }
        }
    }
}