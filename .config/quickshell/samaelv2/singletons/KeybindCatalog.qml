pragma Singleton

import QtQuick
import Quickshell

/**
 * Read-only keybind reference. Hypr apps/tools/surfaces-open match
 * ~/.config/hypr/hyprland/keybinds.lua (maintain by hand until parser exists).
 * In-surface keys come from samaelv2 QML surfaces.
 */
Singleton {
    id: root

    readonly property var appEntries: [
        { keys: "Super (release)", action: "samaelv2 launcher" },
        { keys: "Super + Return", action: "Ghostty terminal" },
        { keys: "Super + E", action: "Microsoft Edge" },
        { keys: "Super + Z", action: "Zen browser" },
        { keys: "Super + A", action: "Dolphin" },
        { keys: "Super + S", action: "Spotify" },
        { keys: "Super + D", action: "Discord" },
        { keys: "Super + T", action: "TablePlus" },
        { keys: "Alt + Space", action: "puerta.sh launcher" }
    ]

    /** Hypr → open samaelv2 pill (drillId = inside section id). */
    readonly property var surfaceOpenRows: [
        { keys: "Super (release)", action: "Launcher", drillId: "surface_launcher" },
        { keys: "Super + Ctrl + R", action: "Screen record (left pill)", drillId: "surface_record" },
        { keys: "Super + W", action: "Wallpaper picker", drillId: "surface_wallpaper" },
        { keys: "Super + Shift + N", action: "Notifications", drillId: "surface_notifications" },
        { keys: "Super + Shift + W", action: "Wi‑Fi", drillId: "surface_wifi" },
        { keys: "Super + Shift + B", action: "Bluetooth", drillId: "surface_bluetooth" },
        { keys: "Super + Shift + A", action: "Usage / CodexBar", drillId: "surface_usage" },
        { keys: "Super + Shift + D", action: "Calendar", drillId: "surface_calendar" },
        { keys: "Super + Ctrl + S", action: "Settings", drillId: "surface_settings" },
        { keys: "Super + M", action: "Media", drillId: "surface_media" },
        { keys: "Super + Shift + O", action: "System overview (right)", drillId: "surface_overview" },
        { keys: "Super + Shift + P", action: "Power menu (right)", drillId: "surface_power" }
    ]

    readonly property var toolEntries: [
        { keys: "Ctrl + Alt + L", action: "Lock screen (samaelv2)" },
        { keys: "Super + Shift + S", action: "Screenshot (swappy)" },
        { keys: "Super + Print", action: "Screenshot now" },
        { keys: "Super + N", action: "Toggle night light (Hyprsunset)" },
        { keys: "Ctrl + Alt + W", action: "Random wallpaper (Quickshell)" },
        { keys: "Super + Ctrl + B", action: "Bar keyboard nav submap (then h/l/j/k · Esc)" },
        { keys: "Super + Shift + M", action: "Samael super menu" },
        { keys: "Super + Alt + R", action: "Refresh bar / menus" },
        { keys: "XF86Audio* / brightness", action: "Volume / brightness scripts → OSD IPC" },
        { keys: "Bar click", action: "Widgets toggle matching surface (Wi‑Fi, media, overview, …)" },
        { keys: "Bar · notifications · Left click", action: "Dismiss latest toast, or open notifications menu" },
        { keys: "Bar · notifications · Right click", action: "Toggle do-not-disturb (hides toasts; badge off)" }
    ]

    function insideEntries(drillId) {
        const map = {
        "surface_record": [
            { keys: "h / l", action: "Controls row: left/right · Mic/system row: volume ±5%" },
            { keys: "Space", action: "Toggle mute (mic or system row)" },
            { keys: "j / k", action: "Next / previous row (controls, mic, system)" },
            { keys: "Enter", action: "Activate (Enter on volume bar: adjust with h/l)" },
            { keys: "Esc", action: "Leave config panel, then close surface" },
            { keys: "Bar · record icon", action: "Open record surface (left)" }
        ],
        "surface_launcher": [
            { keys: "/", action: "Focus search" },
            { keys: "j / k", action: "Move selection" },
            { keys: "Enter", action: "Open app / file / run command" },
            { keys: "Esc", action: "Clear search focus, then close" }
        ],
        "surface_media": [
            { keys: "Space", action: "Play / pause" },
            { keys: "h / l", action: "Previous / next track" },
            { keys: "j / k", action: "Seek ±10s (or lyric line when lyrics open)" },
            { keys: "Tab / Shift+Tab", action: "Cycle MPRIS player" },
            { keys: "s", action: "Toggle shuffle" },
            { keys: "r", action: "Cycle repeat" },
            { keys: "y / Shift+L", action: "Toggle lyrics column" },
            { keys: "Esc", action: "Close surface" }
        ],
        "surface_notifications": [
            { keys: "j / k", action: "Next / previous group (collapsed) or item (expanded)" },
            { keys: "h", action: "Collapse expanded group, or previous group" },
            { keys: "l / Enter / o", action: "Expand group, or activate focused notification" },
            { keys: "x", action: "Dismiss focused notification (expanded, 2+ in group) or whole group otherwise" },
            { keys: "Shift+X", action: "Dismiss entire group at focus" },
            { keys: "d", action: "Dismiss all tracked notifications" },
            { keys: "Esc", action: "Close notifications menu" }
        ],
        "surface_wifi": [
            { keys: "j / k", action: "Move network row" },
            { keys: "l / Enter", action: "Connect / expand" },
            { keys: "r", action: "Start / stop scan" },
            { keys: "t", action: "Toggle Wi‑Fi radio" },
            { keys: "d", action: "Disconnect active" },
            { keys: "/", action: "Hidden network" },
            { keys: "Esc", action: "Leave sub-mode, then close" }
        ],
        "surface_bluetooth": [
            { keys: "j / k", action: "Move device row" },
            { keys: "l / Enter / o", action: "Pair / connect action" },
            { keys: "r", action: "Toggle scan" },
            { keys: "t", action: "Toggle Bluetooth radio" },
            { keys: "d", action: "Disconnect active" },
            { keys: "f", action: "Forget paired device" },
            { keys: "a", action: "Route audio to device" },
            { keys: "Esc", action: "Leave confirm, then close" }
        ],
        "surface_usage": [
            { keys: "Tab / Shift+Tab", action: "Next / previous provider" },
            { keys: "j / k", action: "Next / previous provider" },
            { keys: "r", action: "Refresh" },
            { keys: "Esc", action: "Close surface" }
        ],
        "surface_calendar": [
            { keys: "Tab / Shift+Tab", action: "Next / previous month" },
            { keys: "h / l", action: "Previous / next day" },
            { keys: "j / k", action: "Previous / next week" },
            { keys: "Enter", action: "Open day agenda" },
            { keys: "r", action: "Refresh feeds" },
            { keys: "s", action: "Feed settings (calendar-secrets)" },
            { keys: "Esc", action: "Back through views, then close" }
        ],
        "surface_settings": [
            { keys: "j / k", action: "Nav pages or content rows" },
            { keys: "h / l / Enter", action: "Nav ↔ content; drill keybinds with l/Enter" },
            { keys: "Tab", action: "Switch nav / content" },
            { keys: "s", action: "Save config.json" },
            { keys: "Shift+h", action: "Stepper decrease (content)" },
            { keys: "Esc", action: "Close surface" }
        ],
        "surface_wallpaper": [
            { keys: "h / l", action: "Previous / next image" },
            { keys: "Enter", action: "Apply wallpaper" },
            { keys: "Esc", action: "Field → strip → clear → close" }
        ],
        "surface_overview": [
            { keys: "Esc", action: "Close surface" }
        ],
        "surface_power": [
            { keys: "j / k", action: "Move selection" },
            { keys: "Enter", action: "Confirm action" },
            { keys: "Esc", action: "Close menu" }
        ]
        }
        return map[drillId] || []
    }

    function insideTitle(drillId) {
        for (let i = 0; i < surfaceOpenRows.length; i++) {
            if (surfaceOpenRows[i].drillId === drillId)
                return surfaceOpenRows[i].action
        }
        return "Inside"
    }
}