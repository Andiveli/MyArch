import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    implicitWidth: rowLayout.implicitWidth + 8
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: true

    readonly property color colNormal: "#a6e3a1"
    readonly property color colWarm: "#f9e2af"
    readonly property color colHot: "#fab387"
    readonly property color colCritical: "#f38ba8"
    readonly property color colText: "#cdd6f4"

    function getTempColor() {
        switch (ThermalZone.temperatureStatus) {
            case "critical": return colCritical
            case "hot": return colHot
            case "warm": return colWarm
            default: return colNormal
        }
    }

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: 0

        Resource {
            iconName: "thermostat"
            percentage: ThermalZone.cpuTemperature / 100000
            warningThreshold: 85
            customColor: root.getTempColor()
            textColor: root.colText
        }
    }

    ThermalZonePopup {
        hoverTarget: root
    }
}
