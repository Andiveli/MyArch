import QtQuick
import QtQuick.Layouts
import qs.modules.common

Item {
    id: root
    property bool drawerOpen: false
    property Component mainContent  // El botón/indicador principal
    property Component drawerContent // El contenido del drawer
    property int drawerWidth: 200
    property int animationDuration: 200

    implicitWidth: mainRow.implicitWidth
    implicitHeight: mainRow.implicitHeight

    Row {
        id: mainRow
        spacing: 4

        Loader {
            id: mainLoader
            sourceComponent: root.mainContent
        }
    }

    // Drawer overlay (appears below the main row)
    Rectangle {
        id: drawer
        anchors {
            top: mainRow.bottom
            topMargin: 2
            left: root.left
        }
        width: root.drawerWidth
        height: root.drawerOpen ? drawerContentLoader.implicitHeight + 8 : 0
        radius: 8
        color: Qt.rgba(0, 0, 0, 0.6)
        opacity: root.drawerOpen ? 1 : 0
        clip: true
        z: 100

        Behavior on height {
            NumberAnimation {
                duration: root.animationDuration
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: root.animationDuration / 2
            }
        }

        Loader {
            id: drawerContentLoader
            anchors {
                top: parent.top
                topMargin: 4
                left: parent.left
                leftMargin: 4
            }
            sourceComponent: root.drawerContent
        }
    }

    // Click on main content toggles drawer
    MouseArea {
        id: toggleArea
        anchors.fill: mainRow
        onClicked: root.drawerOpen = !root.drawerOpen

        // Close drawer when clicking outside
        onPressed: (event) => {
            // handled by onClicked
        }
    }
}
