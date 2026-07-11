import QtQuick
import "../singletons"
import "./WidgetHost.qml"

/**
 * Single middle pill (pill pattern): rest widgets + media surface in one morphing Item.
 * Always on overlay; reserve has no MiddleIdle duplicate.
 */
Item {
    id: pill

    property string surface: ""

    readonly property int padH: ShellConfig.innerMarginMiddleSides
    readonly property int padTop: ShellConfig.sectionPadTopCompact
    readonly property int padInnerBottom: ShellConfig.sectionPadBottomCompact
    readonly property int chromeGap: ShellConfig.sectionBottomMargin
    readonly property int chromeRadius: ShellConfig.cornerRadius

    readonly property bool surfaceOpen: surface.length > 0
    readonly property bool mediaVisible: surfaceOpen && surface === "media"
    readonly property bool wallpaperVisible: surfaceOpen && surface === "wallpaper"
    readonly property bool notifVisible: surfaceOpen && surface === "notifications"
    readonly property bool wifiVisible: surfaceOpen && surface === "wifi"
    readonly property bool btVisible: surfaceOpen && surface === "bluetooth"
    readonly property string mode: wallpaperVisible ? "wallpaper"
        : (mediaVisible ? "media" : (notifVisible ? "notifications" : (wifiVisible ? "wifi" : (btVisible ? "bluetooth" : "rest"))))

    readonly property real restInnerW: Math.max(restHost.implicitWidth, 48)
    readonly property real restInnerH: Math.max(restHost.implicitHeight, Style.barContentHeight)

    readonly property size targetInner: {
        if (mode === "rest")
            return Qt.size(restInnerW, restInnerH)
        const sz = ShellConfig.surfaceSize(mode)
            if (mode === "wallpaper") {
                const h = Math.max(sz.height, 124)
                return Qt.size(Math.max(sz.width, 880), h)
            }
            if (mode === "media") {
                const m = ldMedia.item
                if (m && m.implicitWidth > 0)
                    return Qt.size(Math.max(sz.width, m.implicitWidth), Math.max(sz.height, m.implicitHeight))
            }
            if (mode === "notifications") {
                const n = ldNotif.item
                if (n && n.implicitHeight > 0)
                    return Qt.size(Math.max(sz.width, n.implicitWidth), Math.max(sz.height, n.implicitHeight))
            }
                if (mode === "wifi") {
                    const w = ldWifi.item
                    if (w && w.implicitHeight > 0)
                        return Qt.size(Math.max(sz.width, w.implicitWidth), Math.max(sz.height, w.implicitHeight))
                }
                if (mode === "bluetooth") {
                    const b = ldBt.item
                    if (b && b.implicitHeight > 0)
                        return Qt.size(Math.max(sz.width, b.implicitWidth), Math.max(sz.height, b.implicitHeight))
                }
                return Qt.size(sz.width, sz.height)

        }

    readonly property int morphPadH: wallpaperVisible ? 6 : padH
    readonly property int morphPadTop: wallpaperVisible ? 0 : padTop
    readonly property int morphPadBottom: wallpaperVisible ? 0 : padInnerBottom
    readonly property int morphChromeGap: wallpaperVisible ? 0 : chromeGap

    readonly property real targetW: targetInner.width + morphPadH * 2
    readonly property real targetH: targetInner.height + morphPadTop + morphPadBottom + morphChromeGap

    implicitWidth: targetW
    implicitHeight: targetH
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
        if (!surfaceOpen && width > 0)
            ShellActions.middleRestWidth = width
        if (!surfaceOpen && height > 0)
            ShellActions.middleRestHeight = height
    }

        Component.onCompleted: Qt.callLater(syncRestToShell)

        onWallpaperVisibleChanged: {
            if (wallpaperVisible && ldWallpaper.item)
                Qt.callLater(() => ldWallpaper.item.forceActiveFocus())
        }

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
        anchors.leftMargin: morphPadH
        anchors.rightMargin: morphPadH
        anchors.topMargin: morphPadTop
        anchors.bottomMargin: morphChromeGap + morphPadBottom
        clip: true

        WidgetHost {
            id: restHost
            zone: "middle"
            widgetIds: ShellConfig.barMiddle
            spacing: 6
            anchors.centerIn: parent
            opacity: (mediaVisible || wallpaperVisible || notifVisible || wifiVisible || btVisible) ? 0 : Math.pow(morphCloseness, 1.5)
            visible: opacity > 0.02
            enabled: mode === "rest"
        }

        Loader {
            id: ldMedia
            anchors.fill: parent
            active: surfaceOpen && surface === "media"
            source: "../surfaces/MediaSurface.qml"
            onLoaded: bindMedia(item)
            onActiveChanged: if (active && item) bindMedia(item)

            function bindMedia(mediaItem) {
                if (!mediaItem)
                    return
                mediaItem.open = Qt.binding(() => pill.mediaVisible)
                mediaItem.fadeWithMorph = true
                mediaItem.contentShown = true
                    mediaItem.morphCloseness = Qt.binding(() => pill.morphCloseness)
                    if (pill.mediaVisible)
                        Qt.callLater(() => mediaItem.forceActiveFocus())
                }
        }

            Loader {
                id: ldNotif
                anchors.fill: parent
                active: pill.notifVisible
                source: "../surfaces/NotificationsSurface.qml"
                onLoaded: bindNotif(item)
                onActiveChanged: if (active && item) bindNotif(item)

                function bindNotif(nItem) {
                    if (!nItem)
                        return
                    nItem.open = Qt.binding(() => pill.notifVisible)
                    nItem.morphCloseness = Qt.binding(() => pill.morphCloseness)
                    if (pill.notifVisible)
                        Qt.callLater(() => nItem.forceActiveFocus())
                }
            }

                Loader {
                    id: ldWifi
                    anchors.fill: parent
                    active: pill.wifiVisible
                    source: "../surfaces/WifiSurface.qml"
                    onLoaded: bindWifi(item)
                    onActiveChanged: if (active && item) bindWifi(item)

                    function bindWifi(wItem) {
                        if (!wItem)
                            return
                        wItem.open = Qt.binding(() => pill.wifiVisible)
                        wItem.morphCloseness = Qt.binding(() => pill.morphCloseness)
                        if (pill.wifiVisible)
                            Qt.callLater(() => wItem.forceActiveFocus())
                    }
                }

                Loader {
                    id: ldBt
                    anchors.fill: parent
                    active: pill.btVisible
                    source: "../surfaces/BluetoothSurface.qml"
                    onLoaded: bindBt(item)
                    onActiveChanged: if (active && item) bindBt(item)

                    function bindBt(bItem) {
                        if (!bItem)
                            return
                        bItem.open = Qt.binding(() => pill.btVisible)
                        bItem.morphCloseness = Qt.binding(() => pill.morphCloseness)
                        if (pill.btVisible)
                            Qt.callLater(() => bItem.forceActiveFocus())
                    }
                }

                Loader {
                    id: ldWallpaper

                objectName: "middleWallpaperLoader"
            anchors.fill: parent
            active: pill.wallpaperVisible
            source: "../surfaces/WallpaperPickerSurface.qml"
            onLoaded: bindWallpaper(item)
            onActiveChanged: if (active && item) bindWallpaper(item)

            function bindWallpaper(wpItem) {
                if (!wpItem)
                    return
                wpItem.active = Qt.binding(() => pill.wallpaperVisible)
                    wpItem.requestClose.connect(() => {
                        if (ShellActions.closeMiddleSurface)
                            ShellActions.closeMiddleSurface()
                    })
                    if (pill.wallpaperVisible) {
                        Qt.callLater(wpItem.prepareOpen)
                        Qt.callLater(() => wpItem.forceActiveFocus())
                    }
            }
        }
    }
}