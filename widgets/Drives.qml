import QtQuick
import "../components"
import "../services"

// Removable drives: shows up while one is connected (with how many, when
// more than one) and opens the drives panel under the widget.
Item {
    id: root
    property var ctx

    readonly property bool shown: Drives.count > 0 || (ctx && ctx.options && ctx.options.whenNone === "show")
    readonly property real iconSize: ctx && ctx.options ? (ctx.options.iconSize ?? 17) : 17
    readonly property bool open: Shell.detail !== null && Shell.detail.page === "drives" && Shell.detail.output === (ctx ? ctx.output : "")

    implicitWidth: row.implicitWidth + 16
    implicitHeight: 28
    readonly property real minimumContentWidth: row.implicitWidth + 2
    readonly property real minimumContentHeight: row.implicitHeight + 2

    Rectangle {
        anchors.fill: parent
        radius: 9
        color: root.open ? Theme.accentSoft : area.containsMouse ? Theme.hover : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.anim } }
    }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5
        Icon { anchors.verticalCenter: parent.verticalCenter; name: "usb"; size: root.iconSize; color: root.open || Drives.count ? Theme.accent : Theme.subtext }
        Text {
            visible: Drives.count > 1
            anchors.verticalCenter: parent.verticalCenter
            text: Drives.count
            color: Theme.accent
            font { family: Theme.monoFont; pixelSize: 11; bold: true }
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const p = root.mapToItem(null, root.width / 2, root.height / 2)
            Shell.toggleDetail(root.ctx.output, root.ctx.edge, "drives", root.ctx.vertical ? p.y : p.x, root.ctx.thickness)
        }
    }
}
