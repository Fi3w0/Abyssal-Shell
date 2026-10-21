import QtQuick
import QtQuick.Window
import Quickshell.Widgets

// Request physical pixels from icon providers, including on fractional
// scale screens. Keep the displayed geometry in logical pixels.
IconImage {
    id: root
    readonly property int pixels: Math.max(1, Math.ceil(actualSize * (Screen.devicePixelRatio || 1)))
    backer.sourceSize.width: pixels
    backer.sourceSize.height: pixels
    backer.smooth: true
    mipmap: true
}
