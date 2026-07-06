import QtQuick
import qs.modules.samael

Rectangle {
    color: "transparent"
    implicitWidth: 480
    implicitHeight: 280

    readonly property var monthNames: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    property int viewYear: new Date().getFullYear()
    property int viewMonth: new Date().getMonth()

    function daysInMonth(y, m) {
        return new Date(y, m + 1, 0).getDate()
    }

    function firstWeekday(y, m) {
        return new Date(y, m, 1).getDay()
    }

    Column {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6
        Text {
            text: monthNames[viewMonth] + " " + viewYear
            font.family: SamaelStyle.fontFamily
            font.pixelSize: 11
            font.bold: true
            color: "#1a8cff"
        }
        Grid {
            columns: 7
            spacing: 2
            Repeater {
                model: 42
                delegate: Text {
                    required property int index
                    property int dayNum: {
                        const start = root.firstWeekday(root.viewYear, root.viewMonth)
                        const dim = root.daysInMonth(root.viewYear, root.viewMonth)
                        const d = index - start + 1
                        return (d >= 1 && d <= dim) ? d : 0
                    }
                    property bool isToday: {
                        const t = new Date()
                        return dayNum > 0 && t.getDate() === dayNum && t.getMonth() === root.viewMonth && t.getFullYear() === root.viewYear
                    }
                    width: 32
                    height: 22
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: dayNum > 0 ? String(dayNum) : ""
                    font.family: SamaelStyle.fontFamily
                    font.pixelSize: 9
                    color: isToday ? "#1a8cff" : SamaelStyle.textColor
                    font.bold: isToday
                }
            }
        }
    }
}