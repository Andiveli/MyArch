import QtQuick
import Quickshell

import qs.modules.common
import qs.modules.samael
import qs.modules.samael.widgets
import qs.modules.ii.background

Scope {
    SamaelWallpaperPicker {}
    SamaelConnectionMenus {}
    SamaelSystemSidebarPanel {}
    SamaelSuperMenuPanel {}
    SamaelClockCalendarDrop {}
    SamaelMediaManagerPanel {}
    SamaelSessionMenu {}
    
    PanelLoader { component: Background {} }
    PanelLoader { component: SamaelBar {} }
}