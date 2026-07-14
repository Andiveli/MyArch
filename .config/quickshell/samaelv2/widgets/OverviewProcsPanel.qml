pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../singletons"

/** Processes slide — overview cards + wifi row chrome + media typography. */
Item {
    id: root

    property int selectedColumn: 0
    property int selectedRow: 0

    RowLayout {
        id: rowLay
        anchors.fill: parent
        spacing: 8

        OverviewProcColumn {
            Layout.fillWidth: true
            Layout.fillHeight: true
            glyph: "\uf2db"
            title: qsTr("CPU")
            accentColor: WallustColors.sky
            barMuted: Qt.rgba(WallustColors.sky.r, WallustColors.sky.g, WallustColors.sky.b, 0.55)
            rows: SystemOverviewLogic.topCpuProcesses
            metricKey: "cpuPct"
            columnIndex: 0
            active: root.selectedColumn === 0
            selectedRow: root.selectedColumn === 0 ? root.selectedRow : -1
        }

        OverviewProcColumn {
            Layout.fillWidth: true
            Layout.fillHeight: true
            glyph: "\u{F0F86}"
            title: qsTr("RAM")
            accentColor: WallustColors.mauve
            barMuted: Qt.rgba(WallustColors.mauve.r, WallustColors.mauve.g, WallustColors.mauve.b, 0.65)
            rows: SystemOverviewLogic.topMemProcesses
            metricKey: "memPct"
            columnIndex: 1
            active: root.selectedColumn === 1
            selectedRow: root.selectedColumn === 1 ? root.selectedRow : -1
        }
    }
}