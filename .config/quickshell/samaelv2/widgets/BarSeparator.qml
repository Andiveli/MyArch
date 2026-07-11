import QtQuick
import "../singletons"

Item {
    implicitWidth: 1
    implicitHeight: Style.barContentHeight

    Rectangle {
        anchors.centerIn: parent
        width: 1
        height: parent.height * 0.65
        radius: 0.5
        color: WallustColors.borderColor
        opacity: 0.55
    }
}