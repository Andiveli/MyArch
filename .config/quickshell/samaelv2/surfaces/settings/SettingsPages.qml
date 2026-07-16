import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../singletons"
import "../../widgets/settings"

ColumnLayout {
    id: root

    property string pageId: "general"
    readonly property int _rev: ShellConfigService.revision
    /** Keybinds drill toggled — SettingsSurface refreshes flickable height / rows. */
    signal keybindLayoutChanged()
    signal audioLayoutChanged()

    width: parent ? parent.width : 400
    spacing: 2

    function surfaceSizeKeys() {
        return [
            { zone: "middle", name: "media" },
            { zone: "middle", name: "launcher" },
            { zone: "middle", name: "wifi" },
            { zone: "middle", name: "bluetooth" },
            { zone: "middle", name: "calendar" },
            { zone: "left", name: "notifications" },
            { zone: "right", name: "overview" }
        ]
    }

    function readSurfaceSize(zone, name) {
        const _r = _rev
        const base = zone === "middle" ? ["middle", "surfaces", name]
            : zone === "left" ? ["left", "surfaces", name] : ["right", "surfaces", name]
        const w = ShellConfigService.getDraftPath(base.concat(["width"]), 360)
        const h = ShellConfigService.getDraftPath(base.concat(["height"]), 280)
        return { w: Number(w) || 360, h: Number(h) || 280 }
    }

    function writeSurfaceSize(zone, name, w, h) {
        const base = zone === "middle" ? ["middle", "surfaces", name]
            : zone === "left" ? ["left", "surfaces", name] : ["right", "surfaces", name]
        let sur = ShellConfigService.getDraftPath(base.slice(0, 2), {})
        if (typeof sur !== "object" || sur === null)
            sur = {}
        const copy = JSON.parse(JSON.stringify(sur))
        if (!copy[name] || typeof copy[name] !== "object")
            copy[name] = {}
        copy[name].width = w
        copy[name].height = h
        ShellConfigService.setDraftPath(base.slice(0, 2), copy)
    }

    function clearKeybindDrill() {
        if (root.pageId !== "keybinds" || !pageContentLoader.item)
            return false
        const kb = pageContentLoader.item
        if (!kb.keyDrillId || !kb.keyDrillId.length)
            return false
        kb.keyDrillId = ""
        root.keybindLayoutChanged()
        return true
    }

    function keybindDrillActive() {
        return root.pageId === "keybinds" && pageContentLoader.item
            && pageContentLoader.item.keyDrillId
            && pageContentLoader.item.keyDrillId.length > 0
    }

    function clearAudioOutputPicker() {
        if (root.pageId !== "audio" || !pageContentLoader.item)
            return false
        const host = pageContentLoader.item
        if (!host.outputPickerStreamId || !host.outputPickerStreamId.length)
            return false
        host.outputPickerStreamId = ""
        root.audioLayoutChanged()
        return true
    }

    Loader {
        id: pageContentLoader
        Layout.fillWidth: true
        Layout.preferredWidth: root.width
        sourceComponent: root.pageId === "bar" ? barComp
            : root.pageId === "surfaces" ? surfacesComp
            : root.pageId === "lyrics" ? lyricsComp
            : root.pageId === "wallpaper" ? wallpaperComp
            : root.pageId === "videos" ? videosComp
            : root.pageId === "audio" ? audioComp
            : root.pageId === "keybinds" ? keybindsComp
            : generalComp
    }

    Component {
        id: generalComp
        ColumnLayout {
            width: root.width
            spacing: 2
            SettingsSectionHeader { first: true; text: "LOCK" }
            SettingsToggleRow {
                first: true; last: true
                label: "Lock preview UI"
                subtext: "Overlay only — no PAM (Esc closes)"
                checked: ShellConfigService.getDraftPath(["lock", "previewUi"], false) === true
                onToggled: v => ShellConfigService.setDraftPath(["lock", "previewUi"], v)
            }
            SettingsSectionHeader { text: "BAR" }
            SettingsToggleRow {
                first: true; last: true
                label: "Bar enabled"
                subtext: "Off = no widgets, no cava process"
                checked: ShellConfigService.getDraftPath(["bar", "enabled"], true) !== false
                onToggled: v => ShellConfigService.setDraftPath(["bar", "enabled"], v)
            }
        }
    }

    Component {
        id: barComp
        ColumnLayout {
            width: root.width
            spacing: 2
            SettingsSectionHeader { first: true; text: "MARGINS" }
            SettingsStepperRow {
                first: true
                label: "Margin top"
                value: ShellConfigService.getDraftPath(["bar", "marginTop"], 8)
                from: 0; to: 48; step: 1
                onMoved: v => ShellConfigService.setDraftPath(["bar", "marginTop"], v)
            }
            SettingsStepperRow {
                label: "Margin left"
                value: ShellConfigService.getDraftPath(["bar", "marginLeft"], 12)
                from: 0; to: 48; step: 1
                onMoved: v => ShellConfigService.setDraftPath(["bar", "marginLeft"], v)
            }
            SettingsStepperRow {
                last: true
                label: "Margin right"
                value: ShellConfigService.getDraftPath(["bar", "marginRight"], 12)
                from: 0; to: 48; step: 1
                onMoved: v => ShellConfigService.setDraftPath(["bar", "marginRight"], v)
            }
            SettingsSectionHeader { text: "WIDGETS · LEFT" }
            Repeater {
                model: ShellConfigService.barWidgetIds
                delegate: SettingsToggleRow {
                    required property string modelData
                    required property int index
                    first: index === 0
                    last: index === ShellConfigService.barWidgetIds.length - 1
                    label: modelData
                    checked: ShellConfigService.hasBarWidget("left", modelData)
                    onToggled: ShellConfigService.toggleBarWidget("left", modelData)
                }
            }
            SettingsSectionHeader { text: "WIDGETS · MIDDLE" }
            Repeater {
                model: ShellConfigService.barWidgetIds
                delegate: SettingsToggleRow {
                    required property string modelData
                    required property int index
                    first: index === 0
                    last: index === ShellConfigService.barWidgetIds.length - 1
                    label: modelData
                    checked: ShellConfigService.hasBarWidget("middle", modelData)
                    onToggled: ShellConfigService.toggleBarWidget("middle", modelData)
                }
            }
            SettingsSectionHeader { text: "WIDGETS · RIGHT" }
            Repeater {
                model: ShellConfigService.barWidgetIds
                delegate: SettingsToggleRow {
                    required property string modelData
                    required property int index
                    first: index === 0
                    last: index === ShellConfigService.barWidgetIds.length - 1
                    label: modelData
                    checked: ShellConfigService.hasBarWidget("right", modelData)
                    onToggled: ShellConfigService.toggleBarWidget("right", modelData)
                }
            }
        }
    }

    Component {
        id: surfacesComp
        ColumnLayout {
            width: root.width
            spacing: 2
            SettingsSectionHeader { first: true; text: "PANEL SIZES" }
            Repeater {
                model: root.surfaceSizeKeys()
                delegate: ColumnLayout {
                    required property var modelData
                    required property int index
                    readonly property var sz: root.readSurfaceSize(modelData.zone, modelData.name)
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        Layout.fillWidth: true
                        text: modelData.zone + " · " + modelData.name
                        color: WallustColors.moduleText
                        opacity: 0.7
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize - 1
                        topPadding: index === 0 ? 0 : 6
                    }
                    SettingsStepperRow {
                        first: true
                        label: "Width"
                        value: sz.w
                        from: 200; to: 1200; step: 10
                        onMoved: v => root.writeSurfaceSize(modelData.zone, modelData.name, v, sz.h)
                    }
                    SettingsStepperRow {
                        last: true
                        label: "Height"
                        value: sz.h
                        from: 80; to: 800; step: 10
                        onMoved: v => root.writeSurfaceSize(modelData.zone, modelData.name, sz.w, v)
                    }
                }
            }
            SettingsSectionHeader { text: "MIDDLE REST" }
            SettingsStepperRow {
                first: true; last: true
                label: "Rest height"
                subtext: "Collapsed middle pill height"
                value: ShellConfigService.getDraftPath(["middle", "restHeight"], 30)
                from: 24; to: 80; step: 2
                onMoved: v => ShellConfigService.setDraftPath(["middle", "restHeight"], v)
            }
        }
    }

    Component {
        id: lyricsComp
        ColumnLayout {
            width: root.width
            spacing: 2
            SettingsSectionHeader { first: true; text: "LYRICS" }
            SettingsConnectedRow {
                first: true; last: true
                implicitHeight: pathField.implicitHeight + 20
                ColumnLayout {
                    width: parent.width
                    spacing: 4
                    Text {
                        text: "Directory (empty = default)"
                        color: WallustColors.moduleText
                        opacity: 0.55
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize - 2
                    }
                    TextField {
                        id: pathField
                        Layout.fillWidth: true
                        text: ShellConfigService.getDraftPath(["lyrics", "dir"], "")
                        color: WallustColors.moduleText
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize
                        placeholderText: "~/Music/Lyrics"
                        onTextEdited: ShellConfigService.setDraftPath(["lyrics", "dir"], text)
                        background: Rectangle {
                            radius: 6
                            color: Qt.rgba(0, 0, 0, 0.25)
                            border.color: WallustColors.borderColor
                        }
                    }
                }
            }
            SettingsStepperRow {
                label: "Panel width"
                value: ShellConfigService.getDraftPath(["lyrics", "panelWidth"], 220)
                from: 120; to: 480; step: 10
                onMoved: v => ShellConfigService.setDraftPath(["lyrics", "panelWidth"], v)
            }
            SettingsStepperRow {
                last: true
                label: "Time offset (sec)"
                value: Math.round(ShellConfigService.getDraftPath(["lyrics", "timeOffsetSec"], 0) * 10) / 10
                from: -30; to: 30; step: 1
                onMoved: v => ShellConfigService.setDraftPath(["lyrics", "timeOffsetSec"], v)
            }
        }
    }

    Component {
        id: videosComp
        ColumnLayout {
            width: root.width
            spacing: 2
            SettingsSectionHeader { first: true; text: "SCREEN RECORD" }
            Text {
                Layout.fillWidth: true
                Layout.bottomMargin: 4
                text: "Tab complete · ↑↓ pick · Esc back · s save when not editing · ~ for home"
                wrapMode: Text.WordWrap
                color: WallustColors.moduleText
                opacity: 0.38
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize - 3
            }
            SettingsPathFieldRow {
                first: true
                last: false
                label: "Save folder"
                placeholder: "~/Videos"
                pathKey: ["record", "saveDir"]
                defaultValue: "~/Videos"
            }
            SettingsToggleRow {
                first: false
                last: false
                label: "Include system audio"
                subtext: "Default sink when recording starts"
                checked: ShellConfigService.getDraftPath(["record", "includeSystemAudio"], true) !== false
                onToggled: v => ShellConfigService.setDraftPath(["record", "includeSystemAudio"], v)
            }
            SettingsToggleRow {
                first: false
                last: true
                label: "Include microphone"
                subtext: "Default mic when recording starts"
                checked: ShellConfigService.getDraftPath(["record", "includeMic"], false) === true
                onToggled: v => ShellConfigService.setDraftPath(["record", "includeMic"], v)
            }
        }
    }

    Component {
        id: wallpaperComp
        ColumnLayout {
            width: root.width
            spacing: 2
            SettingsSectionHeader { first: true; text: "WALLPAPER" }
            SettingsConnectedRow {
                first: true; last: true
                implicitHeight: wCol.implicitHeight + 14
                ColumnLayout {
                    id: wCol
                    width: parent.width
                    spacing: 6
                    Text {
                        Layout.fillWidth: true
                        text: "Wallpaper folder"
                        color: WallustColors.moduleText
                        opacity: 0.55
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize - 2
                    }
                    TextField {
                        id: wField
                        Layout.fillWidth: true
                        text: ShellConfigService.getDraftPath(["wallpaper", "dir"], "")
                        color: WallustColors.moduleText
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize
                        onTextEdited: ShellConfigService.setDraftPath(["wallpaper", "dir"], text)
                        background: Rectangle {
                            radius: 6
                            color: Qt.rgba(0, 0, 0, 0.25)
                            border.color: WallustColors.borderColor
                        }
                    }
                }
            }
        }
    }

    Component {
        id: audioComp
        ColumnLayout {
            id: audioCol
            width: root.width
            spacing: 4

            property string outputPickerStreamId: ""
            readonly property int _ar: AudioRouteService.revision

            function toggleOutputPicker(id) {
                const sid = String(id)
                outputPickerStreamId = (outputPickerStreamId === sid) ? "" : sid
                root.audioLayoutChanged()
            }

            onOutputPickerStreamIdChanged: root.audioLayoutChanged()

            Connections {
                target: root
                function onPageIdChanged() {
                    if (root.pageId === "audio")
                        AudioRouteService.refresh()
                }
            }
            Connections {
                target: AudioRouteService
                function onRevisionChanged() {
                    if (root.pageId === "audio")
                        Qt.callLater(root.audioLayoutChanged)
                }
            }

            Component.onCompleted: {
                if (root.pageId === "audio")
                    AudioRouteService.refresh()
            }

            SettingsSectionHeader { first: true; text: "STREAMS" }

            Repeater {
                id: streamRep
                model: AudioRouteService.streams
                delegate: ColumnLayout {
                    required property int index
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 0

                    readonly property string sid: String(modelData.id || "")
                    readonly property bool menuOpen: audioCol.outputPickerStreamId === sid

                    SettingsAudioStreamRow {
                        Layout.fillWidth: true
                        first: index === 0
                        last: !menuOpen && index === streamRep.count - 1
                        stream: modelData
                        outputMenuOpen: menuOpen
                        onToggleOutputMenu: audioCol.toggleOutputPicker(sid)
                    }

                    Repeater {
                        id: outPickRep
                        model: menuOpen ? AudioRouteService.sinks : []
                        delegate: SettingsAudioOutputPickRow {
                            required property int index
                            required property var modelData
                            Layout.fillWidth: true
                            first: false
                            last: index === outPickRep.count - 1
                                && parent.index === streamRep.count - 1
                            sink: modelData
                            streamId: parent.sid
                            activeSinkId: String(parent.modelData.sinkId || "")
                        }
                    }
                }
            }

            SettingsAudioActionRow {
                Layout.fillWidth: true
                label: AudioRouteService.loading ? "Refreshing…" : "Refresh"
                onActivated: AudioRouteService.refresh()
            }
        }
    }

    Component {
        id: keybindsComp
        Item {
            id: kbHost
            width: root.width
            implicitHeight: kbColumn.implicitHeight
            property string keyDrillId: ""

            onKeyDrillIdChanged: {
                kbColumn.implicitHeightChanged()
                root.keybindLayoutChanged()
            }

            ColumnLayout {
                id: kbColumn
                width: parent.width
                spacing: 2
                onImplicitHeightChanged: root.implicitHeightChanged()

                SettingsSectionHeader {
                    first: true
                    text: kbHost.keyDrillId.length ? ("INSIDE · " + KeybindCatalog.insideTitle(kbHost.keyDrillId).toUpperCase()) : "REFERENCE"
                }

                SettingsConnectedRow {
                    visible: !kbHost.keyDrillId.length
                    first: true
                    last: true
                    implicitHeight: refNote.implicitHeight + 16
                    Text {
                        id: refNote
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: "Hypr keybinds.lua + samaelv2 pill keys (read-only). Open Surfaces → l/Enter for keys inside each menu."
                        color: WallustColors.moduleText
                        opacity: 0.6
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize - 2
                        lineHeight: 1.35
                    }
                }

                SettingsKeybindBackRow {
                    visible: kbHost.keyDrillId.length > 0
                    Layout.fillWidth: true
                    first: true
                    onBackRequested: {
                        kbHost.keyDrillId = ""
                    }
                }

                // --- drilled: inside keys only ---
                Repeater {
                    id: insideKbRep
                    visible: kbHost.keyDrillId.length > 0
                    model: kbHost.keyDrillId.length ? KeybindCatalog.insideEntries(kbHost.keyDrillId) : []

                    delegate: SettingsKeybindRow {
                        required property int index
                        required property var modelData
                        Layout.fillWidth: true
                        first: index === 0
                        last: index === insideKbRep.count - 1
                        keys: modelData.keys || ""
                        action: modelData.action || ""
                    }
                }

                // --- top level ---
                ColumnLayout {
                    visible: !kbHost.keyDrillId.length
                    Layout.fillWidth: true
                    spacing: 2

                    SettingsSectionHeader { text: "APPLICATIONS" }
                    Repeater {
                        id: appKbRep
                        model: KeybindCatalog.appEntries
                        delegate: SettingsKeybindRow {
                            required property int index
                            required property var modelData
                            Layout.fillWidth: true
                            first: index === 0
                            last: index === appKbRep.count - 1
                            keys: modelData.keys || ""
                            action: modelData.action || ""
                        }
                    }

                    SettingsSectionHeader { text: "OPEN SURFACES" }
                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: "Hypr → Quickshell · l/Enter → keys inside the pill"
                        color: WallustColors.moduleText
                        opacity: 0.45
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize - 2
                        leftPadding: 4
                    }
                    Repeater {
                        id: surfaceKbRep
                        model: KeybindCatalog.surfaceOpenRows
                        delegate: SettingsKeybindDrillRow {
                            required property int index
                            required property var modelData
                            Layout.fillWidth: true
                            first: index === 0
                            last: index === surfaceKbRep.count - 1
                            keys: modelData.keys || ""
                            action: modelData.action || ""
                            drillId: modelData.drillId || ""
                            onDrillRequested: id => {
                                kbHost.keyDrillId = id
                            }
                        }
                    }

                    SettingsSectionHeader { text: "TOOLS & OTHER" }
                    Repeater {
                        id: toolKbRep
                        model: KeybindCatalog.toolEntries
                        delegate: SettingsKeybindRow {
                            required property int index
                            required property var modelData
                            Layout.fillWidth: true
                            first: index === 0
                            last: index === toolKbRep.count - 1
                            keys: modelData.keys || ""
                            action: modelData.action || ""
                        }
                    }
                }
            }

        }
    }
}