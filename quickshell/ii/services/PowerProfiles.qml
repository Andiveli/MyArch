pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Power Profiles Daemon service
 */
Singleton {
    id: root

    property string currentProfile: "balanced"
    readonly property list<string> availableProfiles: ["performance", "balanced", "power-saver"]
    property bool available: false

    function setProfile(profile) {
        if (root.availableProfiles.includes(profile)) {
            setProfileProc.exec(["powerprofilesctl", "set", profile])
        }
    }

    function cycleProfile() {
        const currentIndex = root.availableProfiles.indexOf(root.currentProfile)
        const nextIndex = (currentIndex + 1) % root.availableProfiles.length
        root.setProfile(root.availableProfiles[nextIndex])
    }

    Process {
        id: checkProc
        running: true
        command: ["bash", "-c", "command -v powerprofilesctl"]
        onExited: (exitCode, exitStatus) => {
            root.available = (exitCode === 0)
            if (root.available) {
                getProfileProc.running = true
            }
        }
    }

    Process {
        id: getProfileProc
        running: false
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                const profile = this.text.trim()
                if (root.availableProfiles.includes(profile)) {
                    root.currentProfile = profile
                }
            }
        }
    }

    Process {
        id: setProfileProc
        running: false
        onExited: {
            getProfileProc.running = true
        }
    }

    // Monitor changes
    Process {
        id: monitorProc
        running: true
        command: ["powerprofilesctl", "monitor"]
        stdout: StdioCollector {
            onRead: (data) => {
                if (data.includes(":")) {
                    const parts = data.split(":")
                    const newProfile = parts[1]?.trim()
                    if (root.availableProfiles.includes(newProfile)) {
                        root.currentProfile = newProfile
                    }
                }
            }
        }
    }
}
