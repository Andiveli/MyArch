pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Scope {
    id: bar
    property bool showBarBackground: true  // Always show for Waybar style

    Variants {
        // For each monitor
        model: {
            const screens = Quickshell.screens;
            const list = Config.options.bar.screenList;
            if (!list || list.length === 0)
                return screens;
            return screens.filter(screen => list.includes(screen.name));
        }
        LazyLoader {
            id: barLoader
            active: GlobalStates.barOpen && !GlobalStates.screenLocked
            required property ShellScreen modelData
            component: PanelWindow {
                id: barRoot
                screen: barLoader.modelData

                property bool superShow: false
                property bool mustShow: hoverRegion.containsMouse || superShow
                exclusionMode: ExclusionMode.Ignore
                exclusiveZone: Appearance.sizes.baseBarHeight + 8
                WlrLayershell.namespace: "quickshell:bar"
                implicitHeight: 32 + Appearance.rounding.screenRounding
                color: "transparent"

                // Positioning
                anchors {
                    top: !Config.options.bar.bottom
                    bottom: Config.options.bar.bottom
                    left: true
                    right: true
                }

                margins {
                    top: 3
                    bottom: 3
                    left: 8
                    right: 8
                }

                MouseArea {
                    id: hoverRegion
                    hoverEnabled: true
                    anchors.fill: parent

                    WaybarContent {
                        id: barContent
                        anchors.fill: parent
                    }

                    // Round decorators for Waybar style
                    RoundCorner {
                        id: leftCorner
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            left: parent.left
                        }
                        implicitSize: 15
                        color: "#000000"
                        corner: RoundCorner.CornerEnum.TopLeft

                        states: State {
                            name: "bottom"
                            when: Config.options.bar.bottom
                            PropertyChanges {
                                leftCorner.corner: RoundCorner.CornerEnum.BottomLeft
                            }
                        }
                    }
                    RoundCorner {
                        id: rightCorner
                        anchors {
                            right: parent.right
                            top: !Config.options.bar.bottom ? parent.top : undefined
                            bottom: Config.options.bar.bottom ? parent.bottom : undefined
                        }
                        implicitSize: 15
                        color: "#000000"
                        corner: RoundCorner.CornerEnum.TopRight

                        states: State {
                            name: "bottom"
                            when: Config.options.bar.bottom
                            PropertyChanges {
                                rightCorner.corner: RoundCorner.CornerEnum.BottomRight
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "bar"

        function toggle(): void {
            GlobalStates.barOpen = !GlobalStates.barOpen
        }

        function close(): void {
            GlobalStates.barOpen = false
        }

        function open(): void {
            GlobalStates.barOpen = true
        }
    }

    GlobalShortcut {
        name: "barToggle"
        description: "Toggles bar on press"

        onPressed: {
            GlobalStates.barOpen = !GlobalStates.barOpen;
        }
    }

    GlobalShortcut {
        name: "barOpen"
        description: "Opens bar on press"

        onPressed: {
            GlobalStates.barOpen = true;
        }
    }

    GlobalShortcut {
        name: "barClose"
        description: "Closes bar on press"

        onPressed: {
            GlobalStates.barOpen = false;
        }
    }
}
