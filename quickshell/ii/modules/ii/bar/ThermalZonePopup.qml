import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root

    Column {
        anchors.centerIn: parent
        spacing: 8

        StyledPopupHeaderRow {
            icon: "thermostat"
            label: "CPU Temperature"
        }

        StyledPopupValueRow {
            icon: "show_chart"
            label: Translation.tr("Current:")
            value: (ThermalZone.cpuTemperature / 1000).toFixed(0) + "°C"
        }
    }
}
