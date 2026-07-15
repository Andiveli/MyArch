import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../singletons"

SettingsConnectedRow {
    id: root

    readonly property bool settingsFocusable: true
    property int ruleIndex: 0
    property var rule: ({})
    property var sinks: []

    function sinkLabel(sinkId) {
        const sid = String(sinkId || "")
        for (let i = 0; i < sinks.length; i++) {
            if (String(sinks[i].id) === sid)
                return sinks[i].description || sinks[i].name
        }
        return sid.length ? ("sink " + sid) : "pick sink id below"
    }

    function patch(field, value) {
        const p = {}
        p[field] = value
        ShellConfigService.updateRoutingRule(ruleIndex, p)
    }

    implicitHeight: inner.implicitHeight + 16

    ColumnLayout {
        id: inner
        anchors.fill: parent
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                text: root.rule.enabled !== false ? "\uf028" : "\uf6a9"
                color: WallustColors.accent
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize
            }
            TextField {
                id: matchField
                Layout.fillWidth: true
                placeholderText: "spotify / zen / game binary…"
                text: root.rule.match || ""
                color: WallustColors.moduleText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize - 1
                onTextEdited: root.patch("match", text)
                background: Rectangle {
                    radius: 4
                    color: Qt.rgba(0, 0, 0, 0.2)
                    border.color: WallustColors.borderColor
                }
            }
            Text {
                text: "→"
                color: WallustColors.moduleText
                opacity: 0.5
            }
            TextField {
                id: sinkField
                Layout.preferredWidth: 48
                placeholderText: "id"
                text: root.rule.sinkId || ""
                color: WallustColors.accent
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize - 1
                onTextEdited: root.patch("sinkId", text)
                background: Rectangle {
                    radius: 4
                    color: Qt.rgba(0, 0, 0, 0.2)
                    border.color: WallustColors.borderColor
                }
            }
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: sinkLabel(root.rule.sinkId) + " · " + (root.rule.matchKind || "application.process.binary")
            color: WallustColors.moduleText
            opacity: 0.45
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize - 2
        }
    }
}