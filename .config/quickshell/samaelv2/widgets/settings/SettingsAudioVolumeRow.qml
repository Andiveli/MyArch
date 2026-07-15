import QtQuick
import QtQuick.Layouts
import "../../singletons"
import "../../widgets"

/** Per-stream volume — bar + h/l step; flagged for settings vim routing. */
SettingsConnectedRow {
    id: root

    readonly property bool settingsFocusable: true
    readonly property bool audioVolumeRow: true

    property string streamId: ""
    property int value: 0
    property bool muted: false
    property int step: 3
    property int from: 0
    property int to: 100

    function bump(delta) {
        const v = Math.max(from, Math.min(to, value + delta * step))
        if (v !== value && streamId.length)
            AudioRouteService.setStreamVolume(streamId, v)
    }

    function trigger() {
        bump(1)
    }

    implicitHeight: 52

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: "Volume"
                color: WallustColors.moduleText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize
                font.bold: root.vimFocus
            }
            Text {
                text: muted ? "muted" : (value + "%")
                color: WallustColors.accent
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize - 1
            }
        }

        OverviewSmoothBar {
            Layout.fillWidth: true
            implicitHeight: 6
            barRadius: 3
            fraction: muted ? 0 : Math.max(0, Math.min(1, value / 100))
            fillColor: WallustColors.accent
            trackOpacity: 0.14
        }

        Text {
            Layout.fillWidth: true
            text: "h lower · l higher"
            color: WallustColors.moduleText
            opacity: 0.35
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize - 3
            visible: root.vimFocus
        }
    }
}