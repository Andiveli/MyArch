import QtQuick
import "../singletons"

/** One month column (header + weekday row + day grid) for calendar slide carousel. */
Item {
    id: root

    required property int panelYear
    required property int panelMonth
    required property int focusYear
    required property int focusMonth
    required property int focusDay
    required property date today

    readonly property var loc: Qt.locale()
    readonly property real s: Math.max(0.85, Style.fontPixelSize / 11)

    readonly property int offset: firstWeekdayOffset(panelYear, panelMonth)
    readonly property int monthLen: daysInMonth(panelYear, panelMonth)
    readonly property int rows: Math.ceil((offset + monthLen) / 7)
    readonly property real cellH: 24 * s
    readonly property real rowGap: 2 * s

    readonly property bool isFocusMonth: panelYear === focusYear && panelMonth === focusMonth

    width: 282 * s
    implicitHeight: header.height + divider.anchors.topMargin + divider.height
        + weekdays.anchors.topMargin + weekdays.height + 4 * s
        + rows * cellH + (rows - 1) * rowGap + 6 * s

    function firstWeekdayOffset(year, month) {
        const d = new Date(year, month, 1).getDay()
        return (d + 6) % 7
    }

    function daysInMonth(year, month) {
        return new Date(year, month + 1, 0).getDate()
    }

    function isToday(day) {
        return day === today.getDate()
            && panelMonth === today.getMonth()
            && panelYear === today.getFullYear()
    }

    function dateKey(day) {
        const m = panelMonth + 1
        const mm = m < 10 ? "0" + m : "" + m
        const dd = day < 10 ? "0" + day : "" + day
        return panelYear + "-" + mm + "-" + dd
    }

    Item {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 24 * root.s

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: loc.standaloneMonthName(root.panelMonth, Locale.LongFormat) + " " + root.panelYear
            color: WallustColors.moduleText
            opacity: 0.75
            font.family: Style.fontFamily
            font.pixelSize: 11 * root.s
            font.bold: true
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 0.8 * root.s
        }
    }

    Rectangle {
        id: divider
        anchors.top: header.bottom
        anchors.topMargin: 8 * root.s
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Qt.rgba(WallustColors.borderColor.r, WallustColors.borderColor.g, WallustColors.borderColor.b, 0.35)
    }

    Row {
        id: weekdays
        anchors.top: divider.bottom
        anchors.topMargin: 8 * root.s
        anchors.left: parent.left
        anchors.right: parent.right

        Repeater {
            model: 7
            Item {
                required property int index
                readonly property bool weekend: index >= 5
                width: weekdays.width / 7
                height: 16 * root.s
                Text {
                    anchors.centerIn: parent
                    text: loc.standaloneDayName((index + 1) % 7, Locale.NarrowFormat)
                    color: WallustColors.moduleText
                    opacity: weekend ? 0.35 : 0.5
                    font.family: Style.fontFamily
                    font.pixelSize: 9 * root.s
                }
            }
        }
    }

    Grid {
        id: grid
        y: weekdays.y + weekdays.height + 4 * root.s
        anchors.left: parent.left
        anchors.right: parent.right
        columns: 7
        rowSpacing: root.rowGap
        columnSpacing: 0

        Repeater {
            model: root.rows * 7

            Item {
                id: cell
                required property int index
                readonly property int weekday: index % 7
                readonly property bool weekend: weekday >= 5
                width: grid.width / 7
                height: root.cellH

                readonly property int dayNum: index - root.offset + 1
                readonly property bool inMonth: dayNum >= 1 && dayNum <= root.monthLen
                readonly property bool current: inMonth && root.isToday(dayNum)
                readonly property string dayKey: inMonth ? root.dateKey(dayNum) : ""
                readonly property bool hasEvent: inMonth && CalendarService.hasEvents(dayKey)
                readonly property bool focused: root.isFocusMonth && inMonth && dayNum === root.focusDay

                Rectangle {
                    anchors.centerIn: parent
                    width: 22 * root.s
                    height: 22 * root.s
                    radius: 6 * root.s
                    color: cellArea.containsMouse && cell.inMonth && !cell.focused
                        ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 24 * root.s
                    height: 24 * root.s
                    radius: 6 * root.s
                    visible: cell.current || cell.focused
                    color: cell.focused && !cell.current
                        ? Qt.alpha(WallustColors.buttonHover, 0.18)
                        : Qt.rgba(0, 0, 0, 0.25)
                    border.width: 1
                    border.color: cell.current
                        ? WallustColors.workspaceActive
                        : Qt.alpha(WallustColors.buttonHover, 0.55)
                }

                Text {
                    anchors.centerIn: parent
                    text: cell.inMonth ? cell.dayNum : ""
                    color: cell.inMonth
                        ? (cell.current ? WallustColors.workspaceActive
                            : (cell.hasEvent ? WallustColors.yellow : WallustColors.moduleText))
                        : "transparent"
                    opacity: cell.inMonth && !cell.current && !cell.hasEvent ? 0.82 : 1
                    font.family: Style.fontFamily
                    font.pixelSize: 11 * root.s
                    font.bold: cell.current || cell.hasEvent || cell.focused
                    font.features: { "tnum": 1 }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.verticalCenter
                    anchors.topMargin: 9 * root.s
                    visible: cell.hasEvent && !cell.current
                    width: 3 * root.s
                    height: 3 * root.s
                    radius: width / 2
                    color: WallustColors.yellow
                }

                MouseArea {
                    id: cellArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: cell.inMonth
                    cursorShape: cell.inMonth ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: if (cell.inMonth)
                        root.cellClicked(root.panelYear, root.panelMonth, cell.dayNum)
                }
            }
        }
    }

    signal cellClicked(int year, int month, int day)
}