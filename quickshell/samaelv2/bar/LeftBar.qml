import QtQuick
import "../singletons"
import "../surfaces"
import "./BarSection.qml"
import "./WidgetHost.qml"

/** Pill chrome — load via Loader { active: leftOpen } in shell only. */
BarSection {
    id: chrome
    chromeless: true
    bottomMargin: ShellConfig.sectionBottomMargin
    innerMarginLeft: ShellConfig.innerMarginLeftAll
    innerMarginRight: ShellConfig.innerMarginLeftAll
    innerMarginTop: ShellConfig.innerMarginLeftAll
    innerMarginBottom: ShellConfig.innerMarginLeftAll

    property string surface: ""
    property var barScreen: null

    implicitWidth: morphRoot.implicitWidth
    implicitHeight: morphRoot.implicitHeight + bottomMargin

    readonly property bool surfaceOpen: surface.length > 0
    readonly property string mode: surfaceOpen ? surface : "rest"
    readonly property size targetSize: {
        if (mode === "rest")
            return Qt.size(restHost.implicitWidth, Math.max(24, restHost.implicitHeight))
        const sz = ShellConfig.leftSurfaceSize(mode)
        return Qt.size(sz.width, sz.height)
    }

    readonly property real morphCloseness: {
        const tw = targetSize.width
        const th = targetSize.height
        if (tw <= 0 || th <= 0)
            return 1
        const cw = Math.max(1, morphRoot.width)
        const ch = Math.max(1, morphRoot.height)
        return Math.min(1, Math.min(cw / tw, ch / th))
    }

    Item {
        id: morphRoot
        implicitWidth: targetSize.width
        implicitHeight: targetSize.height
        width: implicitWidth
        height: implicitHeight
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -(chrome.bottomMargin / 2)

        Behavior on width {
            NumberAnimation {
                duration: Motion.morph
                easing.type: Motion.easeMorph
                easing.bezierCurve: Motion.morphCurve
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: Motion.morph
                easing.type: Motion.easeMorph
                easing.bezierCurve: Motion.morphCurve
            }
        }

        WidgetHost {
            id: restHost
            zone: "left"
            anchors.centerIn: parent
            visible: !chrome.surfaceOpen
            opacity: chrome.surfaceOpen ? 0 : 1
            widgetIds: ShellConfig.barLeft
            barScreen: chrome.barScreen
        }

        Loader {
            active: chrome.surfaceOpen && chrome.surface === "notifications"
            anchors.fill: parent
            source: "../surfaces/NotificationsSurface.qml"
            onLoaded: {
                if (!item)
                    return
                item.open = true
                item.morphCloseness = Qt.binding(() => chrome.morphCloseness)
            }
        }
    }
}