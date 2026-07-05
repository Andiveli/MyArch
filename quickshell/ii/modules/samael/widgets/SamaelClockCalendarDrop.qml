import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.modules.common
import qs.modules.samael
import qs.modules.samael.widgets

Scope {
    id: root

    readonly property int dropPanelWidth: 920

    Loader {
        id: calLoader
        active: GlobalStates.samaelClockDropOpen
        sourceComponent: PanelWindow {
            readonly property string targetScreen: GlobalStates.samaelClockScreenName
            readonly property var targetScreenObj: Quickshell.screens.find(s => s.name === targetScreen)
                ?? Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
                ?? Quickshell.screens[0]

            screen: targetScreenObj

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:samael:clockCalendar"
            WlrLayershell.layer: WlrLayer.Overlay
            exclusiveZone: 0
            color: "transparent"

            anchors.top: true
            anchors.left: true
            margins.top: GlobalStates.samaelClockDropTop > 0
                ? GlobalStates.samaelClockDropTop
                : (Appearance?.sizes?.barHeight ?? 36) + 8
            margins.left: {
                const sw = targetScreenObj?.width ?? 1920
                const cx = GlobalStates.samaelClockDropCenterX > 0
                    ? GlobalStates.samaelClockDropCenterX
                    : sw / 2
                return Math.max(8, Math.min(sw - root.dropPanelWidth - 8, cx - root.dropPanelWidth / 2))
            }

            SystemClock {
                id: dropClock
                precision: SystemClock.Minutes
            }

            readonly property color calendarPanelFill: SamaelStyle.menuPanelFill

            Item {
                id: dropRoot
                width: root.dropPanelWidth
                readonly property real calendarBodyFullH: bodySlot.implicitHeight
                implicitHeight: stem.height + calendarBodyFullH
                height: implicitHeight

                    property real offsetScale: 1
                    readonly property real t: Math.min(1, Math.max(0, offsetScale))
                    /** t=0 open → opaque; t=1 closed → hidden */
                    readonly property real labelOpacity: t > 0.55 ? 0 : Math.min(1, (0.55 - t) / 0.55)

                    clip: true

                    Behavior on offsetScale {
                        NumberAnimation {
                            duration: Appearance.animation.samaelMediaAttach.duration
                            easing.type: Appearance.animation.samaelMediaAttach.type
                            easing.bezierCurve: Appearance.animation.samaelMediaAttach.bezierCurve
                        }
                    }

                    readonly property int calendarYear: dropClock.date.getFullYear()
                    readonly property var todayRef: dropClock.date

                Rectangle {
                    id: stem
                    width: Math.max(48, GlobalStates.samaelClockDropWidth)
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 4
                    anchors.top: parent.top
                    color: calendarPanelFill
                    opacity: dropRoot.t < 0.94 ? 1 : 0
                }

                Item {
                    id: bodyHost
                    width: parent.width
                    anchors.top: stem.bottom
                    anchors.topMargin: -1
                    clip: true
                    readonly property real fullH: bodySlot.implicitHeight
                    height: Math.max(0, fullH * (1 - dropRoot.t))

                    Rectangle {
                        anchors.fill: parent
                        radius: 15
                        color: calendarPanelFill
                        border.width: 2
                        border.color: WallustColors.borderColor
                    }

                    Item {
                        id: bodySlot
                        width: parent.width
                        implicitHeight: headerRow.height + flick.height + 32
                        height: implicitHeight
                        anchors.top: parent.top
                        opacity: dropRoot.labelOpacity

                        Column {
                            id: headerRow
                            width: parent.width - 20
                            x: 10
                            y: 10
                            spacing: 4

                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: "📅 " + dropRoot.calendarYear
                                color: WallustColors.moduleText
                                font.family: SamaelStyle.fontFamily
                                font.pixelSize: SamaelStyle.fontPixelSize + 2
                            }

                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: Qt.formatDateTime(dropRoot.todayRef, "dddd, d MMMM")
                                color: WallustColors.sapphire
                                font.family: SamaelStyle.fontFamily
                                font.pixelSize: SamaelStyle.fontPixelSize
                            }
                        }

                        Flickable {
                            id: flick
                            x: 10
                            y: headerRow.y + headerRow.height + 8
                            width: parent.width - 20
                            height: monthGrid.implicitHeight + 16
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
                                        color: Qt.rgba(0, 0, 0, index === dropRoot.todayRef.getMonth() ? 0.28 : 0.14)
                                        border.width: index === dropRoot.todayRef.getMonth() ? 1 : 0
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
                                                text: monthAscii.monthTitle(dropRoot.calendarYear, index)
                                                color: WallustColors.moduleText
                                                font.family: SamaelStyle.fontFamily
                                                font.pixelSize: SamaelStyle.fontPixelSize
                                                font.bold: index === dropRoot.todayRef.getMonth()
                                            }

                                            MonthMiniCalendar {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                layoutWidth: monthCol.width
                                                year: dropRoot.calendarYear
                                                monthIndex: index
                                                refDate: dropRoot.todayRef
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }


            }

            implicitWidth: dropRoot.width
            implicitHeight: dropRoot.implicitHeight
            mask: Region { item: dropRoot }

            Component.onCompleted: Qt.callLater(() => { dropRoot.offsetScale = 0 })
        }
    }

    QtObject {
        id: monthAscii
        function monthTitle(year, monthIndex) {
            return Qt.formatDateTime(new Date(year, monthIndex, 1), "MMMM")
        }
    }
}