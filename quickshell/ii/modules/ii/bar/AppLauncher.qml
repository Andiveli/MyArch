import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

/**
 * App Launcher group - Waybar style
 * Includes: Menu, Theme Toggle, File Manager, Terminal, Browser, Settings
 */
RowLayout {
    id: root
    spacing: 2

    readonly property color colMenu: "#f9e2af"     // Yellow
    readonly property color colTheme: "#fab387"    // Peach
    readonly property color colFile: "#89b4fa"     // Blue
    readonly property color colTerm: "#94e2d5"     // Teal
    readonly property color colBrowser: "#f38ba8"  // Red
    readonly property color colSettings: "#cba6f7" // Mauve
    readonly property color colText: "#e5d9f5"

    // Menu / App Drawer
    AppLauncherButton {
        iconName: "apps"
        iconColor: root.colMenu
        onClicked: {
            Quickshell.execDetached(["bash", "-c", "pkill rofi || rofi -show drun -modi run,drun,filebrowser,window"])
        }
    }

    // Theme Toggle (Light/Dark)
    AppLauncherButton {
        iconName: "light_mode"
        iconColor: root.colTheme
        onClicked: {
            Quickshell.execDetached(["bash", "-c", "$HOME/.config/hypr/scripts/DarkLight.sh"])
        }
    }

    // File Manager
    AppLauncherButton {
        iconName: "folder"
        iconColor: root.colFile
        onClicked: {
            Quickshell.execDetached(["thunar"])
        }
    }

    // Terminal
    AppLauncherButton {
        iconName: "terminal"
        iconColor: root.colTerm
        onClicked: {
            Quickshell.execDetached(["kitty"])
        }
    }

    // Browser
    AppLauncherButton {
        iconName: "public"
        iconColor: root.colBrowser
        onClicked: {
            Quickshell.execDetached(["firefox"])
        }
    }

    // Settings
    AppLauncherButton {
        iconName: "settings"
        iconColor: root.colSettings
        onClicked: {
            Quickshell.execDetached(["bash", "-c", "$HOME/.config/hypr/scripts/Kool_Quick_Settings.sh"])
        }
    }
}
