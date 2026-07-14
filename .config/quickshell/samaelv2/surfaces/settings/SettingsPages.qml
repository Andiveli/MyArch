import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../singletons"
import "../../widgets/settings"

ColumnLayout {
    id: root

    property string pageId: "general"
    readonly property int _rev: ShellConfigService.revision

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

    Loader {
        Layout.fillWidth: true
        Layout.preferredWidth: root.width
        sourceComponent: root.pageId === "bar" ? barComp
            : root.pageId === "surfaces" ? surfacesComp
            : root.pageId === "lyrics" ? lyricsComp
            : root.pageId === "wallpaper" ? wallpaperComp
            : root.pageId === "audio" ? audioComp
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
        id: wallpaperComp
        ColumnLayout {
            width: root.width
            spacing: 2
            SettingsSectionHeader { first: true; text: "WALLPAPER" }
            SettingsConnectedRow {
                first: true; last: true
                implicitHeight: wField.implicitHeight + 20
                ColumnLayout {
                    width: parent.width
                    spacing: 4
                    Text {
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
            width: root.width
            spacing: 8
            SettingsSectionHeader { first: true; text: "AUDIO" }
            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Per-app output routing (Spotify → BT, browser → laptop speakers) will live here. PipeWire sink-input list + rules in config.json — next slice."
                color: WallustColors.moduleText
                opacity: 0.65
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize
                lineHeight: 1.35
            }
        }
    }
}