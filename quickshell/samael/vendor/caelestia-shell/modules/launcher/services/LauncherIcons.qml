pragma Singleton

import QtQuick
import Quickshell

/** Resolve desktop Icon= names to theme icons (avoids image-missing placeholder). */
QtObject {
    id: root

    readonly property var substitutions: ({
        "code-url-handler": "visual-studio-code",
        "Code": "visual-studio-code",
        "gnome-tweaks": "org.gnome.tweaks",
        "pavucontrol-qt": "pavucontrol",
        "wps": "wps-office2019-kprometheus",
        "wpsoffice": "wps-office2019-kprometheus",
        "footclient": "foot",
    })

    readonly property var regexSubstitutions: [
        { regex: /^steam_app_(\d+)$/, replace: "steam_icon_$1" },
        { regex: /Minecraft.*/, replace: "minecraft" },
        { regex: /.*polkit.*/, replace: "system-lock-screen" },
        { regex: /gcr.prompter/, replace: "system-lock-screen" },
    ]

    function iconExists(iconName: string): bool {
        if (!iconName || iconName.length === 0)
            return false
        const path = Quickshell.iconPath(iconName, true)
        return path.length > 0 && !String(path).includes("image-missing")
    }

    function resolveDesktopIcon(entry: var): string {
        if (!entry)
            return "application-x-executable"

        const raw = entry.icon
        if (raw && iconExists(raw))
            return raw

        const id = (entry.id || "").replace(/\.desktop$/i, "")
        const guessed = guessIcon(id)
        if (guessed && iconExists(guessed))
            return guessed

        const hinted = DesktopEntries.heuristicLookup(entry.id)
        if (hinted?.icon && iconExists(hinted.icon))
            return hinted.icon

        return "application-x-executable"
    }

    function guessIcon(str: string): string {
        if (!str || str.length === 0)
            return "application-x-executable"

        const byId = DesktopEntries.byId(str)
        if (byId?.icon && iconExists(byId.icon))
            return byId.icon

        if (substitutions[str] && iconExists(substitutions[str]))
            return substitutions[str]
        const lower = str.toLowerCase()
        if (substitutions[lower] && iconExists(substitutions[lower]))
            return substitutions[lower]

        for (let i = 0; i < regexSubstitutions.length; i++) {
            const sub = regexSubstitutions[i]
            const replaced = str.replace(sub.regex, sub.replace)
            if (replaced !== str && iconExists(replaced))
                return replaced
        }

        if (iconExists(str))
            return str
        if (iconExists(lower))
            return lower

        const tail = str.split(".").pop()
        if (tail) {
            if (iconExists(tail))
                return tail
            if (iconExists(tail.toLowerCase()))
                return tail.toLowerCase()
        }

        const kebab = str.toLowerCase().replace(/\s+/g, "-")
        if (iconExists(kebab))
            return kebab

        const heuristic = DesktopEntries.heuristicLookup(str)
        if (heuristic?.icon && iconExists(heuristic.icon))
            return heuristic.icon

        return "application-x-executable"
    }
}
