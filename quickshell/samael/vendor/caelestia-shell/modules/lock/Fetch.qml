pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.effects
import Quickshell
import qs.services
import qs.utils
import qs.modules.samael

StyledRect {
    id: root

    required property real rootHeight
    readonly property int cBoxSize: Tokens.font.body.medium.pointSize * 2
    readonly property int logoSide: Math.max(32, Tokens.font.body.medium.pointSize * 2.8)

    implicitHeight: layout.implicitHeight + layout.anchors.topMargin + layout.anchors.margins
    radius: Tokens.rounding.medium
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.extraLarge
        anchors.topMargin: Tokens.padding.extraLarge
        anchors.bottomMargin: Tokens.padding.extraLarge

        spacing: Tokens.spacing.small

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            spacing: Tokens.spacing.medium

            StyledRect {
                implicitWidth: prompt.implicitWidth + Tokens.padding.medium * 2
                implicitHeight: prompt.implicitHeight + Tokens.padding.small * 2

                color: Colours.palette.m3primary
                radius: Tokens.rounding.medium

                MonoText {
                    id: prompt

                    anchors.centerIn: parent
                    text: ">"
                    color: Colours.palette.m3onPrimary
                }
            }

            MonoText {
                Layout.fillWidth: true
                text: "caelestiafetch.sh"
                elide: Text.ElideRight
                color: WallustColors.foreground
            }

            WrappedLoader {
                Layout.preferredWidth: root.logoSide
                Layout.preferredHeight: root.logoSide
                active: !iconLoader.active

                sourceComponent: SysInfo.isDefaultLogo ? caelestiaLogo : distroIcon
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Tokens.spacing.extraLarge

            WrappedLoader {
                id: iconLoader

                Layout.preferredWidth: root.logoSide * 2.2
                Layout.preferredHeight: root.logoSide * 2.2
                Layout.alignment: Qt.AlignVCenter
                active: root.width > Math.min(Tokens.sizes.lock.largeLogoWidth, 200)

                sourceComponent: SysInfo.isDefaultLogo ? caelestiaLogo : distroIcon
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.padding.medium
                Layout.bottomMargin: iconLoader.active || colourRowLoader.active ? Tokens.padding.medium : 0
                spacing: Tokens.spacing.medium

                Repeater {
                    model: root.fetchLines

                    MonoText {
                        required property string modelData

                        Layout.fillWidth: true
                        text: modelData
                        elide: Text.ElideRight
                    }
                }
            }
        }

        WrappedLoader {
            id: colourRowLoader

            Layout.topMargin: iconLoader.active ? Tokens.spacing.small : 0
            Layout.alignment: Qt.AlignHCenter
            active: root.rootHeight > Tokens.sizes.lock.showColourBoxRowHeight

            sourceComponent: RowLayout {
                id: coloursRow

                spacing: Tokens.spacing.largeIncreased

                Repeater {
                    model: CUtils.clamp(Math.floor((layout.width + coloursRow.spacing) / (root.cBoxSize + coloursRow.spacing)), 0, 8)

                    StyledRect {
                        required property int index

                        implicitWidth: implicitHeight
                        implicitHeight: root.cBoxSize
                        color: Colours.palette[`term${index}`]
                        radius: Tokens.rounding.medium
                    }
                }
            }
        }
    }

    readonly property var fetchLines: {
        const items = [];
        const os = SysInfo.osPrettyName || SysInfo.osName || "";
        const wm = SysInfo.wm || Quickshell.env("XDG_CURRENT_DESKTOP") || (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") ? "Hyprland" : "");
        const user = SysInfo.user || Quickshell.env("USER") || "—";
        const up = SysInfo.uptime || "…";
        items.push(`OS  : ${os || "—"}`);
        items.push(`WM  : ${wm || "—"}`);
        items.push(`USER: ${user}`);
        items.push(`UP  : ${up}`);
        if (UPower.displayDevice.isLaptopBattery) {
            const charging = [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state);
            const pct = Math.round(UPower.displayDevice.percentage * 100);
            items.push(`BATT: ${charging ? "(+) " : ""}${pct}%`);
        }
        return items;
    }

    Component {
        id: caelestiaLogo

        Logo {
            anchors.fill: parent
            topColour: WallustColors.sapphire
            bottomColour: WallustColors.foreground
        }
    }

    Component {
        id: distroIcon

        ColouredIcon {
            anchors.fill: parent
            source: SysInfo.osLogo
            implicitSize: Math.min(parent.width, parent.height)
            colour: WallustColors.sapphire
            layer.enabled: Config.lock.recolourLogo
        }
    }

    component WrappedLoader: Loader {
        asynchronous: true
        visible: active
    }

    component MonoText: StyledText {
        color: WallustColors.foreground
        font: root.width > Tokens.sizes.lock.largeFontWidth ? Tokens.font.mono.medium : Tokens.font.mono.small
    }
}
