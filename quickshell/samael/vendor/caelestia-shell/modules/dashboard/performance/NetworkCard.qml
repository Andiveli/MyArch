import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.Internal
import qs.components
import qs.components.misc
import qs.services

StyledRect {
    id: root

    property bool compactLayout: false

    readonly property string downloadSpeedText: {
        const fmt = NetworkUsage.formatBytes(NetworkUsage.downloadSpeed ?? 0);
        return fmt ? `${fmt.value.toFixed(1)} ${fmt.unit}` : "0.0 B/s";
    }
    readonly property string uploadSpeedText: {
        const fmt = NetworkUsage.formatBytes(NetworkUsage.uploadSpeed ?? 0);
        return fmt ? `${fmt.value.toFixed(1)} ${fmt.unit}` : "0.0 B/s";
    }
    readonly property string sessionTotalText: {
        const down = NetworkUsage.formatBytesTotal(NetworkUsage.downloadTotal ?? 0);
        const up = NetworkUsage.formatBytesTotal(NetworkUsage.uploadTotal ?? 0);
        return (down && up) ? `↓${down.value.toFixed(1)}${down.unit} ↑${up.value.toFixed(1)}${up.unit}` : "↓0.0B ↑0.0B";
    }

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.extraLarge

        implicitWidth: compactLayout ? Math.max(0, parent ? parent.width : 0) : Tokens.sizes.dashboard.perfNetworkCardWidth
        width: compactLayout && parent ? parent.width : implicitWidth
        implicitHeight: compactLayout
            ? compactBarLayout.implicitHeight + Tokens.padding.large + Tokens.padding.medium
            : Tokens.sizes.dashboard.perfNetworkCardHeight
        height: implicitHeight

    Ref {
        service: NetworkUsage
    }

    Item {
        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        anchors.bottomMargin: Tokens.padding.medium

        // Dashboard / narrow column: stacked layout
        ColumnLayout {
            visible: !root.compactLayout
            anchors.fill: parent
            spacing: 0

            NetworkTitleRow {}

            SparklineHost {
                Layout.topMargin: Tokens.spacing.medium
                Layout.bottomMargin: Tokens.spacing.small
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            NetworkDownloadRow {}
            NetworkUploadRow {}
            NetworkTotalRow {}
        }

            // Bar drop: title, then download número | gráfico (short card)
            ColumnLayout {
                id: compactBarLayout

                visible: root.compactLayout
                anchors.fill: parent
                spacing: Tokens.spacing.small

                NetworkTitleRow {}

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.medium

                    ColumnLayout {
                        Layout.preferredWidth: 168
                        Layout.maximumWidth: 200
                        Layout.alignment: Qt.AlignVCenter
                        spacing: Tokens.spacing.extraSmall

                        NetworkInlineStat {
                            icon: "download"
                            iconColor: Colours.palette.m3tertiary
                            label: qsTr("Download")
                            value: root.downloadSpeedText
                            valueColor: Colours.palette.m3tertiary
                        }

                        NetworkInlineStat {
                            icon: "upload"
                            iconColor: Colours.palette.m3secondary
                            label: qsTr("Upload")
                            value: root.uploadSpeedText
                            valueColor: Colours.palette.m3secondary
                        }

                        NetworkInlineStat {
                            icon: "history"
                            iconColor: Colours.palette.m3onSurfaceVariant
                            label: qsTr("Total")
                            value: root.sessionTotalText
                            valueColor: Colours.palette.m3onSurfaceVariant
                            compactValue: true
                        }
                    }

                    SparklineHost {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 76
                        Layout.minimumHeight: 76
                        Layout.maximumHeight: 76
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
    }

    component NetworkTitleRow: RowLayout {
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: "swap_vert"
            color: Colours.palette.m3primary
            fontStyle: Tokens.font.icon.medium
        }

        StyledText {
            text: qsTr("Network")
            font: Tokens.font.title.medium
        }
    }

    component SparklineHost: Item {
        SparklineItem {
            id: sparkline

            property real targetMax: 1024
            property real smoothMax: targetMax

            anchors.fill: parent
            line1: NetworkUsage.uploadBuffer // qmllint disable missing-type
            line1Color: Colours.palette.m3secondary
            line1FillAlpha: 0.15
            line2: NetworkUsage.downloadBuffer // qmllint disable missing-type
            line2Color: Colours.palette.m3tertiary
            line2FillAlpha: 0.2
            maxValue: smoothMax
            historyLength: NetworkUsage.historyLength

            Connections {
                function onValuesChanged(): void {
                    sparkline.targetMax = Math.max(NetworkUsage.downloadBuffer.maximum, NetworkUsage.uploadBuffer.maximum, 1024);
                    slideAnim.restart();
                }

                target: NetworkUsage.downloadBuffer
            }

            NumberAnimation {
                id: slideAnim

                target: sparkline
                property: "slideProgress"
                from: 0
                to: 1
                easing.type: Easing.Linear
                duration: GlobalConfig.dashboard.resourceUpdateInterval
            }

            Behavior on smoothMax {
                Anim {}
            }
        }

        StyledText {
            anchors.centerIn: parent
            text: qsTr("Collecting data...")
            font: Tokens.font.body.small
            color: Colours.palette.m3outline
            visible: NetworkUsage.downloadBuffer.count < 2
        }
    }

        component NetworkInlineStat: RowLayout {
            spacing: Tokens.spacing.extraSmall

            property string icon
            property color iconColor
            property string label
            property string value
            property color valueColor
            property bool compactValue: false

            MaterialIcon {
                text: parent.icon
                color: parent.iconColor
                fontStyle: Tokens.font.icon.small
            }

            StyledText {
                text: parent.label
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }

            Item {
                Layout.fillWidth: true
                Layout.minimumWidth: 4
            }

            StyledText {
                text: parent.value
                font: parent.compactValue ? Tokens.font.body.small : Tokens.font.body.builders.small.weight(Font.Medium).build()
                color: parent.valueColor
                elide: Text.ElideRight
                Layout.maximumWidth: 96
            }
        }

        component NetworkStatLine: ColumnLayout {
        id: statLine

        property string icon
        property color iconColor
        property string label
        property string value
        property color valueColor
        property bool smallValue: false

        spacing: 0

        RowLayout {
            spacing: Tokens.spacing.extraSmall

            MaterialIcon {
                text: statLine.icon
                color: statLine.iconColor
                fontStyle: Tokens.font.icon.small
            }

            StyledText {
                text: statLine.label
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        StyledText {
            Layout.leftMargin: 22
            text: statLine.value
            font: statLine.smallValue ? Tokens.font.body.small : Tokens.font.body.builders.medium.weight(Font.Medium).build()
            color: statLine.valueColor
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }

    component NetworkDownloadRow: RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: "download"
            color: Colours.palette.m3tertiary
            fontStyle: Tokens.font.icon.medium
        }

        StyledText {
            text: qsTr("Download")
            font: Tokens.font.body.small
            color: Colours.palette.m3onSurfaceVariant
        }

        Item {
            Layout.fillWidth: true
        }

        StyledText {
            text: root.downloadSpeedText
            font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
            color: Colours.palette.m3tertiary
        }
    }

    component NetworkUploadRow: RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: "upload"
            color: Colours.palette.m3secondary
            fontStyle: Tokens.font.icon.medium
        }

        StyledText {
            text: qsTr("Upload")
            font: Tokens.font.body.small
            color: Colours.palette.m3onSurfaceVariant
        }

        Item {
            Layout.fillWidth: true
        }

        StyledText {
            text: root.uploadSpeedText
            font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
            color: Colours.palette.m3secondary
        }
    }

    component NetworkTotalRow: RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: "history"
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.medium
        }

        StyledText {
            text: qsTr("Total")
            font: Tokens.font.body.small
            color: Colours.palette.m3onSurfaceVariant
        }

        Item {
            Layout.fillWidth: true
        }

        StyledText {
            text: root.sessionTotalText
            font: Tokens.font.body.small
            color: Colours.palette.m3onSurfaceVariant
        }
    }
}