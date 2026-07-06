pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../lock"

/**
 * Caelestia session lock for Samael panel family (replaces SamaelLock / ii LockScreen).
 * Requires Caelestia QML plugin (Caelestia.Config) — see caelestia/plugin README.
 */
Scope {
    id: root

    property alias sessionLock: lockHost.lock

    Lock {
        id: lockHost
    }

    // Hypr / hypridle still call `ipc call lock activate`; Caelestia native IPC uses `lock`.
    IpcHandler {
        target: "lock"

        function activate(): void {
            root.sessionLock.locked = true
        }

        function lock(): void {
            root.sessionLock.locked = true
        }

        function unlock(): void {
            root.sessionLock.unlock()
        }

        function isLocked(): bool {
            return root.sessionLock.locked
        }

        function focus(): void {
            // Caelestia lock refocuses via PasswordInput forceActiveFocus on surface
        }
    }
}