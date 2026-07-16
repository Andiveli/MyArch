pragma Singleton

import QtQuick

/** Wired from shell.qml — bar widgets call these instead of GlobalStates. */
Item {
    property var toggleMedia: null
    property var toggleNotifications: null
    property var toggleWifi: null
    property var toggleBluetooth: null
    property var toggleOverview: null
    property var togglePower: null
    property var toggleUsage: null
    property var toggleLauncher: null
    property var toggleCalendar: null
    property var toggleSettings: null
    property var toggleRecord: null
    property var closeMiddleSurface: null
    property var closeRightSurface: null
    property var closeLeftSurface: null
    /** Measured from reserve MiddleIdle (pill handoff). */
    property real middleRestWidth: 0
    property real middleRestHeight: 0
    property real rightRestWidth: 0
    property real rightRestHeight: 0
    property real leftRestWidth: 0
    property real leftRestHeight: 0
    /** True while middle media surface is open — gates MprisPlaybackClock timers. */
    property bool mediaPanelOpen: false
}