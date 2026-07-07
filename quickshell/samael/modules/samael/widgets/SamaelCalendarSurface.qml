import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common
import qs.modules.samael

SamaelPillSurface {
    id: surface

    mTop: 0
    mLeft: 0
    mRight: 0
    mBottom: 0

    readonly property var todayRef: new Date()
    readonly property int calendarYear: todayRef.getFullYear()

    onRequestClose: GlobalStates.samaelClockDropOpen = false

    QtObject {
        id: monthAscii
        function monthTitle(year, monthIndex) {
            return Qt.formatDateTime(new Date(year, monthIndex, 1), "MMMM")
        }
    }

    implicitWidth: 300
    implicitHeight: 360

    Item {
        id: bodySlot
        anchors.fill: parent
        anchors.margins: 10

        Column {
            id: headerRow
            width: parent.width
            spacing: 4

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "📅 " + surface.calendarYear
                color: WallustColors.moduleText
                font.family: SamaelStyle.fontFamily
                font.pixelSize: SamaelStyle.fontPixelSize + 2
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDateTime(surface.todayRef, "dddd, d MMMM")
                color: WallustColors.sapphire
                font.family: SamaelStyle.fontFamily
                font.pixelSize: SamaelStyle.fontPixelSize
            }
        }

        Flickable {
            id: flick
            anchors.top: headerRow.bottom
            anchors.topMargin: 8
            width: parent.width
            height: parent.height - headerRow.height - 8
            clip: true
            contentWidth: width
            contentHeight: monthGrid.implicitHeight + 16
            boundsBehavior: Flickable.StopAtBounds

            GridLayout {
                id: monthGrid
                width: flick.width
                columns: 4
                columnSpacing: 22
                rowSpacing: 26
                readonly property int tileMargin: 10
                readonly property real tileWidth: Math.floor(
                    (width - columnSpacing * (columns - 1)
                        - tileMargin * 2 * columns) / columns)

                Repeater {
                    model: 12
                    delegate: Rectangle {
                        required property int index
                        Layout.preferredWidth: monthGrid.tileWidth
                        Layout.maximumWidth: monthGrid.tileWidth
                        Layout.margins: 10
                        implicitHeight: monthCol.implicitHeight + 20
                        radius: 8
                        clip: true
                        color: Qt.rgba(0, 0, 0, index === surface.todayRef.getMonth() ? 0.28 : 0.14)
                        border.width: index === surface.todayRef.getMonth() ? 1 : 0
                        border.color: WallustColors.workspaceActive

                        Column {
                            id: monthCol
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: 8
                            spacing: 4
                            width: parent.width - 8

                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: monthAscii.monthTitle(surface.calendarYear, index)
                                color: WallustColors.moduleText
                                font.family: SamaelStyle.fontFamily
                                font.pixelSize: SamaelStyle.fontPixelSize
                                font.bold: index === surface.todayRef.getMonth()
                            }

                            MonthMiniCalendar {
                                anchors.horizontalCenter: parent.horizontalCenter
                                layoutWidth: monthCol.width
                                year: surface.calendarYear
                                monthIndex: index
                                refDate: surface.todayRef
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Keyboard API ──
    function moveH(dir) {
        // Scroll horizontally in the flickable
        flick.contentX = Math.max(0, Math.min(flick.contentWidth - flick.width, flick.contentX + dir * 100))
    }

    function moveV(dir) {
        // Scroll vertically in the flickable
        flick.contentY = Math.max(0, Math.min(flick.contentHeight - flick.height, flick.contentY + dir * 100))
    }

    function activate() {
        // No actionable items currently — reserved
    }

    function back() {
        return false // surface should close
    }
}
