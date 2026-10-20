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
    readonly property var win: Tide.windowFor(ctx ? ctx.output : "")
    readonly property var entry: win ? DesktopEntries.heuristicLookup(win.app_id) : null
    readonly property string iconPath: entry && entry.icon ? Quickshell.iconPath(entry.icon, true) : ""

    readonly property bool shown: win !== null && !(ctx && ctx.vertical)
    implicitHeight: 28
    implicitWidth: Math.min(row.implicitWidth + 26, 300)

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.chip
    }

    RowLayout {
        id: row
        anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right; leftMargin: 12; rightMargin: 13 }
        spacing: 8

        IconImage {
            visible: root.iconPath !== ""
            source: root.iconPath
            implicitSize: 16
            asynchronous: true
            Layout.alignment: Qt.AlignVCenter
        }
        Icon {
            visible: root.iconPath === ""
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
