import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool alwaysShowAllResources: false
    implicitWidth: rowLayout.implicitWidth + rowLayout.anchors.leftMargin + rowLayout.anchors.rightMargin
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    // Colores Catppuccin Mo塘 (tema oscuro del usuario)
    readonly property color colRam: "#ff00bf"       // Rosa/magenta
    readonly property color colCpu: "#cba6f7"       // Mauve
    readonly property color colText: "#cdd6f4"      // Text (base)

    RowLayout {
        id: rowLayout

        spacing: 0
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4

        // CPU primero
        Resource {
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
            shown: Config.options.bar.resources.alwaysShowCpu ||
                !(MprisController.activePlayer?.trackTitle?.length > 0) ||
                root.alwaysShowAllResources
            warningThreshold: Config.options.bar.resources.cpuWarningThreshold
            customColor: root.colCpu
            textColor: root.colText
        }

        // RAM segundo
        Resource {
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            warningThreshold: Config.options.bar.resources.memoryWarningThreshold
            customColor: root.colRam
            textColor: root.colText
        }

    }

    ResourcesPopup {
        hoverTarget: root
    }
}
