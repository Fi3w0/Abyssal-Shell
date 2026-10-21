import QtQuick
import Quickshell
import "../services"

HiDpiIcon {
    id: root
    property string iconName: ""
    property bool rasterFailed: false

    // The shipped OBS SVG has clipping that Qt renders as square patches.
    // Use its installed raster export; installations without it fall back
    // to normal theme resolution. No icon files are copied or modified.
    readonly property string rasterSource: iconName === "com.obsproject.Studio"
        ? (IconAssets.rasters.obs || "") : ""
    source: rasterSource && !rasterFailed ? rasterSource
          : iconName ? Quickshell.iconPath(iconName, true) : ""
    onIconNameChanged: rasterFailed = false
    onStatusChanged: {
        if (status === Image.Error && rasterSource && !rasterFailed) rasterFailed = true
    }
}
