import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.dashboard
import qs.modules.samael.widgets

Item {
    id: root
    focus: true

    /** 0 = Caelestia metrics, 1 = top processes + audio */
    property int dropTabIndex: 0

    readonly property real overviewBottomPad: 10
    readonly property real tabBarHeight: tabBarRow.implicitHeight
    readonly property real metricsContentHeight: perfBlock.implicitHeight + overviewBottomPad
    readonly property real processesContentHeight: procAudio.implicitHeight
    readonly property real activeContentHeight: dropTabIndex === 0
        ? metricsContentHeight
        : processesContentHeight

    implicitWidth: column.width
    implicitHeight: tabBarHeight + column.spacing + activeContentHeight + 2

    function focusActiveTab() {
        if (dropTabIndex === 0) {
            procAudio.focus = false
            metricsPane.forceActiveFocus()
        } else {
            procAudio.forceActiveFocus()
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Tab && !event.modifiers) {
            dropTabIndex = (dropTabIndex + 1) % 2
            Qt.callLater(root.focusActiveTab)
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Backtab) {
            dropTabIndex = (dropTabIndex + 1) % 2
            Qt.callLater(root.focusActiveTab)
            event.accepted = true
            return
        }
    }

    ColumnLayout {
        id: column
        width: parent.width
        spacing: 10

        RowLayout {
            id: tabBarRow
            Layout.fillWidth: true
            spacing: 16

            PerformanceTabChip {
                label: qsTr("Overview")
                active: root.dropTabIndex === 0
                onClicked: {
                    root.dropTabIndex = 0
                    root.focusActiveTab()
                }
            }

            PerformanceTabChip {
                label: qsTr("Processes & audio")
                active: root.dropTabIndex === 1
                onClicked: {
                    root.dropTabIndex = 1
                    root.focusActiveTab()
                }
            }

            Item { Layout.fillWidth: true }

            StyledText {
                text: qsTr("Tab")
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        Item {
            id: tabContentHost
            Layout.fillWidth: true
            implicitWidth: column.width
            implicitHeight: root.activeContentHeight
            height: implicitHeight
            clip: false

            Item {
                id: metricsWrap
                visible: root.dropTabIndex === 0
                enabled: visible
                width: tabContentHost.width
                implicitHeight: perfBlock.implicitHeight + root.overviewBottomPad
                height: implicitHeight

                Item {
                    id: metricsPane
                    focus: root.dropTabIndex === 0
                    width: parent.width
                    height: perfBlock.implicitHeight

                    Performance {
                        id: perfBlock
                        width: column.width
                        compactLayout: true
                    }
                }
            }

            SamaelSystemSidebar {
                id: procAudio
                visible: root.dropTabIndex === 1
                enabled: visible
                width: tabContentHost.width
                y: 0
                performanceDropMode: true
            }
        }
    }

    component PerformanceTabChip: MouseArea {
        id: chip

        property string label
        property bool active

        signal clicked()

        implicitWidth: chipRow.implicitWidth + 12
        implicitHeight: chipRow.implicitHeight + 8
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: chip.clicked()

        RowLayout {
            id: chipRow
            anchors.centerIn: parent
            spacing: 0

            StyledText {
                text: chip.label
                font: Tokens.font.body.builders.medium.weight(chip.active ? Font.DemiBold : Font.Normal).build()
                color: chip.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: chipRow.width
            height: 2
            radius: 1
            visible: active
            color: Colours.palette.m3primary
        }
    }
}