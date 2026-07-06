import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.samael

Rectangle {
    id: root
    color: "transparent"
    implicitWidth: 480
    implicitHeight: 200

    readonly property var monitor: Brightness.getMonitorForScreen(
        Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0])

    function handleKey(event): bool {
        if (!monitor?.ready)
            return false
        const step = 0.05
        if (event.key === Qt.Key_H || event.key === Qt.Key_Left) {
            monitor.setBrightness(Math.max(0, monitor.brightness - step))
            event.accepted = true
            return true
        }
        if (event.key === Qt.Key_L || event.key === Qt.Key_Right) {
            monitor.setBrightness(Math.min(1, monitor.brightness + step))
            event.accepted = true
            return true
        }
        return false
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Text {
            text: "DISPLAY"
            font.family: SamaelStyle.fontFamily
            font.pixelSize: 11
            font.bold: true
            color: "#1a8cff"
        }

        Text {
            text: monitor?.ready ? `Brightness ${Math.round(monitor.brightness * 100)}%` : "brightnessctl unavailable"
            font.family: SamaelStyle.fontFamily
            font.pixelSize: 10
            color: SamaelStyle.textColor
        }

        Slider {
            Layout.fillWidth: true
            visible: monitor?.ready ?? false
            from: 0
            to: 1
            stepSize: 0.01
            value: monitor?.brightness ?? 0
            onMoved: {
                if (monitor)
                    monitor.setBrightness(value)
            }
        }

        Text {
            text: "h/l adjust brightness"
            font.family: SamaelStyle.fontFamily
            font.pixelSize: 8
            color: "#475569"
        }
    }
}