import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common.widgets
import qs.modules.samael

// Waybar custom/weather: WeatherWrap.sh (Open-Meteo), interval 3600
Item {
    id: root
    property string weatherLine: "󰖐 --°"
    property string weatherTooltip: ""

    implicitWidth: lineText.implicitWidth
    implicitHeight: lineText.implicitHeight

    SamaelPaddedText {
        id: lineText
        text: root.weatherLine
    }

    Process {
        id: weatherProc
        command: ["bash", "/home/samael/.config/hypr/UserScripts/WeatherWrap.sh"]
        stdout: SplitParser {
            onRead: (data) => {
                const raw = data.trim()
                if (!raw.length)
                    return
                try {
                    const j = JSON.parse(raw)
                    root.weatherLine = (j.text ?? "󰖐 --°").trim()
                    root.weatherTooltip = j.tooltip ?? j.alt ?? ""
                } catch (e) {
                    console.warn("[Samael weather] parse failed:", e)
                }
            }
        }
    }

    function refresh() {
        weatherProc.running = false
        weatherProc.running = true
    }

    Timer {
        interval: 3600 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton)
                root.refresh()
        }

        StyledToolTip {
            visible: parent.containsMouse && root.weatherTooltip.length > 0
            text: root.weatherTooltip
        }
    }
}