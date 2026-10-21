import QtQuick
import "../components"
import "../services"

// Pending package updates: an icon with the count (rose when something
// important like the kernel is in it), pulsing while it checks. Opens the
// updates panel under the widget. Hidden with nothing pending unless set
// to always show.
Item {
    id: root
    property var ctx

    readonly property bool shown: Updates.count > 0 || Updates.checking || (ctx && ctx.options && ctx.options.whenNone === "show")
    readonly property real iconSize: ctx && ctx.options ? (ctx.options.iconSize ?? 17) : 17
    readonly property bool open: Shell.detail !== null && Shell.detail.page === "updates" && Shell.detail.output === (ctx ? ctx.output : "")
    readonly property color tint: open ? Theme.accent : Updates.important ? Theme.rose : Updates.count ? Theme.accent : Theme.subtext

    implicitWidth: row.implicitWidth + 16
    implicitHeight: 28

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
        opacity: pulse.value
        Icon { anchors.verticalCenter: parent.verticalCenter; name: "package"; size: root.iconSize; color: root.tint }
        Text {
            visible: Updates.count > 0
            anchors.verticalCenter: parent.verticalCenter
            text: Updates.count
            color: root.tint
            font { family: Theme.monoFont; pixelSize: 11; bold: true }
        }
    }

    // Breathes while checking.
    QtObject { id: pulse; property real value: 1 }
    SequentialAnimation {
        running: Updates.checking
        loops: Animation.Infinite
        onRunningChanged: if (!running) pulse.value = 1
        NumberAnimation { target: pulse; property: "value"; to: 0.4; duration: 700; easing.type: Easing.InOutSine }
        NumberAnimation { target: pulse; property: "value"; to: 1; duration: 700; easing.type: Easing.InOutSine }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const p = root.mapToItem(null, root.width / 2, root.height / 2)
            Shell.toggleDetail(root.ctx.output, root.ctx.edge, "updates", root.ctx.vertical ? p.y : p.x, root.ctx.thickness)
        }
    }
}
