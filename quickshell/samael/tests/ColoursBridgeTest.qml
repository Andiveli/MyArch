import QtQuick
import QtTest
import qs.services
import qs.modules.bridge

TestCase {
    name: "ColoursBridge"

    function test_wallust_bridge_exposes_primary() {
        compare(WallustColoursBridge.primary, Colours.palette.m3primary)
    }

    function test_tpalette_lock_surface_roles() {
        compare(Colours.tPalette.m3surfaceContainer, Colours.palette.m3surfaceContainer)
        compare(Colours.tPalette.m3surfaceContainerHigh, Colours.palette.m3surfaceContainerHigh)
        compare(Colours.tPalette.m3surfaceContainerHighest, Colours.palette.m3surfaceContainerHighest)
        verify(Colours.tPalette.m3surfaceContainer.a > 0)
        verify(Colours.palette.m3primary !== undefined)
    }

    function test_samael_lock_colors_track_wallust() {
        compare(SamaelLockColors.primary, WallustColors.sapphire)
        compare(SamaelLockColors.onSurface, WallustColors.moduleText)
    }
}