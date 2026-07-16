import QtQuick
import QtQuick.Layouts
import "../singletons"

RowLayout {
    id: root
    /** "left" | "middle" | "right" — lazy-load only widgets listed in config for that zone. */
    property string zone: "middle"
    property var widgetIds: []
    property var barScreen: null
    property int spacing: 8

    Repeater {
        model: root.widgetIds
        delegate: Loader {
            id: widgetLoader
            required property var modelData
            Layout.alignment: Qt.AlignVCenter
            active: ShellConfig.barEnabled && ShellConfig.hasWidget(root.zone, modelData)
            source: active ? sourceFor(modelData) : ""
            asynchronous: true

            readonly property real layoutW: item && item.implicitWidth > 0 ? item.implicitWidth : -1
            readonly property real layoutH: item && item.implicitHeight > 0 ? item.implicitHeight : -1

            Layout.preferredWidth: layoutW
            Layout.preferredHeight: layoutH

            onLoaded: {
                if (modelData === "workspaces" && item && item.barScreen !== undefined)
                    item.barScreen = root.barScreen
            }
            onActiveChanged: {
                if (!active) {
                    Layout.preferredWidth = -1
                    Layout.preferredHeight = -1
                }
            }
        }
    }

    function sourceFor(id) {
        switch (id) {
        case "workspaces": return "../widgets/WorkspacesWidget.qml"
        case "ai": return "../widgets/AiWidget.qml"
        case "launcher": return "../widgets/LauncherWidget.qml"
        case "notifications": return "../widgets/NotificationsIconWidget.qml"
        case "record": return "../widgets/RecordWidget.qml"
        case "separator": return "../widgets/BarSeparator.qml"
        case "clock": return "../widgets/ClockWidget.qml"
        case "wifi": return "../widgets/WifiWidget.qml"
        case "bluetooth": return "../widgets/BluetoothWidget.qml"
        case "cava": return "../widgets/CavaWidget.qml"
        case "media":
        case "mpris": return "../widgets/MediaWidget.qml"
        case "overview": return "../widgets/OverviewWidget.qml"
        case "power": return "../widgets/PowerWidget.qml"
        default: return ""
        }
    }
}