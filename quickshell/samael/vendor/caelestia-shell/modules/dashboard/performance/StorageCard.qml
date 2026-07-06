import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    property bool compactLayout: false

    readonly property color accent: Colours.palette.m3secondary
    readonly property real percentage: Storage.primaryDisk?.perc ?? 0
    readonly property real compactInnerW: compactLayout
        ? Math.max(0, width - Tokens.padding.large * 2)
        : 0

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.extraExtraLarge
    clip: compactLayout

    implicitWidth: compactLayout
        ? Math.max(0, parent ? parent.width : 0)
        : layout.implicitWidth + layout.anchors.margins * 2
    width: compactLayout && parent ? parent.width : implicitWidth
    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2

    ServiceRef {
        service: Storage
    }

    ColumnLayout {
        id: layout

        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: compactLayout ? Tokens.padding.large : Tokens.padding.extraLarge
        anchors.horizontalCenter: compactLayout ? parent.horizontalCenter : undefined
        anchors.left: compactLayout ? undefined : parent.left
        anchors.right: compactLayout ? undefined : parent.right
        width: compactLayout ? Math.min(implicitWidth, parent.width - anchors.margins * 2) : undefined
        spacing: compactLayout ? Tokens.spacing.small : 0

        RowLayout {
            id: row

            Layout.fillWidth: !compactLayout
            Layout.alignment: Qt.AlignHCenter
            spacing: compactLayout ? Tokens.spacing.medium : Tokens.spacing.large

            CircularProgress {
                fgColour: root.accent
                value: root.percentage
                implicitSize: compactLayout ? 72 : usageColumn.implicitHeight + thickness + Tokens.padding.large * 2
                startAngle: -225
                sweepAngle: 270

                Behavior on clampedVal {
                    Anim {}
                }

                ColumnLayout {
                    id: usageColumn

                    anchors.centerIn: parent
                    spacing: 0

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "hard_drive"
                        color: root.accent
                        fontStyle: compactLayout ? Tokens.font.icon.small : Tokens.font.icon.medium
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Math.round(root.percentage * 100) + "%"
                        font: compactLayout
                            ? Tokens.font.title.medium
                            : Tokens.font.title.builders.large.width(90).build()
                        color: root.accent
                    }

                    StyledText {
                        visible: !compactLayout
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Used")
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: !compactLayout
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: compactLayout ? compactInnerW - 80 : -1
                Layout.minimumWidth: compactLayout ? 0 : Tokens.sizes.dashboard.perfStorageTextWidth
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("Storage")
                    font: Tokens.font.title.medium
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: {
                        if (!Storage.primaryDisk)
                            return qsTr("No disks detected");

                        const fmt = UsageFmt.formatKib(Storage.primaryDisk.used, Storage.primaryDisk.total);
                        return `${+fmt.value.toFixed(1)} / ${+fmt.total.toFixed(1)} ${fmt.unit}`;
                    }
                    font: compactLayout ? Tokens.font.body.medium : Tokens.font.body.large
                    color: root.accent
                    elide: Text.ElideRight
                }
            }
        }

        Item {
            Layout.fillWidth: !compactLayout
            Layout.preferredWidth: compactLayout ? splitBtn.implicitWidth : splitBtn.implicitWidth
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: splitBtn.implicitWidth
            implicitHeight: splitBtn.implicitHeight
            width: implicitWidth
            height: implicitHeight
            clip: true

            SplitButton {
                id: splitBtn
                anchors.centerIn: parent
                width: compactLayout ? Math.min(implicitWidth, root.width - layout.anchors.margins * 2) : implicitWidth

                type: SplitButton.Tonal
                disabled: !Storage.disks.length
                fallbackIcon: "storage"
                fallbackText: qsTr("No disks")
                menuOnTop: true
                minLeftWidth: compactLayout ? 0 : row.implicitWidth * 0.6

                menuItems: disks.instances
                active: menuItems.find(m => m.modelData === Storage.primaryDisk) ?? menuItems[0] ?? null
                menu.onItemSelected: item => Storage.manualPrimaryDisk = (item as DiskItem).modelData

                Variants {
                    id: disks

                    model: Storage.disks

                    DiskItem {}
                }
            }
        }
    }

    component DiskItem: MenuItem {
        required property var modelData

        icon: modelData === Storage.primaryDisk ? "check" : ""
        text: modelData.mount
        activeIcon: "storage"
    }
}