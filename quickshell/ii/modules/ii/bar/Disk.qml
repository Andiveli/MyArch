import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    implicitWidth: rowLayout.implicitWidth + rowLayout.anchors.leftMargin + rowLayout.anchors.rightMargin
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    // Color Catppuccin Sky
    readonly property color colDisk: "#74c7ec"
    readonly property color colText: "#cdd6f4"

    RowLayout {
        id: rowLayout

        spacing: 0
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4

        Resource {
            iconName: "storage"
            percentage: DiskUsage.diskUsedPercentage
            warningThreshold: Config.options.bar.resources.diskWarningThreshold ?? 0.9
            customColor: root.colDisk
            textColor: root.colText
        }
    }

    DiskPopup {
        hoverTarget: root
    }
}
