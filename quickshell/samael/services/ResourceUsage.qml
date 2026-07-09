pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

/**
 * DEPRECATED — all live CPU / RAM / disk / temp / top-process data
 * has been consolidated into the single source of truth: SamaelSystemMonitor.
 *
 * This file is kept only to avoid breaking any stray `import qs.services`
 * or qmldir registration. It does zero work and owns no state.
 *
 * TODO: remove this file + its qmldir entry once a full audit confirms zero references.
 */
Singleton {
    // Intentionally empty. All previous properties, timers, FileViews and Processes removed.
}
