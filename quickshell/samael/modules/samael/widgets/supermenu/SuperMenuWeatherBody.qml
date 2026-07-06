import QtQuick
import QtQuick.Layouts
import qs.modules.samael

Rectangle {
    id: root
    color: "transparent"
    implicitWidth: 480
    implicitHeight: 120

    property string weatherLine: ""

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8
        Text {
            text: "WEATHER"
            font.family: SamaelStyle.fontFamily
            font.pixelSize: 11
            font.bold: true
            color: "#1a8cff"
        }
        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: weatherLine.length ? weatherLine : "Loading…"
            font.family: SamaelStyle.fontFamily
            font.pixelSize: 12
            color: "#e0e6f0"
        }
    }
}