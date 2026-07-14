import QtQuick
import QtQuick.Effects
import Quickshell.Wayland
import "../singletons"
import "./LockSurfaceContent.qml"

Item {
    id: root

    /** Quickshell screen (width/height) or WlSessionLockSurface.screen */
    required property var screen
    required property var pamHost

    /** Preview overlay: skip screencopy, Esc closes via requestClose */
    property bool designMode: false

    signal requestClose()

    readonly property real screenW: screen && screen.width > 0 ? screen.width : 1920
    readonly property real screenH: screen && screen.height > 0 ? screen.height : 1080
    readonly property real s: Math.max(0.85, Style.fontPixelSize / 11)
    /** Card = fila fastfetch+media (+ padding), sin tope 340 que dejaba hueco */
    readonly property real panelH: {
        const row = content.cardRowH
        if (row > 24)
            return row + 2 * content.pad
        if (LockService.layoutLeftColH > 24)
            return LockService.layoutLeftColH + 2 * content.pad
        return Math.min(screenH * 0.38, 340 * s)
    }
    readonly property real panelW: Math.min(screenW * 0.88, 920 * s)
    readonly property real iconSize: 72 * s
    readonly property real contentScale: Math.min(1, screenH / 1080)

    anchors.fill: parent

    function playUnlock() {
        if (unlockAnim.running || designMode)
            return
        lockIcon.opacity = 1
        lockIcon.rotation = 0
        unlockAnim.start()
    }

    Connections {
        target: LockService
        function onPlayUnlockAnimation() {
            playUnlock()
        }
    }

    property bool lockInWaitSys: false
    property real lockInLockedCardH: 0

    function syncExpandedCardSize() {
        if (designMode || lockInAnim.running || unlockAnim.running || LockService.layoutFrozen)
            return
        lockContent.cardW = panelW
        lockContent.cardH = panelH
    }

    function lockInTargetH() {
        if (LockService.layoutLeftColH > 24)
            return LockService.layoutLeftColH + 2 * content.pad
        const row = content.cardRowH
        if (row > 24)
            return row + 2 * content.pad
        return panelH
    }

    function beginLockInMotion() {
        lockInLockedCardH = lockInTargetH()
        lockBackdrop.opacity = 0
        lockContent.cardScale = 0
        lockContent.cardRotation = 180
        lockIcon.opacity = 1
        lockIcon.rotation = 180
        content.opacity = 0
        content.scale = 0
        lockContent.cardW = lockContent.collapsedSize
        lockContent.cardH = lockContent.collapsedSize
        lockBg.radius = lockContent.collapsedRadius
        lockInAnim.restart()
    }

    Connections {
        target: LockService
        function onSysRevisionChanged() {
            if (lockInWaitSys) {
                lockInWaitSys = false
                Qt.callLater(beginLockInMotion)
                return
            }
            Qt.callLater(syncExpandedCardSize)
        }
    }

    Connections {
        target: content
        function onCardRowHChanged() {
            if (!LockService.layoutFrozen)
                Qt.callLater(syncExpandedCardSize)
        }
    }

    Timer {
        id: lockInSysTimeout
        interval: 280
        repeat: false
        onTriggered: {
            if (!lockInWaitSys)
                return
            lockInWaitSys = false
            beginLockInMotion()
        }
    }

    Timer {
        id: layoutUnfreezeTimer
        interval: 120
        repeat: false
        onTriggered: LockService.layoutFrozen = false
    }

    function playLockIn() {
        LockService.loadSysInfo()
        if (designMode) {
            lockBackdrop.opacity = 1
            lockContent.scale = 1
            lockContent.rotation = 0
            lockIcon.opacity = 0
            content.opacity = 1
            content.scale = 1
            lockContent.cardW = root.panelW
            lockContent.cardH = root.panelH
            lockContent.cardScale = 1
            lockContent.cardRotation = 0
            lockBg.radius = ShellConfig.cornerRadius
            Qt.callLater(() => content.forceActiveFocus())
            return
        }
        LockService.layoutFrozen = true
        layoutUnfreezeTimer.stop()
        if (LockService.sysLoading && LockService.layoutLeftColH <= 24) {
            lockInWaitSys = true
            lockInSysTimeout.restart()
            return
        }
        lockInWaitSys = false
        lockInSysTimeout.stop()
        beginLockInMotion()
    }

    SequentialAnimation {
        id: unlockAnim
        running: false

        ParallelAnimation {
            NumberAnimation {
                target: lockContent
                property: "cardScale"
                to: 0
                duration: Motion.morph
                easing.type: Motion.easeMorph
                easing.bezierCurve: Motion.morphCurve
            }
            NumberAnimation {
                target: lockContent
                property: "opacity"
                to: 0
                duration: Motion.fast
            }
            NumberAnimation {
                target: lockIcon
                property: "opacity"
                to: 1
                duration: Motion.standard
            }
            NumberAnimation {
                target: lockIcon
                property: "rotation"
                to: lockIcon.rotation + 360
                duration: Motion.morph
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: lockBg
                property: "radius"
                to: lockContent.collapsedRadius
                duration: Motion.morph
            }
            NumberAnimation {
                target: lockContent
                property: "cardW"
                to: lockContent.collapsedSize
                duration: Motion.morph
                easing.type: Motion.easeMorph
                easing.bezierCurve: Motion.morphCurve
            }
            NumberAnimation {
                target: lockContent
                property: "cardH"
                to: lockContent.collapsedSize
                duration: Motion.morph
                easing.type: Motion.easeMorph
                easing.bezierCurve: Motion.morphCurve
            }
            NumberAnimation {
                target: lockBackdrop
                property: "opacity"
                to: 0
                duration: Motion.morph
            }
        }
        ScriptAction {
            script: {
                lockContent.cardRotation = 0
                lockContent.cardScale = 1
                lockContent.opacity = 1
                if (root.designMode) {
                    root.requestClose()
                } else {
                    LockService.forceUnlock()
                }
                if (root.pamHost)
                    root.pamHost.unlocking = false
            }
        }
    }

    // Caelestia LockSurface: blurred screencopy only (opacity 0→1), no heavy tint on top
    ScreencopyView {
        id: lockBackdrop
        anchors.fill: parent
        captureSource: root.screen
        opacity: designMode ? 1 : 0

        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 1
            blurMax: 64
            blurMultiplier: 1
        }

        Behavior on opacity {
            NumberAnimation { duration: Motion.morph }
        }
    }

    Text {
        visible: root.designMode
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 12 * s
        text: "LOCK UI PREVIEW — Esc to close"
        color: WallustColors.yellow
        font.family: Style.fontFamily
        font.pixelSize: 10 * s
        font.bold: true
        z: 10
    }

    Item {
        id: lockContent
        anchors.centerIn: parent

        readonly property real collapsedSize: root.iconSize + 32 * s
        readonly property int collapsedRadius: collapsedSize / 4

        property real cardW: collapsedSize
        property real cardH: collapsedSize
        property real cardScale: 0
        property real cardRotation: 180

        implicitWidth: cardW
        implicitHeight: cardH
        width: implicitWidth
        height: implicitHeight

        scale: cardScale
        rotation: cardRotation
        opacity: 1

        Rectangle {
            id: lockBg
            anchors.fill: parent
            radius: designMode ? ShellConfig.cornerRadius : parent.collapsedRadius
            color: Qt.rgba(WallustColors.moduleBackground.r, WallustColors.moduleBackground.g,
                WallustColors.moduleBackground.b, 0.92)
            border.width: 2
            border.color: WallustColors.borderColor
        }

        Text {
            id: lockIcon
            anchors.centerIn: parent
            text: "\uf023"
            color: WallustColors.sky
            font.family: Style.fontFamily
            font.pixelSize: 36 * s
            rotation: designMode ? 0 : 180
            opacity: designMode ? 0 : 1
        }

        LockSurfaceContent {
            id: content
            anchors.fill: lockBg
            pamHost: root.pamHost
            contentScale: root.contentScale
            opacity: designMode ? 1 : 0
            scale: designMode ? 1 : 0
        }
    }

    /** Caelestia LockSurface initAnim: blur in + two-phase lock spin then panel morph */
    ParallelAnimation {
        id: lockInAnim
        running: false

        onFinished: {
            lockContent.cardRotation = 0
            lockIcon.rotation = 0
            lockContent.cardScale = 1
            lockContent.cardW = root.panelW
            lockContent.cardH = lockInLockedCardH > 24 ? lockInLockedCardH : lockInTargetH()
            layoutUnfreezeTimer.restart()
            Qt.callLater(() => content.forceActiveFocus())
        }

        NumberAnimation {
            target: lockBackdrop
            property: "opacity"
            to: 1
            duration: Motion.morph
        }

        SequentialAnimation {
            ParallelAnimation {
                NumberAnimation {
                    target: lockContent
                    property: "cardScale"
                    from: 0
                    to: 1
                    duration: Motion.standard
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.12
                }
                NumberAnimation {
                    target: lockContent
                    property: "cardRotation"
                    from: 180
                    to: 360
                    duration: Motion.morph
                    easing.type: Easing.OutCubic
                }
            }
            ParallelAnimation {
                NumberAnimation {
                    target: lockIcon
                    property: "rotation"
                    from: 180
                    to: 360
                    duration: Motion.morph
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: lockIcon
                    property: "opacity"
                    to: 0
                    duration: Motion.standard
                }
                NumberAnimation {
                    target: content
                    property: "opacity"
                    to: 1
                    duration: Motion.standard
                }
                NumberAnimation {
                    target: content
                    property: "scale"
                    from: 0
                    to: 1
                    duration: Motion.morph
                    easing.type: Motion.easeMorph
                    easing.bezierCurve: Motion.morphCurve
                }
                NumberAnimation {
                    target: lockBg
                    property: "radius"
                    to: ShellConfig.cornerRadius
                    duration: Motion.morph
                }
                NumberAnimation {
                    target: lockContent
                    property: "cardW"
                    to: root.panelW
                    duration: Motion.morph
                    easing.type: Motion.easeMorph
                    easing.bezierCurve: Motion.morphCurve
                }
                NumberAnimation {
                    target: lockContent
                    property: "cardH"
                    to: lockInLockedCardH > 24 ? lockInLockedCardH : lockInTargetH()
                    duration: Motion.morph
                    easing.type: Motion.easeMorph
                    easing.bezierCurve: Motion.morphCurve
                }
            }
        }
    }
}