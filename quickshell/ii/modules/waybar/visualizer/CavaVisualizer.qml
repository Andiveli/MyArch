import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

/**
 * CAVA-like audio visualizer - Waybar style
 * Shows a simple bar visualization based on audio levels
 */
Item {
    id: root
    implicitWidth: 60
    implicitHeight: Appearance.sizes.barHeight

    readonly property color colVisualizer: "#a6e3a1"  // Green
    readonly property int barCount: 8

    property double audioLevel: MprisController.activePlayer?.volume ?? 0

    // Simulated visualizer bars
    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Repeater {
            model: root.barCount

            delegate: Rectangle {
                id: bar
                width: 4
                height: {
                    // Generate pseudo-random but deterministic height based on index and audio level
                    const base = Math.sin((index + 1) * 1.5) * 0.3 + 0.5
                    const variation = Math.sin(Date.now() / 500 + index) * 0.2
                    const level = (root.audioLevel + 0.2) * (base + variation)
                    return 8 + (level * 12)
                }
                radius: 1
                color: root.colVisualizer

                Timer {
                    running: true
                    interval: 100
                    repeat: true
                    onTriggered: {
                        // Update height for animation effect
                        const base = Math.sin((index + 1) * 1.5) * 0.3 + 0.5
                        const variation = Math.sin(Date.now() / (200 + index * 50) + index * 10) * 0.3
                        const level = (root.audioLevel + 0.3) * (base + variation)
                        bar.height = 6 + Math.max(0, level * 16)
                    }
                }
            }
        }
    }
}
