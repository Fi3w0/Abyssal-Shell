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
            const fresh = !shown || !last || last.page !== d.page
            last = d
            shown = true
            if (fresh) Qt.callLater(placeCard)
        }
    }
    function keepCardOnScreen() {
        if (!win.clipboard) return
        card.x = Math.max(8, Math.min(Math.max(8, win.width - card.width - 8), card.x))
        card.y = Math.max(8, Math.min(Math.max(8, win.height - card.height - 8), card.y))
    }
    function placeCard() {
        if (!win.clipboard) { card.x = 0; card.y = 0; return }
        card.x = edge === "left" ? win.inset : edge === "right" ? win.width - card.width - win.inset
            : (last ? last.pos : win.width / 2) - card.width / 2
        card.y = edge === "top" ? win.inset : edge === "bottom" ? win.height - card.height - win.inset
            : (last ? last.pos : win.height / 2) - card.height / 2
        keepCardOnScreen()
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

        // Keep pointer coordinates stable while the clipboard card moves.
        // Only the card accepts input; outside clicks reach the catcher.
        readonly property bool clipboard: page === "clipboard"
        anchors.top: clipboard || root.edge !== "bottom"
        anchors.bottom: clipboard || root.edge === "bottom"
        anchors.left: clipboard || root.edge !== "right"
        anchors.right: clipboard || root.edge === "right"
        margins.top: clipboard ? 0 : root.edge === "top" ? inset : root.vertical ? along : 0
        margins.bottom: !clipboard && root.edge === "bottom" ? inset : 0
        margins.left: clipboard ? 0 : root.edge === "left" ? inset : root.vertical ? 0 : along
        margins.right: !clipboard && root.edge === "right" ? inset : 0
        mask: clipboard ? cardRegion : null
        Region { id: cardRegion; item: card }
        onWidthChanged: Qt.callLater(root.keepCardOnScreen)
        onHeightChanged: Qt.callLater(root.keepCardOnScreen)

        readonly property string page: root.last ? root.last.page : ""
        implicitWidth: page === "clock" ? 680 : page === "notifications" || page === "clipboard" ? 380 : ["updates", "update-settings", "wallpaper-settings"].includes(page) ? 420 : page === "usage" ? 360 : page === "calendar" ? 320 : 340
        implicitHeight: Math.min(card.implicitHeight, (root.screen ? root.screen.height : 900) - 2 * inset)

        Rectangle {
            id: card
            anchors.fill: win.clipboard ? undefined : parent
            width: win.clipboard ? Math.max(0, Math.min(380, win.width - 16)) : win.width
            height: win.clipboard ? Math.max(0, Math.min(implicitHeight, win.height - 16)) : win.height
            onHeightChanged: Qt.callLater(root.keepCardOnScreen)
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
                    clipboard: "ClipboardPanel.qml", updates: "UpdatesPanel.qml", "update-settings": "UpdateSettingsPage.qml", "wallpaper-settings": "WallpaperSettings.qml", drives: "DrivesPanel.qml", usage: "AiUsagePanel.qml"
                })[win.page] || ""
                onLoaded: {
                    if (win.clipboard) item.dragTarget = card
                    item.active = Qt.binding(() => root.open)
                }
            }
        }
    }
}
