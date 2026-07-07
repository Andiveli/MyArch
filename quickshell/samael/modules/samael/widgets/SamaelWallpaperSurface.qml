import QtQuick
import qs
import qs.services
import qs.modules.samael

SamaelPillSurface {
    id: surface

    mTop: 0
    mLeft: 0
    mRight: 0
    mBottom: 0

    onRequestClose: GlobalStates.wallpaperSelectorOpen = false

    implicitWidth: 920
    implicitHeight: 520

    SamaelWallpaperPickerContent {
        id: picker
        anchors.fill: parent
        focus: true
    }

    // ── Keyboard API — delegate to SamaelWallpaperPickerContent's existing nav ──

    function moveH(dir) {
        if (dir > 0) picker.vimMoveRight()
        else picker.vimMoveLeft()
    }

    function moveV(dir) {
        if (dir > 0) picker.vimMoveDown()
        else picker.vimMoveUp()
    }

    function activate() {
        if (picker.filteredPaths.length > 0)
            picker.applyPath(picker.filteredPaths[picker.selectedIndex])
    }

    function back() {
        return false
    }
}
