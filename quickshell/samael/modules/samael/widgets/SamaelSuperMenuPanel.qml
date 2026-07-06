import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.modules.common
import qs.modules.samael.widgets

Scope {
    Loader {
        id: superLoader
        active: GlobalStates.samaelSuperMenuOpen
        sourceComponent: PanelWindow {
            id: win
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
                ?? Quickshell.screens[0]

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:samael:superMenu"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: Qt.rgba(0, 0, 0, 0.42)

            anchors {
                top: true
                left: true
                right: true
            }
            implicitWidth: screen?.width ?? 1920
            implicitHeight: screen?.height ?? 1080

            Component.onCompleted: GlobalFocusGrab.addDismissable(win)
            Component.onDestruction: GlobalFocusGrab.removeDismissable(win)
            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    GlobalStates.samaelSuperMenuOpen = false
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: GlobalStates.samaelSuperMenuOpen = false
            }

            SamaelSuperMenu {
                id: menu
                anchors.centerIn: parent
                onVisibleChanged: if (visible) forceActiveFocus()
            }

            Connections {
                target: GlobalStates
                function onSamaelSuperMenuOpenChanged() {
                    if (GlobalStates.samaelSuperMenuOpen)
                        Qt.callLater(() => menu.forceActiveFocus())
                }
            }
        }
    }
}