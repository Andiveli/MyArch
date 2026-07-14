pragma Singleton

import QtQuick
import Quickshell

/** Suspend / poweroff / logout / lock — same commands as quickshell/samael Session. */
QtObject {
    function lock() {
        Quickshell.execDetached(["qs", "-c", "samaelv2", "ipc", "call", "lock", "lock"])
    }

    function suspend() {
        Quickshell.execDetached(["bash", "-c", "systemctl suspend || loginctl suspend"])
    }

    function logout() {
        Quickshell.execDetached(["bash", "-c", "pkill -i Hyprland || loginctl terminate-user \"$USER\""])
    }

    function poweroff() {
        Quickshell.execDetached(["bash", "-c", "systemctl poweroff || loginctl poweroff"])
    }
}