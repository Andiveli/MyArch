import QtQuick
import QtQuick.Layouts
import qs.modules.samael

Item {
    id: root
    required property int year
    required property int monthIndex
    required property var refDate
    /** Width available inside the month card (keeps 7 columns inside the tile). */
    property real layoutWidth: 7 * 22 + 6 * 2

    readonly property int cellW: Math.max(14, Math.floor((layoutWidth - 6 * 2) / 7))
    readonly property int cellH: Math.max(16, Math.round(cellW * 0.78))
    readonly property int firstDow: (new Date(year, monthIndex, 1).getDay() + 6) % 7
    readonly property int daysInMonth: new Date(year, monthIndex + 1, 0).getDate()
    readonly property bool isCurrentMonth: refDate.getFullYear() === year
        && refDate.getMonth() === monthIndex
    readonly property int todayDay: isCurrentMonth ? refDate.getDate() : -1

    readonly property var weekdayLabels: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    width: layoutWidth
    implicitWidth: layoutWidth
    implicitHeight: grid.implicitHeight
    clip: true

    GridLayout {
        id: grid
        width: root.layoutWidth
        columns: 7
        columnSpacing: 2
        rowSpacing: 2

        Repeater {
            model: 7
            delegate: Text {
                required property int index
                Layout.preferredWidth: root.cellW
                Layout.preferredHeight: root.cellH
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: root.weekdayLabels[index]
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: Math.max(9, SamaelStyle.fontPixelSize - 2)
                color: WallustColors.buttonHover
            }
        }

        Repeater {
            model: root.firstDow + root.daysInMonth
            delegate: Item {
                required property int index
                Layout.preferredWidth: root.cellW
                Layout.preferredHeight: root.cellH

                readonly property int dayNum: index - root.firstDow + 1
                readonly property bool isDay: index >= root.firstDow
                readonly property bool isToday: isDay && dayNum === root.todayDay

                Rectangle {
                    visible: parent.isDay
                    anchors.centerIn: parent
                    width: root.cellW - 2
                    height: root.cellH - 2
                    radius: 4
                    color: parent.isToday
                        ? WallustColors.workspaceActive
                        : "transparent"
                    opacity: parent.isToday ? 0.35 : 0
                }

                Text {
                    visible: parent.isDay
                    anchors.centerIn: parent
                    width: root.cellW
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: parent.dayNum
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Math.max(10, SamaelStyle.fontPixelSize)
                    font.bold: parent.isToday
                    color: parent.isToday
                        ? WallustColors.moduleText
                        : WallustColors.sapphire
                }
            }
        }
    }
}