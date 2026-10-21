import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"

// Popup opened from a bar widget, placed right under (or beside) it: the
// Wi-Fi / Bluetooth / Sound pages the quick menu drills into, the calendar,
// the notification centre, or both (the clock's panel).
// Its own layer surface with on-demand keyboard focus, so the Wi-Fi
// password field can be typed into (bar surfaces never take the keyboard).
// Click outside or press Esc to close. It grows in from the bar's side
// and fades; closing plays that backwards before the window goes away.
Scope {
    id: root

    required property var screen
    readonly property var d: Shell.detail
    readonly property bool open: d !== null && screen && d.output === screen.name
    // The popup last opened here, kept while it animates out.
    property var last: null
    // The window stays up until the closing animation is done.
    property bool shown: false
    Connections {
        target: Shell
        function onDetailChanged() { root.sync() }
    }
    function sync() {
        const d = Shell.detail
        if (d && screen && d.output === screen.name) {
            last = d
            shown = true
        }
    }
    readonly property string edge: last ? last.edge : "top"
    readonly property bool vertical: edge === "left" || edge === "right"

    PanelWindow {
        screen: root.screen
        visible: root.open
        WlrLayershell.namespace: "abyssal-catcher"
        WlrLayershell.layer: WlrLayer.Top
        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: 0
        color: "transparent"
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: Shell.detail = null
        }
    }

    PanelWindow {
        id: win
        screen: root.screen
        visible: root.shown
        WlrLayershell.namespace: "abyssal-detail"
        WlrLayershell.layer: WlrLayer.Overlay
        // The clipboard takes the keyboard at once (type to search right
        // after the keybind); the others only when clicked.
        WlrLayershell.keyboardFocus: page === "clipboard" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand
        exclusiveZone: 0
        color: "transparent"

        readonly property int gap: 8
        readonly property int inset: root.last ? root.last.inset + 6 + gap : gap
        // Centre on the widget, kept on screen.
        readonly property int along: {
            if (!root.last || !root.screen) return gap
            const span = root.vertical ? root.screen.height : root.screen.width
            const size = root.vertical ? implicitHeight : implicitWidth
            return Math.max(gap, Math.min(span - size - gap, Math.round(root.last.pos - size / 2)))
        }

        anchors.top: root.edge !== "bottom"
        anchors.bottom: root.edge === "bottom"
        anchors.left: root.edge !== "right"
        anchors.right: root.edge === "right"
        margins.top: root.edge === "top" ? inset : root.vertical ? along : 0
        margins.bottom: root.edge === "bottom" ? inset : 0
        margins.left: root.edge === "left" ? inset : root.vertical ? 0 : along
        margins.right: root.edge === "right" ? inset : 0

        readonly property string page: root.last ? root.last.page : ""
        implicitWidth: page === "clock" ? 680 : page === "notifications" || page === "clipboard" ? 380 : page === "calendar" ? 320 : 340
        implicitHeight: Math.min(card.implicitHeight, (root.screen ? root.screen.height : 900) - 2 * inset)

        Rectangle {
            id: card
            anchors.fill: parent
            implicitHeight: loader.implicitHeight + 28
            radius: Theme.popupRadius
            color: Theme.glassStrong
            border.width: 1
            border.color: Theme.hairline
            clip: true
            focus: true
            Keys.onEscapePressed: Shell.detail = null

            property real t: root.open ? 1 : 0
            Behavior on t { NumberAnimation { duration: root.open ? 220 : 150; easing.type: Easing.OutCubic } }
            onTChanged: if (t === 0 && !root.open) root.shown = false
            opacity: t
            scale: 0.94 + 0.06 * t
            transformOrigin: root.edge === "bottom" ? Item.Bottom : root.edge === "left" ? Item.Left
                           : root.edge === "right" ? Item.Right : Item.Top

            Loader {
                id: loader
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                active: root.shown
                source: ({
                    wifi: "WifiPage.qml", bluetooth: "BluetoothPage.qml", sound: "SoundPage.qml",
                    calendar: "CalendarView.qml", notifications: "NotificationList.qml", clock: "ClockCenter.qml",
                    clipboard: "ClipboardPanel.qml"
                })[win.page] || ""
                onLoaded: item.active = Qt.binding(() => root.open)
            }
        }
    }
}
