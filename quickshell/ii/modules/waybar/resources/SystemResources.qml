import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

/**
 * System resources widget similar to Waybar's group/motherboard
 * Shows: CPU, Power Profile, Memory, Temperature, Disk
 */
RowLayout {
    id: root
    spacing: 4

    // Colores del tema Samael.css
    readonly property color colCpu: "#cba6f7"      // Mauve
    readonly property color colRam: "#ff00bf"      // Rosa/Magenta
    readonly property color colTemp: "#ff5349"     // Rojo
    readonly property color colDisk: "#89b4fa"     // Sky blue
    readonly property color colPowerProfile: "#fab387" // Peach
    readonly property color colText: "#e5d9f5"     // Texto claro

    // CPU
    ResourceItem {
        iconName: "planner_review"
        percentage: ResourceUsage.cpuUsage
        iconColor: root.colCpu
        textColor: root.colText
        showPercentage: true
    }

    // Power Profile
    Item {
        id: powerProfileItem
        implicitWidth: powerProfileLayout.implicitWidth + 8
        implicitHeight: Appearance.sizes.barHeight

        readonly property string profile: PowerProfiles.currentProfile

        RowLayout {
            id: powerProfileLayout
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            MaterialSymbol {
                text: "bolt"
                iconSize: Appearance.font.pixelSize.small
                color: root.colPowerProfile
            }

            StyledText {
                text: powerProfileItem.profile === "performance" ? "PWR" :
                      powerProfileItem.profile === "power-saver" ? "ECO" : "BAL"
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: root.colPowerProfile
            }
        }

        TapHandler {
            onTapped: {
                PowerProfiles.cycleProfile()
            }
        }
    }

    // Memory
    ResourceItem {
        iconName: "memory"
        percentage: ResourceUsage.memoryUsedPercentage
        iconColor: root.colRam
        textColor: root.colText
        showPercentage: true
    }

    // Temperature
    Item {
        id: tempItem
        implicitWidth: tempLayout.implicitWidth + 8
        implicitHeight: Appearance.sizes.barHeight

        readonly property real temperature: ThermalZone.cpuTemperature / 1000  // Convertir a grados Celsius

        RowLayout {
            id: tempLayout
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            MaterialSymbol {
                text: "thermostat"
                iconSize: Appearance.font.pixelSize.small
                color: root.colTemp
            }

            StyledText {
                text: `${Math.round(tempItem.temperature)}°`
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: root.colTemp
            }
        }

        TapHandler {
            onTapped: {
                // Show thermal info popup
            }
        }
    }

    // Disk
    Item {
        id: diskItem
        implicitWidth: diskLayout.implicitWidth + 8
        implicitHeight: Appearance.sizes.barHeight

        readonly property real diskUsage: DiskUsage.diskUsedPercentage

        RowLayout {
            id: diskLayout
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            MaterialSymbol {
                text: "hard_drive"
                iconSize: Appearance.font.pixelSize.small
                color: root.colDisk
            }

            StyledText {
                text: `${Math.round(diskItem.diskUsage * 100)}%`
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: root.colDisk
            }
        }

        TapHandler {
            onTapped: {
                // Show disk info popup
            }
        }
    }
}
