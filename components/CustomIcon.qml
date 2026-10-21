import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Widgets
import "../services"

// A user-chosen icon:
//   builtin:<name>   one of Abyssal's line icons, tinted
//   theme:<name>     an icon from the icon theme
//   file:<path>      any image Qt reads (png, jpg, svg, webp, gif, bmp, ico)
// Files are decoded at the size they are shown, so a large picture costs a
// small texture, and SVGs stay sharp at any scale.
Item {
    id: root

    property string spec: "builtin:logo"
    property real size: 20
    property color tint: Theme.cyan

    readonly property string kind: spec.indexOf(":") > 0 ? spec.slice(0, spec.indexOf(":")) : "builtin"
    readonly property string value: spec.indexOf(":") > 0 ? spec.slice(spec.indexOf(":") + 1) : spec
    readonly property int pixels: Math.ceil(size * (Screen.devicePixelRatio || 1))

    implicitWidth: size
    implicitHeight: size

    Icon {
        anchors.centerIn: parent
        visible: root.kind === "builtin"
        name: root.value
        size: root.size
        stroke: 2.2
        color: root.tint
    }

    AppIcon {
        anchors.fill: parent
        visible: root.kind === "theme"
        iconName: root.kind === "theme" ? root.value : ""
        asynchronous: true
    }

    Image {
        id: picture
        anchors.fill: parent
        visible: root.kind === "file" && status === Image.Ready
        source: root.kind === "file" ? "file://" + root.value.split("/").map(encodeURIComponent).join("/") : ""
        sourceSize.width: root.pixels
        sourceSize.height: root.pixels
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        mipmap: true
    }

    // A missing or unreadable file falls back to the generic icon.
    Icon {
        anchors.centerIn: parent
        visible: root.kind === "file" && picture.status === Image.Error
        name: "app"
        size: root.size * 0.8
        color: Theme.overlay
    }
}
