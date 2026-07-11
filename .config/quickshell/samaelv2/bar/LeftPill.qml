import QtQuick
import "../singletons"
import "./WidgetHost.qml"

/**
 * Left pill on overlay (same pattern as MiddlePill / RightPill): workspaces rest + left surfaces morph.
 */
Item {
    id: pill

    property string surface: ""
    property var barScreen: null

    readonly property int padH: ShellConfig.innerMarginLeftAll
    readonly property int padTop: ShellConfig.sectionPadTopCompact
    readonly property int padInnerBottom: ShellConfig.sectionPadBottomCompact
    readonly property int chromeGap: ShellConfig.sectionBottomMargin
    readonly property int chromeRadius: ShellConfig.cornerRadius

    readonly property bool surfaceOpen: surface.length > 0
    readonly property string mode: "rest"

    readonly property real restInnerW: Math.max(restHost.implicitWidth, 48)
    readonly property real restInnerH: Math.max(restHost.implicitHeight, Style.barContentHeight)

    readonly property size targetInner: Qt.size(restInnerW, restInnerH)

    readonly property real targetW: targetInner.width + padH * 2
    readonly property real targetH: targetInner.height + padTop + padInnerBottom + chromeGap

    implicitWidth: targetW
    implicitHeight: targetH
    width: targetW
    height: targetH

    readonly property real morphCloseness: {
        const d = Math.max(Math.abs(width - targetW), Math.abs(height - targetH))
        return d < 0.5 ? 1 : (1 - Math.min(1, d / 110))
    }

    readonly property bool restWidthMorph: width > 0 && Math.abs(width - targetW) > 12

    Behavior on width {
        NumberAnimation {
            duration: pill.restWidthMorph ? Motion.fast : 0
            easing.type: Easing.OutBack
            easing.overshoot: 1.35
            easing.bezierCurve: [0.2, 0.8, 0.2, 1, 1, 1]
        }
    }
    Behavior on height {
        NumberAnimation {
            duration: Motion.morph
            easing.type: Motion.easeMorph
            easing.bezierCurve: Motion.morphCurve
        }
    }

    onWidthChanged: syncRestToShell()
    onHeightChanged: syncRestToShell()

    function syncRestToShell() {
        if (!surfaceOpen && width > 0)
            ShellActions.leftRestWidth = width
        if (!surfaceOpen && height > 0)
            ShellActions.leftRestHeight = height
    }

    Component.onCompleted: Qt.callLater(syncRestToShell)

    Rectangle {
        anchors.fill: parent
        radius: chromeRadius
        color: Qt.rgba(WallustColors.moduleBackground.r, WallustColors.moduleBackground.g,
                        WallustColors.moduleBackground.b, 0.92)
        border.width: 2
        border.color: WallustColors.borderColor
    }

    Item {
        id: morphRoot
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: padH
        anchors.rightMargin: padH
        anchors.topMargin: padTop
        anchors.bottomMargin: chromeGap + padInnerBottom
        clip: false

        WidgetHost {
            id: restHost
            zone: "left"
            widgetIds: ShellConfig.barLeft
            barScreen: pill.barScreen
            spacing: 6
            anchors.centerIn: parent
            opacity: Math.pow(morphCloseness, 1.5)
            visible: opacity > 0.02
            enabled: true
        }
    }
}