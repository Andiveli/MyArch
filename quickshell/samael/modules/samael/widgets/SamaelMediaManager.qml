import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.modules.samael
import qs.modules.samael.widgets
import Qt5Compat.GraphicalEffects

Item {
    id: root
    focus: true
    activeFocusOnTab: false

    /** Inside SamaelBar center dock (no outer card) */
    property bool embeddedInBar: false
    /** Caelestia dashboard Media skin; vim Keys unchanged on this root */
    property bool useCaelestiaMediaSkin: true

    readonly property int panelWidth: 680
    /** Bar drop column widths (compact) */
    readonly property int barDiscW: 228
    readonly property int barMetaW: 208
    readonly property int barLyricsW: 220
    readonly property int barGap: 16
    readonly property int caelestiaMediaRowWidth: barDiscW + barGap + barMetaW
        + (caelestiaLyricsVisible ? barGap + barLyricsW : 0)
    property bool caelestiaLyricsVisible: true
    readonly property int effectiveDropWidth: useCaelestiaMediaSkin
        ? caelestiaMediaRowWidth + 40
        : panelWidth
    readonly property int coverSize: 208
    readonly property int discRingExtent: 42
    readonly property int discColumnW: 268
    /** Fixed so play/pause and Cava never re-center the row */
    readonly property int discRowW: coverSize + discRingExtent * 2 + 22 + discColumnW
    readonly property int seekStepSec: 10

    /** Lock after first layout so play/pause cannot resize the drop */
    property int bodyHeightLock: 0

    readonly property var players: SamaelPlayers.list
    readonly property MprisPlayer player: SamaelPlayers.active
    readonly property string coverArtUrl: SamaelPlayers.getArtUrl(player)

    function lengthStr(seconds) {
        if (seconds < 0 || isNaN(seconds))
            return "--:--"
        const s = Math.floor(seconds)
        const mins = Math.floor(s / 60)
        const secs = (s % 60).toString().padStart(2, "0")
        return `${mins}:${secs}`
    }

    function closePanel() {
        GlobalStates.mediaControlsOpen = false
    }

        function cyclePlayer(delta) {
            const ps = players
            const n = ps.length
            if (n <= 1)
                return
            const curKey = SamaelPlayers.playerKey(player)
            let idx = 0
            for (let i = 0; i < n; ++i) {
                if (SamaelPlayers.playerKey(ps[i]) === curKey) {
                    idx = i
                    break
                }
            }
            const nextIdx = (idx + delta + n) % n
            if (nextIdx === idx)
                return
            SamaelPlayers.setActivePlayer(ps[nextIdx])
        }

        function cycleLoopState() {
            const p = player
            if (!p?.loopSupported)
                return
            const state = p.loopState
            if (state === MprisLoopState.None)
                p.loopState = MprisLoopState.Track
            else if (state === MprisLoopState.Track)
                p.loopState = MprisLoopState.Playlist
            else
                p.loopState = MprisLoopState.None
        }

        function toggleShuffle() {
            const p = player
            if (p?.shuffleSupported)
                p.shuffle = !p.shuffle
        }

        /** 0 shuffle … 4 loop (keyboard focus ring) */
        property int controlFocus: 2

        readonly property var controlSpecs: [
            { id: "shuffle", enabled: player?.shuffleSupported ?? false, activate: () => toggleShuffle() },
            { id: "prev", enabled: player?.canGoPrevious ?? false, activate: () => player?.previous() },
            { id: "play", enabled: player?.canTogglePlaying ?? false, activate: () => player?.togglePlaying() },
            { id: "next", enabled: player?.canGoNext ?? false, activate: () => player?.next() },
            { id: "loop", enabled: player?.loopSupported ?? false, activate: () => cycleLoopState() }
        ]

        function moveControlFocus(delta) {
            const n = controlSpecs.length
            if (!n)
                return
            let i = controlFocus
            for (let step = 0; step < n; step++) {
                i = (i + delta + n) % n
                if (controlSpecs[i].enabled) {
                    controlFocus = i
                    return
                }
            }
        }

        function activateFocusedControl() {
            const spec = controlSpecs[controlFocus]
            if (spec?.enabled)
                spec.activate()
        }

    function seekBy(deltaSec) {
        const p = player
        if (!p?.canSeek || !p.positionSupported)
            return
        const len = p.length || 0
        let pos = p.position
        if (len > 0)
            pos = ((pos % len) + len) % len
        let next = pos + deltaSec
        if (len > 0)
            next = Math.max(0, Math.min(len - 0.25, next))
        else
            next = Math.max(0, next)
        p.position = next
    }


    Timer {
        running: root.player?.playbackState === MprisPlaybackState.Playing
        interval: (typeof GlobalConfig !== "undefined" && GlobalConfig.dashboard)
            ? GlobalConfig.dashboard.mediaUpdateInterval
            : 500
        repeat: true
        onTriggered: if (root.player)
            root.player.positionChanged()
    }

        implicitWidth: effectiveDropWidth
        implicitHeight: {
            if (useCaelestiaMediaSkin) {
                if (!root.player)
                    return 200
                const skinH = caelestiaMediaSkin.implicitHeight
                return Math.max(200, skinH + 28)
            }
            if (!root.player)
                return 220
            return bodyHeightLock > 0 ? bodyHeightLock : bodyLayout.implicitHeight + 32
        }

        onImplicitHeightChanged: {
            if (useCaelestiaMediaSkin || !root.player || !GlobalStates.mediaControlsOpen)
                return
            const h = bodyLayout.implicitHeight + 32
            if (h > 80 && (bodyHeightLock === 0 || Math.abs(h - bodyHeightLock) > 2))
                bodyHeightLock = h
        }

        Rectangle {
            id: panelBg
            anchors.fill: parent
            radius: (root.useCaelestiaMediaSkin && root.embeddedInBar)
                ? 0
                : (root.useCaelestiaMediaSkin
                    ? Tokens.rounding.extraLarge
                    : (root.embeddedInBar ? 0 : 14))
            color: (root.useCaelestiaMediaSkin && root.embeddedInBar)
                ? "transparent"
                : (root.useCaelestiaMediaSkin
                    ? Colours.palette.m3surfaceContainerHigh
                    : (root.embeddedInBar ? "transparent" : SamaelStyle.menuPanelFill))
            border.width: (root.useCaelestiaMediaSkin && root.embeddedInBar)
                ? 0
                : (root.useCaelestiaMediaSkin ? 1 : (root.embeddedInBar ? 0 : 2))
            border.color: root.useCaelestiaMediaSkin
            ? Colours.palette.m3outlineVariant
            : WallustColors.borderColor

            readonly property bool hasPlayer: !!root.player

            states: [
                State {
                    name: "empty"
                    when: !panelBg.hasPlayer
                    PropertyChanges { target: emptyState; opacity: 1 }
                    PropertyChanges { target: bodyLayout; opacity: 0 }
                },
                State {
                    name: "playing"
                    when: panelBg.hasPlayer
                    PropertyChanges { target: emptyState; opacity: 0 }
                    PropertyChanges { target: bodyLayout; opacity: 1 }
                }
            ]

            transitions: Transition {
                from: "*"; to: "*"
                NumberAnimation {
                    properties: "opacity"
                    duration: Appearance.animation.elementMove.duration
                    easing.type: Appearance.animation.elementMove.type
                    easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                }
            }

            ColumnLayout {
                id: emptyState
                anchors.centerIn: parent
                width: parent.width - 32
                opacity: 0
                spacing: Tokens.spacing.small

                MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                visible: root.useCaelestiaMediaSkin
                text: "art_track"
                grade: 200
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.size(40).build()
                }

                Text {
                Layout.alignment: Qt.AlignHCenter
                visible: !root.useCaelestiaMediaSkin
                text: "󰎈"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 36
                color: WallustColors.buttonHover
                }

                StyledText {
                Layout.alignment: Qt.AlignHCenter
                visible: root.useCaelestiaMediaSkin
                text: qsTr("Nothing playing")
                font: Tokens.font.title.small
                color: Colours.palette.m3primary
                }

                Text {
                Layout.alignment: Qt.AlignHCenter
                visible: !root.useCaelestiaMediaSkin
                text: "Nothing playing"
                color: WallustColors.moduleText
                font.family: SamaelStyle.fontFamily
                font.pixelSize: SamaelStyle.fontPixelSize + 2
                }

                StyledText {
                Layout.alignment: Qt.AlignHCenter
                visible: root.useCaelestiaMediaSkin
                text: qsTr("Start a player with MPRIS support")
                font: Tokens.font.body.small
                color: Colours.palette.m3outline
                horizontalAlignment: Text.AlignHCenter
                }

                Text {
                Layout.alignment: Qt.AlignHCenter
                visible: !root.useCaelestiaMediaSkin
                text: "Start a player with MPRIS support"
                color: WallustColors.buttonHover
                font.family: SamaelStyle.fontFamily
                font.pixelSize: SamaelStyle.fontPixelSize - 1
                horizontalAlignment: Text.AlignHCenter
                }
            }

        ColumnLayout {
            id: bodyLayout
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: root.useCaelestiaMediaSkin ? 12 : 16
            opacity: 0
            spacing: root.useCaelestiaMediaSkin ? 8 : 12

            RowLayout {
                Layout.fillWidth: true
                visible: !root.useCaelestiaMediaSkin
                Text {
                    text: "MEDIA"
                    color: WallustColors.moduleText
                    font.family: SamaelStyle.fontFamily
                    font.pixelSize: SamaelStyle.fontPixelSize + 1
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                    visible: players.length > 1
                    text: `${SamaelPlayers.getIdentity(player)} · Tab player`
                    color: WallustColors.buttonHover
                    font.family: SamaelStyle.fontFamily
                    font.pixelSize: SamaelStyle.fontPixelSize - 2
                    elide: Text.ElideRight
                    Layout.maximumWidth: 220
                }
                Text {
                    text: "h/l track · j/k lyrics/seek · s shuffle · r loop · ←/→ · space · esc"
                    color: WallustColors.buttonHover
                    font.family: SamaelStyle.fontFamily
                    font.pixelSize: SamaelStyle.fontPixelSize - 2
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                }
            }

                ColumnLayout {
                    visible: root.useCaelestiaMediaSkin
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6

                    SamaelCaelestiaMedia {
                        id: caelestiaMediaSkin
                        Layout.alignment: Qt.AlignHCenter
                        horizontalBarLayout: true
                        compactBarDrop: true
                        barDiscWidth: root.barDiscW
                        barMetaWidth: root.barMetaW
                        barLyricsWidth: root.barLyricsW
                        columnWidthOverride: root.caelestiaMediaRowWidth
                        showLyricsColumn: root.caelestiaLyricsVisible
                        controlFocusIndex: root.controlFocus
                    }

                    StyledText {
                        Layout.fillWidth: true
                        Layout.preferredWidth: root.caelestiaMediaRowWidth
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        text: "h/l track · j/k lyrics · L/y lyrics · s · r · ←/→ · space · Tab · esc"
                        font: Tokens.font.label.small
                        color: Colours.palette.m3outline
                    }
                }

            Item {
                Layout.fillWidth: true
                Layout.topMargin: 4
                Layout.preferredHeight: discColumnRow.implicitHeight
                Layout.alignment: Qt.AlignHCenter
                visible: !root.useCaelestiaMediaSkin

                RowLayout {
                    id: discColumnRow
                    width: root.discRowW
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 22

                    SamaelMediaDiscCava {
                        id: discViz
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: implicitWidth
                        Layout.preferredHeight: implicitHeight
                        discDiameter: root.coverSize
                        ringExtent: root.discRingExtent
                        barGain: 2.85
                        barCount: 48
                        barColor: WallustColors.sapphire
                        opacity: 1
                        playing: root.player?.isPlaying ?? false

                            Item {
                                width: discViz.discDiameter
                                height: discViz.discDiameter
                                anchors.centerIn: parent

                                Item {
                                    id: discRoot
                                    anchors.fill: parent
                                    transformOrigin: Item.Center

                                    property bool artReady: coverImg.status === Image.Ready
                                        && (root.coverArtUrl?.length > 0)

                            Image {
                                id: coverImg
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                source: root.coverArtUrl
                                visible: discRoot.artReady
                                layer.enabled: true
                                layer.smooth: true
                                layer.effect: OpacityMask {
                                    maskSource: Item {
                                        width: coverImg.width
                                        height: coverImg.height
                                        Rectangle {
                                    anchors.fill: parent
                                    radius: width / 2
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                visible: !discRoot.artReady
                                color: Qt.rgba(0.08, 0.09, 0.12, 1)

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰎈"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 44
                                    color: WallustColors.buttonHover
                                }
                            }

                                    NumberAnimation on rotation {
                                        running: root.player?.isPlaying ?? false
                                        loops: Animation.Infinite
                                        from: discRoot.rotation
                                        to: discRoot.rotation + 360
                                        duration: 26000
                                    }
                                }
                            }
                        }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: root.discColumnW
                        Layout.maximumWidth: root.discColumnW
                        Layout.minimumWidth: root.discColumnW
                        spacing: 4

                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: StringUtils.cleanMusicTitle(root.player?.trackTitle) || "Unknown title"
                            color: WallustColors.moduleText
                            font.family: SamaelStyle.fontFamily
                            font.pixelSize: SamaelStyle.fontPixelSize + 3
                            font.bold: true
                            elide: Text.ElideRight
                            maximumLineCount: 2
                            wrapMode: Text.Wrap
                        }
                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: root.player?.trackArtist || "Unknown artist"
                            color: WallustColors.sapphire
                            font.family: SamaelStyle.fontFamily
                            font.pixelSize: SamaelStyle.fontPixelSize + 1
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: root.player?.trackAlbum || "Unknown album"
                            color: WallustColors.buttonHover
                            font.family: SamaelStyle.fontFamily
                            font.pixelSize: SamaelStyle.fontPixelSize
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            Layout.topMargin: 2
                            text: (root.player?.identity || root.player?.dbusName || "").replace(/^org\.mpris\.MediaPlayer2\./, "")
                            color: WallustColors.buttonHover
                            font.family: SamaelStyle.fontFamily
                            font.pixelSize: SamaelStyle.fontPixelSize - 2
                            elide: Text.ElideRight
                        }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: 10
                                spacing: 6

                                Text {
                                    readonly property real pos: root.player?.position ?? 0
                                    text: root.lengthStr(pos)
                                    color: WallustColors.buttonHover
                                    font.family: SamaelStyle.fontFamily
                                    font.pixelSize: SamaelStyle.fontPixelSize - 1
                                    Layout.preferredWidth: 40
                                }

                                Slider {
                                    id: seekSlider
                                    Layout.fillWidth: true
                                    focusPolicy: Qt.NoFocus
                                    activeFocusOnTab: false
                                    from: 0
                                    to: 1
                                    stepSize: 0.001
                                    enabled: root.player?.canSeek ?? false
                                    property real trackProgress: {
                                        const len = root.player?.length ?? 0
                                        if (len <= 0)
                                            return 0
                                        return (root.player.position % len) / len
                                    }
                                    value: pressed ? value : trackProgress
                                    onPressedChanged: {
                                        if (!pressed && root.player?.canSeek && root.player.positionSupported) {
                                            const len = root.player.length || 1
                                            root.player.position = value * len
                                        }
                                    }
                                    background: Rectangle {
                                        x: seekSlider.leftPadding
                                        y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                                        implicitWidth: 120
                                        implicitHeight: 4
                                        width: seekSlider.availableWidth
                                        height: implicitHeight
                                        radius: 2
                                        color: Qt.rgba(0, 0, 0, 0.4)
                                        Rectangle {
                                            width: seekSlider.visualPosition * parent.width
                                            height: parent.height
                                            radius: 2
                                            color: WallustColors.sapphire
                                        }
                                    }
                                    handle: Rectangle {
                                        x: seekSlider.leftPadding + seekSlider.visualPosition * (seekSlider.availableWidth - width)
                                        y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                                        implicitWidth: 12
                                        implicitHeight: 12
                                        radius: 6
                                        color: WallustColors.moduleText
                                    }
                                }

                                Text {
                                    text: root.lengthStr(root.player?.length ?? -1)
                                    color: WallustColors.buttonHover
                                    font.family: SamaelStyle.fontFamily
                                    font.pixelSize: SamaelStyle.fontPixelSize - 1
                                    Layout.preferredWidth: 40
                                    horizontalAlignment: Text.AlignRight
                                }
                            }

                                    Item {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 52
                                        Layout.topMargin: 4

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 6

                                            MediaBtn {
                                                keyboardFocused: root.controlFocus === 0
                                                glyph: "󰒯"
                                                small: true
                                                toggled: root.player?.shuffle ?? false
                                                enabled: root.player?.shuffleSupported ?? false
                                                onActivated: root.toggleShuffle()
                                            }
                                            MediaBtn {
                                                keyboardFocused: root.controlFocus === 1
                                                glyph: "󰒮"
                                                enabled: root.player?.canGoPrevious ?? false
                                                onActivated: root.player?.previous()
                                            }
                                            MediaBtn {
                                                width: 52
                                                height: 52
                                                keyboardFocused: root.controlFocus === 2
                                                glyph: root.player?.isPlaying ? "󰏤" : "󰐊"
                                                large: true
                                                enabled: root.player?.canTogglePlaying ?? false
                                                onActivated: root.player?.togglePlaying()
                                            }
                                            MediaBtn {
                                                keyboardFocused: root.controlFocus === 3
                                                glyph: "󰒭"
                                                enabled: root.player?.canGoNext ?? false
                                                onActivated: root.player?.next()
                                            }
                                            MediaBtn {
                                                keyboardFocused: root.controlFocus === 4
                                                glyph: root.player?.loopState === MprisLoopState.Track ? "󰑖" : "󰑐"
                                                small: true
                                                toggled: root.player?.loopState === MprisLoopState.Track
                                                    || root.player?.loopState === MprisLoopState.Playlist
                                                enabled: root.player?.loopSupported ?? false
                                                onActivated: root.cycleLoopState()
                                            }
                                        }
                                    }
                        }
                    }
                }
            }
    }

    component MediaBtn: Rectangle {
        id: btn
        property string glyph: ""
        property string glyphAlt: ""
        property bool useAlt: false
        property bool large: false
        property bool small: false
        property bool toggled: false
        property bool keyboardFocused: false
        signal activated()
        implicitWidth: large ? 52 : (small ? 34 : 40)
        implicitHeight: large ? 52 : (small ? 34 : 40)
        radius: large ? 26 : (small ? 17 : 10)
        color: toggled ? Qt.rgba(WallustColors.sapphire.r, WallustColors.sapphire.g, WallustColors.sapphire.b, 0.35) : (btnMa.containsMouse || keyboardFocused ? WallustColors.buttonHover : Qt.rgba(0, 0, 0, 0.28))
        border.width: keyboardFocused ? 2 : 1
        border.color: keyboardFocused ? WallustColors.sapphire : (toggled ? WallustColors.sapphire : WallustColors.borderColor)
        opacity: enabled ? 1 : 0.35

        Text {
            anchors.centerIn: parent
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: btn.useAlt && btn.glyphAlt.length ? btn.glyphAlt : btn.glyph
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: large ? 22 : 18
            color: WallustColors.moduleText
        }

        MouseArea {
            id: btnMa
            anchors.fill: parent
            hoverEnabled: true
            enabled: btn.enabled
            onClicked: btn.activated()
        }
    }

    Keys.onPressed: event => {
        const text = event.text
        if (event.key === Qt.Key_Escape) {
            closePanel()
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Tab) {
            cyclePlayer(event.modifiers & Qt.ShiftModifier ? -1 : 1)
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Space) {
            seekSlider.focus = false
            root.forceActiveFocus()
            root.player?.togglePlaying()
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            activateFocusedControl()
            event.accepted = true
            return
        }
        if (text === "s") {
            toggleShuffle()
            event.accepted = true
            return
        }
            if (text === "r") {
                cycleLoopState()
                event.accepted = true
                return
            }
        if (text === "h") {
            root.player?.previous()
            event.accepted = true
            return
        }
            if (text === "L" || text === "y") {
                if (useCaelestiaMediaSkin)
                    caelestiaLyricsVisible = !caelestiaLyricsVisible
                event.accepted = true
                return
            }
            if (text === "l") {
                root.player?.next()
                event.accepted = true
                return
            }
        if (event.key === Qt.Key_Left) {
            moveControlFocus(-1)
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Right) {
            moveControlFocus(1)
            event.accepted = true
            return
        }
            if (text === "j" || event.key === Qt.Key_Down) {
                if (useCaelestiaMediaSkin && caelestiaLyricsVisible)
                    caelestiaMediaSkin.stepLyrics(1)
                else
                    seekBy(seekStepSec)
                event.accepted = true
                return
            }
            if (text === "k" || event.key === Qt.Key_Up) {
                if (useCaelestiaMediaSkin && caelestiaLyricsVisible)
                    caelestiaMediaSkin.stepLyrics(-1)
                else
                    seekBy(-seekStepSec)
                event.accepted = true
            }
    }

    Connections {
        target: MprisController
        function onPlayersChanged() {
            SamaelPlayers.reconcileSelection()
        }
    }

    Connections {
        target: GlobalStates
        function onMediaControlsOpenChanged() {
                if (GlobalStates.mediaControlsOpen) {
                    Qt.callLater(() => {
                        const h = bodyLayout.implicitHeight + 32
                        if (h > 80)
                            root.bodyHeightLock = h
                        root.forceActiveFocus()
                    })
                } else {
                root.bodyHeightLock = 0
                root.focus = false
            }
        }
    }
}