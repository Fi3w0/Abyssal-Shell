import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../components"
import "../services"

// The window this monitor is showing: the focused one if it is here,
// otherwise the last one you used on this monitor's workspace.
Item {
    id: root

    property var ctx
    readonly property var opts: ctx && ctx.options ? ctx.options : ({})
    readonly property var win: Tide.windowFor(ctx ? ctx.output : "")
    // A toplevel with no app_id (TideWM's own winit window, for one) must
    // not reach heuristicLookup: an empty name matches whichever desktop
    // entry lacks StartupWMClass, which is how an unrelated app's icon
    // (Deltarune) ended up on it. Fall back to the generic icon instead.
    readonly property string appId: win && win.app_id ? String(win.app_id) : ""
    readonly property var entry: appId ? DesktopEntries.heuristicLookup(appId) : null

    readonly property bool shown: win !== null && !(ctx && ctx.vertical)
    implicitHeight: 28
    implicitWidth: Math.min(row.implicitWidth + 26, opts.maxWidth ?? 300)

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.chip
    }

    RowLayout {
        id: row
        anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right; leftMargin: 12; rightMargin: 13 }
        spacing: 8

        AppIcon {
            id: appIcon
            visible: root.opts.showIcon !== false && status === Image.Ready
            iconName: root.entry ? root.entry.icon : ""
            implicitSize: 16
            asynchronous: true
            Layout.alignment: Qt.AlignVCenter
        }
        Icon {
            visible: root.opts.showIcon !== false && !appIcon.visible
            name: "app"
            size: 15
            color: Theme.subtext
            Layout.alignment: Qt.AlignVCenter
        }
        Text {
            text: root.win ? (root.win.title || root.win.app_id) : ""
            color: root.win && root.win.focused ? Theme.text : Theme.subtext
            font { family: Theme.font; pixelSize: 12; bold: true }
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
