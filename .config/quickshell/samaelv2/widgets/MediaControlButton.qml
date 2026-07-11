import QtQuick
import "../singletons"

/** Round tonal media control (Font Awesome glyph). */
Item {
    id: root

    property string glyph: "\uf04b"
    property bool enabled: true
    property bool checked: false
    property bool primary: false
    property int diameter: 36

    signal clicked()

    implicitWidth: diameter
    implicitHeight: diameter

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: {
            if (!root.enabled)
                return Qt.rgba(0, 0, 0, 0.15)
            if (root.primary || root.checked)
                return Qt.rgba(WallustColors.buttonHover.r, WallustColors.buttonHover.g,
                               WallustColors.buttonHover.b, 0.35)
            return Qt.rgba(WallustColors.buttonColor.r, WallustColors.buttonColor.g,
                           WallustColors.buttonColor.b, 0.45)
        }
        border.width: root.primary ? 0 : 1
        border.color: WallustColors.borderColor
    }

    Text {
        anchors.centerIn: parent
        text: root.glyph
        font.family: Style.fontFamily
        font.pixelSize: root.primary ? 18 : 15
        color: root.enabled ? WallustColors.moduleText : WallustColors.buttonHover
        opacity: root.enabled ? 1 : 0.4
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}