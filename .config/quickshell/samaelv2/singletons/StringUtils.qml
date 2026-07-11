pragma Singleton

import QtQuick

Item {
    function cleanMusicTitle(title) {
        if (!title)
            return ""
        title = title.replace(/^ *\([^)]*\) */g, " ")
        title = title.replace(/^ *\[[^\]]*\] */g, " ")
        title = title.replace(/^ *\{[^\}]*\} */g, " ")
        title = title.replace(/^ *【[^】]*】/, "")
        title = title.replace(/^ *《[^》]*》/, "")
        title = title.replace(/^ *「[^」]*」/, "")
        title = title.replace(/^ *『[^』]*』/, "")
        return title.trim()
    }
}