import qs.modules.common
import qs.services
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root
    property bool barOpen: true
    property bool crosshairOpen: false
    property bool sidebarLeftOpen: false
    property bool sidebarRightOpen: false
    property bool mediaControlsOpen: false
    property bool osdBrightnessOpen: false
    property bool osdVolumeOpen: false
    property bool oskOpen: false
    property bool overlayOpen: false
    property bool overviewOpen: false
    property bool regionSelectorOpen: false
    property bool searchOpen: false
    property bool screenLocked: false
    property bool screenLockContainsCharacters: false
    property bool screenUnlockFailed: false
    property bool screenTranslatorOpen: false
    property bool sessionOpen: false
    property bool superDown: false
    property bool superReleaseMightTrigger: true
    property bool wallpaperSelectorOpen: false
    property bool samaelWifiMenuOpen: false
    property bool samaelBluetoothMenuOpen: false
    property bool samaelNotificationsMenuOpen: false
    property bool samaelSystemSidebarOpen: false
    property bool samaelSuperMenuOpen: false
    // Screen coords for notification island (updated by focused monitor bar)
    property bool samaelIslandAnchorValid: false
    property string samaelIslandScreenName: ""
    property real samaelIslandTop: 0
    property real samaelIslandLeft: 0
    property real samaelIslandWidth: 0
    property int samaelIslandPulse: 0
    // Clock calendar drop (bar publishes anchor under clock)
    property bool samaelClockDropOpen: false
    property bool samaelClockAnchorValid: false
    property string samaelClockScreenName: ""
    property real samaelClockDropTop: 0
    property real samaelClockDropLeft: 0
    property real samaelClockDropCenterX: 0
    property real samaelClockDropWidth: 0
    // Media manager drop (bar MediaWidget publishes anchor + dock seam)
    property string samaelMediaScreenName: ""
    property real samaelMediaCenterX: 0
    property real samaelMediaDockTop: 0
    property real samaelMediaDockLeft: 0
    property real samaelMediaDockWidth: 0
    /** 0 = docked flush to bar; 1 = panel tucked under bar (Caelestia-style attach anim) */
    property real samaelMediaAttach: 1.0
    // Bar vim navigation (h/l stops, j/k contextual)
    property bool samaelBarNavActive: false
    property int samaelBarFocus: 0 // 0 drawer .. 7 session
    property bool workspaceShowNumbers: false

    onSidebarRightOpenChanged: {
        if (GlobalStates.sidebarRightOpen) {
            Notifications.timeoutAll();
            Notifications.markAllRead();
        }
    }

    GlobalShortcut {
        name: "workspaceNumber"
        description: "Hold to show workspace numbers, release to show icons"

        onPressed: {
            root.superDown = true
        }
        onReleased: {
            root.superDown = false
        }
    }
}