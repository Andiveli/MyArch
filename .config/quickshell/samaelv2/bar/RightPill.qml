import QtQuick
import "../singletons"
import "./WidgetHost.qml"
import "./OsdBarContent.qml"

/**
 * Right bar pill: rest | overview | toast | osd | combined (overview + toast).
 *
 * Combined mode: when overview is open and a toast notification arrives,
 * the pill shows both stacked (overview top, toast bottom) instead of
 * replacing the overview. Toast alone still takes over the pill as before.
 */
Item {
    id: pill

    property string screenName: ""
    property string surface: ""

    readonly property int padH: ShellConfig.innerMarginRightBeforeContent
    readonly property int padTop: ShellConfig.sectionPadTopCompact
    readonly property int padInnerBottom: ShellConfig.sectionPadBottomCompact
    readonly property int chromeGap: ShellConfig.sectionBottomMargin
    readonly property int chromeRadius: ShellConfig.cornerRadius

    readonly property bool surfaceOpen: surface.length > 0
    readonly property bool overviewVisible: surfaceOpen && surface === "overview"

    readonly property bool toastActive: NotifsService.popups.length > 0
    readonly property bool osdActive: OsdService.visibleOnMonitor(screenName)
    readonly property bool combinedVisible: overviewVisible && toastActive

    readonly property string mode: combinedVisible ? "combined"
        : (overviewVisible ? "overview"
        : (osdActive ? "osd"
        : (toastActive ? "toast" : "rest")))

    readonly property real restInnerW: Math.max(restHost.implicitWidth, 48)
    readonly property real restInnerH: Math.max(restHost.implicitHeight, Style.barContentHeight)

    readonly property real toastW: 342
    readonly property real toastInnerH: toastActive
            ? Math.max((toastLoader.item ? toastLoader.item.implicitHeight : 0) + 24, restInnerH)
            : restInnerH

    readonly property real toastCombinedH: toastActive
        ? Math.max((toastLoader.item ? toastLoader.item.implicitHeight : 0) + 16, 36)
        : 0
    readonly property real toastSeparatorH: combinedVisible ? 1 : 0

    readonly property size targetInner: {
        if (mode === "combined") {
            const sz = ShellConfig.rightSurfaceSize("overview")
            const o = ldOverview.item
            const overviewW = o && o.implicitWidth > 0
                ? Math.max(sz.width, o.implicitWidth) : sz.width
            const overviewH = o && o.implicitHeight > 0
                ? Math.max(sz.height, o.implicitHeight) : sz.height
            return Qt.size(
                Math.max(overviewW, toastW),
                overviewH + toastSeparatorH + toastCombinedH)
        }
        if (mode === "toast")
            return Qt.size(toastW, toastInnerH)
        if (mode === "osd")
            return Qt.size(OsdService.desiredW, restInnerH)
        if (mode === "overview") {
            const sz = ShellConfig.rightSurfaceSize("overview")
            const o = ldOverview.item
            if (o && o.implicitWidth > 0)
                return Qt.size(Math.max(sz.width, o.implicitWidth), Math.max(sz.height, o.implicitHeight))
            return Qt.size(sz.width, sz.height)
        }
        return Qt.size(restInnerW, restInnerH)
    }

    readonly property real targetW: targetInner.width + padH * 2
    readonly property real targetH: targetInner.height + padTop + padInnerBottom + chromeGap

    width: targetW
    height: targetH

    readonly property real morphCloseness: {
        const d = Math.max(Math.abs(width - targetW), Math.abs(height - targetH))
        return d < 0.5 ? 1 : (1 - Math.min(1, d / 110))
    }

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

    onWidthChanged: syncRestToShell()
    onHeightChanged: syncRestToShell()

    function syncRestToShell() {
        if (!surfaceOpen && mode === "rest" && width > 0)
            ShellActions.rightRestWidth = width
        if (!surfaceOpen && mode === "rest" && height > 0)
            ShellActions.rightRestHeight = height
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
        clip: true

        WidgetHost {
            id: restHost
            zone: "right"
            widgetIds: ShellConfig.barRight
            spacing: 6
            anchors.centerIn: parent
            opacity: (mode === "rest" && !overviewVisible) ? Math.pow(morphCloseness, 1.5) : 0
            visible: opacity > 0.02
            enabled: mode === "rest"
        }

        Loader {
            id: ldOverview
            x: 0
            y: 0
            width: parent.width
            height: combinedVisible
                ? (parent.height - toastSeparatorH - toastCombinedH)
                : parent.height
            active: pill.overviewVisible
            source: "../surfaces/SystemOverviewSurface.qml"
            onLoaded: bindOverview(item)
            onActiveChanged: if (active && item) bindOverview(item)

            function bindOverview(oItem) {
                if (!oItem)
                    return
                oItem.open = Qt.binding(() => pill.overviewVisible)
                oItem.morphCloseness = Qt.binding(() => pill.morphCloseness)
                if (pill.overviewVisible)
                    Qt.callLater(() => oItem.forceActiveFocus())
            }
        }

        Rectangle {
            id: toastSeparator
            visible: combinedVisible
            color: WallustColors.borderColor
            width: parent.width - 16
            height: 1
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(parent.height - toastCombinedH - height)
        }

        Item {
            id: toastHost
            visible: mode === "toast" || mode === "combined"
            opacity: (mode === "toast" || mode === "combined")
                ? Math.pow(morphCloseness, 1.3) : 0
            enabled: mode === "toast" || mode === "combined"

            x: combinedVisible ? 8 : 0
            y: combinedVisible ? Math.round(parent.height - toastCombinedH) : 0
            width: parent.width - (combinedVisible ? 16 : 0)
            height: combinedVisible ? toastCombinedH : parent.height

            Loader {
                id: toastLoader
                anchors.fill: parent
                anchors.margins: combinedVisible ? 4 : 0
                active: pill.toastActive
                source: "../widgets/NotificationToast.qml"
                onLoaded: {
                    if (!item)
                        return
                    item.width = Qt.binding(() => toastLoader.width)
                    item.notif = Qt.binding(() => NotifsService.popups.length > 0
                        ? NotifsService.popups[NotifsService.popups.length - 1]
                        : null)
                    item.live = Qt.binding(() => pill.mode === "toast" || pill.mode === "combined")
                }
            }

            Text {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                visible: NotifsService.popups.length > 1
                text: "+" + (NotifsService.popups.length - 1)
                color: WallustColors.moduleText
                opacity: 0.5
                font.pixelSize: 9
                font.weight: Font.DemiBold
            }
        }

        OsdBarContent {
            id: osdContent
            z: 2
            anchors.fill: parent
            enabled: mode === "osd"
            visible: mode === "osd"
            opacity: mode === "osd" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.fast } }
            kind: OsdService.kind
            level: OsdService.barLevel
            muted: OsdService.muted
        }
    }
}
