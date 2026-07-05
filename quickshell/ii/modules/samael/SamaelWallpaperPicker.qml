import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.samael

Scope {
    id: root

    readonly property string randomCmd: [
        "d=\"/home/samael/Pictures/wallpapers\"",
        "mapfile -t a < <(find -L \"$d\" -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) )",
        "[[ ${#a[@]} -gt 0 ]] && bash /home/samael/.config/quickshell/ii/scripts/wallpaper/samael-wallpaper.sh \"${a[$RANDOM % ${#a[@]}]}\""
    ].join("; ")

    function toggle() {
        const opening = !GlobalStates.wallpaperSelectorOpen
        if (opening) {
        GlobalStates.samaelSuperMenuOpen = false
        GlobalStates.samaelSystemSidebarOpen = false
        }
        GlobalStates.wallpaperSelectorOpen = opening
    }

    function runRandom() {
        randomProc.exec(["bash", "-c", randomCmd])
    }

    Process {
        id: randomProc
    }

    Loader {
        active: GlobalStates.wallpaperSelectorOpen

        sourceComponent: PanelWindow {
            id: panelWindow
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:samael:wallpaperPicker"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"

            anchors.top: true
            margins.top: Appearance.sizes.barHeight + Appearance.sizes.hyprlandGapsOut + 8

            implicitWidth: pickerContent.implicitWidth
            implicitHeight: pickerContent.implicitHeight

            mask: Region { item: pickerContent }

            Component.onCompleted: GlobalFocusGrab.addDismissable(panelWindow)
            Component.onDestruction: GlobalFocusGrab.removeDismissable(panelWindow)

            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    GlobalStates.wallpaperSelectorOpen = false
                }
            }

            SamaelWallpaperPickerContent {
                id: pickerContent
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    IpcHandler {
        target: "wallpaperSelector"

        function toggle(): void {
            root.toggle()
        }

        function random(): void {
            root.runRandom()
        }
    }

    GlobalShortcut {
        name: "wallpaperSelectorToggle"
        description: "Samael wallpaper grid"
        onPressed: root.toggle()
    }

    GlobalShortcut {
        name: "wallpaperSelectorRandom"
        description: "Samael random wallpaper"
        onPressed: root.runRandom()
    }
}