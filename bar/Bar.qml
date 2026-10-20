import QtQuick
import Quickshell
import Quickshell.Wayland
import "../components"
import "../services"

// One bar on one edge of one monitor, built from a BarLayout entry. Its
// three sections (start / center / end) become floating islands, or sit on
// one solid strip in the solid style.
//
// Edit mode (Shell.editing): every widget gets a dashed outline, a drag
// handle and a remove button; empty sections stay visible as drop targets.
// Auto-hide: the bar reserves no space and slides away, leaving a thin
// strip at the screen edge that brings it back on hover.
PanelWindow {
    id: bar

    required property var config        // one entry of BarLayout.barsFor()
    readonly property string edge: config.edge
    readonly property string output: screen ? screen.name : ""
    readonly property bool vertical: edge === "left" || edge === "right"
    readonly property bool islands: config.style === "islands"
    readonly property bool autohide: config.visibility === "autohide"
    readonly property int thickness: config.size

    // Auto-hide reveal: hover, an open menu, or edit mode keep it out.
    property bool hovered: false
    readonly property bool revealed: !autohide || hovered || Shell.editing || menu.visible
                                     || (Shell.quickSettings !== null && Shell.quickSettings.output === output)
    readonly property int hotStrip: 3

    WlrLayershell.namespace: "abyssal-bar"
    WlrLayershell.layer: autohide ? WlrLayer.Overlay : WlrLayer.Top

    anchors.top: edge !== "bottom"
    anchors.bottom: edge !== "top"
    anchors.left: edge !== "right"
    anchors.right: edge !== "left"
    implicitHeight: thickness
    implicitWidth: thickness
    exclusiveZone: autohide ? 0 : thickness
    color: "transparent"

    // While hidden only the thin edge strip takes input; windows under the
    // rest of the bar stay clickable.
    mask: revealed ? null : hotRegion
    Region { id: hotRegion; item: hot }
    Item {
        id: hot
        x: bar.edge === "right" ? bar.width - bar.hotStrip : 0
        y: bar.edge === "bottom" ? bar.height - bar.hotStrip : 0
        width: bar.vertical ? bar.hotStrip : bar.width
        height: bar.vertical ? bar.height : bar.hotStrip
    }

    HoverHandler {
        onHoveredChanged: {
            if (hovered) { hideDelay.stop(); bar.hovered = true }
            else hideDelay.restart()
        }
    }
    Timer { id: hideDelay; interval: 450; onTriggered: bar.hovered = false }

    // Handed to every widget; `options` is the widget's own layout entry.
    function contextFor(widget) {
        return { output: bar.output, edge: bar.edge, vertical: bar.vertical, options: widget }
    }

    // ── Content, slid off-screen while auto-hidden ──────────────────────
    Item {
        id: content
        width: bar.width
        height: bar.height
        x: bar.revealed ? 0 : (bar.edge === "left" ? -bar.width : bar.edge === "right" ? bar.width : 0)
        y: bar.revealed ? 0 : (bar.edge === "top" ? -bar.height : bar.edge === "bottom" ? bar.height : 0)
        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        // Right-click on the bar's empty space: the bar menu.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: mouse => {
                menu.anchor.rect.x = mouse.x
                menu.anchor.rect.y = mouse.y
                menu.visible = true
            }
        }

        // Solid style: one strip with a hairline on the inner edge.
        Rectangle {
            visible: !bar.islands
            anchors.fill: parent
            color: Theme.glass

            Rectangle {
                color: Theme.alpha(Theme.text, 0.10)
                width: bar.vertical ? 1 : parent.width
                height: bar.vertical ? parent.height : 1
                x: bar.edge === "left" ? parent.width - 1 : 0
                y: bar.edge === "top" ? parent.height - 1 : 0
            }
        }

        // Edit mode marks the whole bar.
        Rectangle {
            visible: Shell.editing
            anchors.fill: parent
            anchors.margins: 2
            radius: 10
            color: "transparent"
            border.width: 1
            border.color: Theme.alpha(Theme.cyan, 0.45)
        }

        Slot { id: startSlot; which: "start" }
        Slot { id: centerSlot; which: "center" }
        Slot { id: endSlot; which: "end" }

        // Drag ghost: follows the pointer while a widget is being moved.
        Rectangle {
            id: ghost
            visible: drag.active
            z: 100
            x: drag.px - width / 2
            y: drag.py - height / 2
            width: ghostLabel.implicitWidth + 20
            height: 26
            radius: 13
            color: Theme.accent
            Text {
                id: ghostLabel
                anchors.centerIn: parent
                text: drag.label
                color: Theme.crust
                font { family: Theme.font; pixelSize: 11; bold: true }
            }
        }

        // Drop indicator: a bar between widgets where the drop will land.
        Rectangle {
            visible: drag.active && drag.target !== null
            z: 99
            color: Theme.cyan
            radius: 1
            width: bar.vertical ? 24 : 2
            height: bar.vertical ? 2 : 24
            x: drag.target ? (bar.vertical ? (bar.width - width) / 2 : drag.target.at - 1) : 0
            y: drag.target ? (bar.vertical ? drag.target.at - 1 : (bar.height - height) / 2) : 0
        }
    }

    // ── Drag and drop between sections ──────────────────────────────────
    QtObject {
        id: drag
        property bool active: false
        property string label: ""
        property string fromSection: ""
        property int fromIndex: -1
        property real px: 0
        property real py: 0
        // { section, index, at } where `at` is the indicator position
        property var target: null
    }

    readonly property var slots: [startSlot, centerSlot, endSlot]

    // Picks the section under (or nearest to) the pointer and the index the
    // widget would take there, counting the other widgets' centres.
    function dropTarget(px, py) {
        const along = vertical ? py : px
        let best = null
        let bestDist = Infinity
        for (const s of slots) {
            const lo = vertical ? s.y : s.x
            const hi = lo + (vertical ? s.height : s.width)
            const d = along < lo ? lo - along : along > hi ? along - hi : 0
            if (d < bestDist) { bestDist = d; best = s }
        }
        if (!best) return null
        const cells = best.cells()
        let index = 0
        let at = vertical ? best.y + best.pad : best.x + best.pad
        for (const c of cells) {
            if (best.which === drag.fromSection && c.index === drag.fromIndex) continue
            const p = c.mapToItem(content, 0, 0)
            const start = vertical ? p.y : p.x
            const size = vertical ? c.height : c.width
            if (along > start + size / 2) {
                index++
                at = start + size + 3
            } else {
                at = start - 3
                break
            }
        }
        return { section: best.which, index: index, at: at }
    }

    function finishDrag() {
        const t = drag.target
        drag.active = false
        drag.target = null
        if (t) BarLayout.moveWidget(output, edge, drag.fromSection, drag.fromIndex, t.section, t.index)
    }

    // ── Bar menu ────────────────────────────────────────────────────────
    PopupWindow {
        id: menu
        anchor.window: bar
        anchor.rect.width: 1
        anchor.rect.height: 1
        anchor.gravity: (bar.edge === "bottom" ? Edges.Top : Edges.Bottom) | (bar.edge === "right" ? Edges.Left : Edges.Right)
        grabFocus: true
        color: "transparent"
        implicitWidth: 200
        implicitHeight: menuCol.implicitHeight + 12

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: Theme.glassStrong
            border.width: 1
            border.color: Theme.alpha(Theme.text, 0.10)

            Column {
                id: menuCol
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: 6 }
                spacing: 1

                MenuItem {
                    icon: "pencil"
                    label: Shell.editing ? "Done editing" : "Edit bars"
                    onActivated: { menu.visible = false; Shell.setEditing(!Shell.editing) }
                }
                MenuItem {
                    icon: "sliders"
                    label: "Quick settings"
                    onActivated: { menu.visible = false; Shell.toggleQuickSettings(bar.output, bar.edge) }
                }
            }
        }
    }

    component MenuItem: Rectangle {
        id: mi
        property string icon: ""
        property string label: ""
        signal activated()

        width: menuCol.width
        height: 32
        radius: 8
        color: miArea.containsMouse ? Theme.alpha(Theme.accent, 0.18) : "transparent"

        Row {
            anchors { fill: parent; leftMargin: 10 }
            spacing: 9
            Icon { anchors.verticalCenter: parent.verticalCenter; name: mi.icon; size: 14; color: Theme.subtext }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: mi.label
                color: Theme.text
                font { family: Theme.font; pixelSize: 12 }
            }
        }
        MouseArea {
            id: miArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mi.activated()
        }
    }

    // ── A section and, in the islands style, the island around it ───────
    component Slot: Item {
        id: slot

        required property string which
        readonly property var widgets: bar.config[which] || []
        readonly property bool empty: section.implicitWidth === 0 || section.implicitHeight === 0
        readonly property int pad: bar.islands ? 10 : 6
        // Empty sections stay as drop targets while editing.
        readonly property bool placeholder: Shell.editing && empty
        readonly property int along: placeholder ? 48 : (bar.vertical ? section.implicitHeight : section.implicitWidth) + pad * 2

        function cells() {
            const out = []
            for (const c of section.children)
                if (c.isCell && c.visible) out.push(c)
            return out
        }

        visible: widgets.length > 0 || Shell.editing
        width: bar.vertical ? bar.thickness : along
        height: bar.vertical ? along : bar.thickness

        // The center section stays centred while there is room, otherwise
        // it slides to sit between the other two instead of under them.
        function centred(total, size, startEnd, endStart) {
            const ideal = (total - size) / 2
            return Math.max(startEnd + 8, Math.min(ideal, endStart - size - 8))
        }

        x: bar.vertical ? 0
         : which === "start" ? 8
         : which === "end" ? bar.width - width - 8
         : centred(bar.width, width,
                   startSlot.visible ? startSlot.x + startSlot.width : 0,
                   endSlot.visible ? endSlot.x : bar.width)
        y: !bar.vertical ? 0
         : which === "start" ? 8
         : which === "end" ? bar.height - height - 8
         : centred(bar.height, height,
                   startSlot.visible ? startSlot.y + startSlot.height : 0,
                   endSlot.visible ? endSlot.y : bar.height)

        Island {
            visible: (bar.islands && !slot.empty) || slot.placeholder
            anchors.centerIn: parent
            width: bar.vertical ? 36 : parent.width
            height: bar.vertical ? parent.height : 34
            highlighted: drag.active && drag.target !== null && drag.target.section === slot.which
        }

        Text {
            visible: slot.placeholder
            anchors.centerIn: parent
            text: slot.which
            color: Theme.overlay
            font { family: Theme.font; pixelSize: 9 }
        }

        Grid {
            id: section
            anchors.centerIn: parent
            rows: bar.vertical ? -1 : 1
            columns: bar.vertical ? 1 : -1
            spacing: Shell.editing ? (bar.vertical ? 8 : 10) : (bar.vertical ? 4 : 7)
            verticalItemAlignment: Grid.AlignVCenter
            horizontalItemAlignment: Grid.AlignHCenter

            Repeater {
                model: slot.widgets
                delegate: Item {
                    id: cell
                    required property var modelData
                    required property int index
                    readonly property bool isCell: true
                    readonly property string name: Widgets.registry[modelData.id] ? Widgets.registry[modelData.id].name : modelData.id
                    // A widget hidden right now (no battery, CPU not hot)
                    // still shows as a named chip in edit mode.
                    readonly property bool live: loader.status === Loader.Ready && loader.item !== null
                                                 && loader.item.shown !== false && Widgets.available(modelData.id)

                    visible: live || (Shell.editing && modelData.id !== "")
                    implicitWidth: live ? loader.implicitWidth : (bar.vertical ? 30 : chipLabel.implicitWidth + 16)
                    implicitHeight: live ? loader.implicitHeight : (bar.vertical ? chipLabel.implicitWidth + 16 : 24)
                    opacity: drag.active && drag.fromSection === slot.which && drag.fromIndex === index ? 0.3 : 1

                    Loader {
                        id: loader
                        visible: cell.live
                        Component.onCompleted: {
                            const url = Widgets.url(cell.modelData.id)
                            if (url === "") {
                                if (cell.modelData.id !== "") console.warn("abyssal: unknown widget", cell.modelData.id)
                                return
                            }
                            setSource(url, { ctx: bar.contextFor(cell.modelData) })
                        }
                    }

                    Rectangle {
                        visible: Shell.editing && !cell.live
                        anchors.fill: parent
                        radius: 8
                        color: Theme.alpha(Theme.surface1, 0.7)
                        Text {
                            id: chipLabel
                            anchors.centerIn: parent
                            rotation: bar.vertical ? -90 : 0
                            // Short, so hidden widgets do not crowd the bar.
                            text: cell.name.length > 9 ? cell.name.slice(0, 8) + "…" : cell.name
                            color: Theme.overlay
                            font { family: Theme.font; pixelSize: 10 }
                        }
                    }

                    // Edit overlay: outline, drag anywhere on the widget,
                    // × in the corner removes it.
                    Rectangle {
                        visible: Shell.editing
                        anchors.fill: parent
                        anchors.margins: -3
                        radius: 9
                        color: dragArea.containsMouse ? Theme.alpha(Theme.cyan, 0.10) : "transparent"
                        border.width: 1
                        border.color: Theme.alpha(Theme.cyan, dragArea.containsMouse ? 0.9 : 0.45)

                        MouseArea {
                            id: dragArea
                            anchors.fill: parent
                            hoverEnabled: true
                            preventStealing: true
                            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                            property point pressAt
                            onPressed: mouse => pressAt = Qt.point(mouse.x, mouse.y)
                            onPositionChanged: mouse => {
                                if (!pressed) return
                                const p = mapToItem(content, mouse.x, mouse.y)
                                if (!drag.active && Math.hypot(mouse.x - pressAt.x, mouse.y - pressAt.y) > 4) {
                                    drag.label = cell.name
                                    drag.fromSection = slot.which
                                    drag.fromIndex = cell.index
                                    drag.active = true
                                }
                                if (drag.active) {
                                    drag.px = p.x
                                    drag.py = p.y
                                    drag.target = bar.dropTarget(p.x, p.y)
                                }
                            }
                            onReleased: if (drag.active) bar.finishDrag()
                        }

                        Rectangle {
                            width: 16
                            height: 16
                            radius: 8
                            x: parent.width - 11
                            y: -5
                            color: removeArea.containsMouse ? Theme.danger : Theme.surface1
                            border.width: 1
                            border.color: Theme.alpha(Theme.danger, 0.7)
                            Icon {
                                anchors.centerIn: parent
                                name: "x"
                                size: 10
                                stroke: 2.6
                                color: removeArea.containsMouse ? Theme.crust : Theme.danger
                            }
                            MouseArea {
                                id: removeArea
                                anchors.fill: parent
                                anchors.margins: -2
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: BarLayout.removeWidget(bar.output, bar.edge, slot.which, cell.index)
                            }
                        }
                    }
                }
            }
        }
    }
}
