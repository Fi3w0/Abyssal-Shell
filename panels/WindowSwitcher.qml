import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../components"
import "../services"

// Alt+Tab window switcher, off unless a keybind calls it:
//   bind Alt+Tab { "spawn:qs -c abyssal ipc call shell switcher" }
// Opens on the monitor you are working on with the windows most recently
// used first and the previous one picked. Each call (Tab) moves on;
// Shift+Tab / arrows go back; letting go of Alt, Enter or a click switches;
// Esc cancels.
PanelWindow {
    id: root

    required property string output
    readonly property bool open: Shell.switcherOn === output
    property bool shown: false
    property int selected: 0
    // Toplevels when it opened, most recent first.
    property var list: []

    onOpenChanged: {
        if (open) {
            list = Shell.windowsByRecent()
            selected = list.length > 1 ? 1 : 0
            shown = true
        }
    }
    Connections {
        target: Shell
        function onSwitcherStep(dir) {
            if (root.open && root.list.length) root.selected = (root.selected + dir + root.list.length) % root.list.length
        }
    }

    // The compositor ignores activation while an exclusive-keyboard layer
    // surface is mapped (a lock-screen guard), and this switcher is one: so
    // the chosen window is activated only once the switcher is gone.
    property var pending: null
    function choose() {
        pending = list[selected] || null
        Shell.switcherOn = ""
    }
    onShownChanged: if (!shown && pending) {
        const t = pending
        pending = null
        Qt.callLater(() => t.activate())
    }

    WlrLayershell.namespace: "abyssal-switcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: -1
    color: "transparent"
    visible: shown

    Item {
        id: stage
        anchors.fill: parent
        focus: true
        property real t: root.open ? 1 : 0
        Behavior on t { NumberAnimation { duration: root.open ? 160 : 120; easing.type: Easing.OutCubic } }
        onTChanged: if (t === 0 && !root.open) root.shown = false
        opacity: t

        Connections {
            target: root
            function onOpenChanged() { if (root.open) stage.forceActiveFocus() }
        }
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Tab || e.key === Qt.Key_Right) { Shell.switcherStep(1); e.accepted = true }
            else if (e.key === Qt.Key_Backtab || e.key === Qt.Key_Left) { Shell.switcherStep(-1); e.accepted = true }
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { root.choose(); e.accepted = true }
            else if (e.key === Qt.Key_Escape) { Shell.switcherOn = ""; e.accepted = true }
        }
        Keys.onReleased: e => { if (e.key === Qt.Key_Alt || e.key === Qt.Key_Meta) root.choose() }

        MouseArea { anchors.fill: parent; onClicked: Shell.switcherOn = "" }

        Text {
            visible: root.list.length === 0
            anchors.centerIn: parent
            text: "No windows"
            color: Theme.text
            style: Text.Outline
            styleColor: Theme.alpha(Theme.crust, 0.6)
            font { family: Theme.font; pixelSize: 13; bold: true }
        }

        // Live previews floating over the desktop, no panel behind them. The
        // compositor needs hyprland-toplevel-export (TideWM has it); without
        // it a card shows the app icon instead.
        Row {
            id: cards
            anchors.centerIn: parent
            spacing: 18
            scale: 0.96 + 0.04 * stage.t

            Repeater {
                model: root.list
                delegate: Item {
                    id: card
                    required property var modelData
                    required property int index
                    readonly property bool current: index === root.selected
                    readonly property var entry: modelData.appId ? DesktopEntries.heuristicLookup(modelData.appId) : null
                    // Fit the window's own shape into the card's box.
                    readonly property real boxW: Math.min(280, (root.width - 120) / Math.max(1, root.list.length) - 18)
                    readonly property real boxH: 180
                    readonly property real aspect: view.hasContent && view.sourceSize.height > 0
                        ? view.sourceSize.width / view.sourceSize.height : 16 / 10
                    readonly property real shotW: Math.min(boxW, boxH * aspect)
                    readonly property real shotH: shotW / aspect

                    width: boxW
                    height: boxH + 34
                    opacity: current || area.containsMouse ? 1 : 0.72
                    Behavior on opacity { NumberAnimation { duration: 120 } }

                    RectangularShadow {
                        anchors.fill: shot
                        radius: shot.radius
                        blur: 24
                        offset: Qt.vector2d(0, 8)
                        color: Theme.alpha(Theme.crust, 0.55)
                    }
                    ClippingRectangle {
                        id: shot
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: (card.boxH - height) / 2
                        width: card.shotW
                        height: card.shotH
                        radius: Theme.controlRadius
                        color: Theme.alpha(Theme.base, 0.9)
                        border.width: card.current ? 2 : 1
                        border.color: card.current ? Theme.accent : Theme.hairline
                        scale: card.current ? 1.04 : 1
                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                        ScreencopyView {
                            id: view
                            anchors.fill: parent
                            captureSource: root.shown ? card.modelData : null
                            live: root.open
                        }
                        // No capture (compositor without the protocol, or a
                        // window that cannot be captured): the app's icon.
                        AppIcon {
                            id: icon
                            visible: !view.hasContent && status === Image.Ready
                            anchors.centerIn: parent
                            implicitSize: 56
                            iconName: card.entry ? card.entry.icon : (card.modelData.appId || "")
                        }
                    }

                    // Icon and name under the preview.
                    Row {
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
                        spacing: 6
                        width: Math.min(implicitWidth, card.width)
                        AppIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: 16
                            iconName: card.entry ? card.entry.icon : (card.modelData.appId || "")
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(implicitWidth, card.width - 22)
                            elide: Text.ElideRight
                            text: card.modelData.title || (card.entry ? card.entry.name : card.modelData.appId)
                            color: card.current ? Theme.accent : Theme.text
                            style: Text.Outline
                            styleColor: Theme.alpha(Theme.crust, 0.6)
                            font { family: Theme.font; pixelSize: 12; bold: card.current }
                        }
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.selected = card.index
                        onClicked: root.choose()
                    }
                }
            }
        }
    }
}
