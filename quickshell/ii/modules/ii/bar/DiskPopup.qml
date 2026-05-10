import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root

    // Helper function to format bytes to GB
    function formatGB(bytes) {
        return (bytes / (1024 * 1024 * 1024)).toFixed(1) + " GB";
    }

    Column {
        anchors.centerIn: parent
        spacing: 8

        StyledPopupHeaderRow {
            icon: "storage"
            label: "Disk (/)"
        }

        Column {
            spacing: 4

            StyledPopupValueRow {
                icon: "clock_loader_60"
                label: Translation.tr("Used:")
                value: root.formatGB(DiskUsage.diskUsed)
            }

            StyledPopupValueRow {
                icon: "check_circle"
                label: Translation.tr("Free:")
                value: root.formatGB(DiskUsage.diskFree)
            }

            StyledPopupValueRow {
                icon: "empty_dashboard"
                label: Translation.tr("Total:")
                value: root.formatGB(DiskUsage.diskTotal)
            }
        }
    }
}
