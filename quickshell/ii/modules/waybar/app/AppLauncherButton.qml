import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

/**
 * App Launcher Button - Used in AppLauncher group
 */
Item {
    id: root
    property string iconName
    property color iconColor
    signal clicked

    implicitWidth: 28
    implicitHeight: Appearance.sizes.barHeight

    MaterialSymbol {
        id: icon
        anchors.centerIn: parent
        text: iconName
        iconSize: Appearance.font.pixelSize.normal
        color: root.iconColor
    }

    TapHandler {
        onTapped: {
            root.clicked()
        }
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: {
            // Optional: right click action
        }
    }
}
