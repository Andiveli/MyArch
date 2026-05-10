import qs.modules.ii.bar.weather
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

/**
 * Waybar-style Bar Content
 * Replicates the Waybar configuration from objetivo/Samael
 *
 * Structure:
 * - Left: AppLauncher, SystemResources, Weather
 * - Center: Notifications, Cava, Clock, WorkspacesKanji, IdleInhibitor
 * - Right: Network, Audio, StatusButtons
 */
Item {
    id: root

    property var screen: root.QsWindow.window?.screen
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
    property real useShortenedForm: (Appearance.sizes.barHellaShortenScreenWidthThreshold >= screen?.width) ? 2 : (Appearance.sizes.barShortenScreenWidthThreshold >= screen?.width) ? 1 : 0

    // Background
    Rectangle {
        anchors {
            fill: parent
            margins: Config.options.bar.cornerStyle === 1 ? (Appearance.sizes.hyprlandGapsOut) : 0
        }
        color: "#000000"  // Negro como en Samael.css
        radius: Config.options.bar.cornerStyle === 1 ? 15 : 0
    }

    Row {
        anchors {
            fill: parent
            leftMargin: 8
            rightMargin: 8
        }
        spacing: 3

        // ============ LEFT SECTION ============
        Row {
            id: leftSection
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            // AppLauncher group (menu, browser, terminal, etc)
            AppLauncher {}

            // Separator dot-line
            Separator { separatorType: "dot-line"; implicitWidth: 6 }

            // System Resources (CPU, RAM, temp, disco)
            SystemResources {}

            // Separator blank
            Separator { separatorType: "blank"; implicitWidth: 4 }

            // Separator line
            Separator { separatorType: "line"; implicitWidth: 8 }

            // Weather
            WeatherWidget {}
        }

        // Spacer
        Item {
            width: 20
            height: 1
        }

        // ============ CENTER SECTION ============
        Row {
            id: centerSection
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            // Notifications
            NotificationsIndicator {}

            // Cava Visualizer
            CavaVisualizer {}

            // Separator dot-line
            Separator { separatorType: "dot-line"; implicitWidth: 6 }

            // Clock
            ClockWidget {}

            // Separator line
            Separator { separatorType: "line"; implicitWidth: 8 }

            // Workspaces (Kanji style)
            WorkspacesKanji {}

            // Separator dot-line
            Separator { separatorType: "dot-line"; implicitWidth: 6 }

            // Idle Inhibitor
            IdleInhibitor {}
        }

        // Spacer
        Item {
            width: 20
            height: 1
        }

        // ============ RIGHT SECTION ============
        Row {
            id: rightSection
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            layoutDirection: Qt.RightToLeft

            // Status Buttons (Power, Lock, Keyboard)
            StatusButtons {}

            // Separator dot-line
            Separator { separatorType: "dot-line"; implicitWidth: 6 }

            // Audio (Volume + Mic)
            AudioIndicator {}

            // Separator line
            Separator { separatorType: "line"; implicitWidth: 8 }

            // Network with speed
            NetworkIndicator {}

            // Tray (system tray)
            SysTray {
                visible: useShortenedForm === 0
            }
        }
    }
}
