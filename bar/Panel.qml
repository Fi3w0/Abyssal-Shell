import QtQuick
import Quickshell
import Quickshell.Wayland
import "../components"
import "../edit"
import "../services"

// One panel on one edge of one monitor: a taskbar, a top bar or a dock,
// depending only on its settings (see PanelLayout). Its items form one row;
// spacers split the row into groups.
//
//   fill     one strip along the whole edge
//   fit      one pill around the content, aligned
//   islands  one pill per group, spacers share the free space (three
//            groups keep the middle one truly centred)
//   custom   one strip of `length` percent, aligned
//
// Edit mode: click a panel to select it (its settings pop out), drag items
// to move them, × removes, click a widget with options to change them.
PanelWindow {
    id: panel

    required property var config        // one entry of PanelLayout.panelsFor()
    readonly property string edge: config.edge
    readonly property string output: screen ? screen.name : ""
    readonly property bool vertical: edge === "left" || edge === "right"
    readonly property string mode: config.width
    readonly property bool islands: mode === "islands"
    readonly property int thickness: config.size
    readonly property int gap: config.floating ? 6 : 0
    readonly property real along: vertical ? height : width
    // Content sits on the screen-edge side, `gap` away from it.
    readonly property real crossStart: (edge === "top" || edge === "left") ? gap : 0
    readonly property real radius: config.floating || islands ? Math.min(thickness / 2, Theme.square ? 10 : 18) : 0
    readonly property bool editing: Shell.editing
    readonly property bool selected: Shell.isEditTarget(output, edge)

    // Auto-hide reveal: hover, an open menu, or edit mode keep it out.
    property bool hovered: false
    readonly property bool autohide: config.visibility === "autohide"
    readonly property bool revealed: !autohide || hovered || editing || menu.visible
                                     || (Shell.quickSettings !== null && Shell.quickSettings.output === output)
    readonly property int hotStrip: 3

    WlrLayershell.namespace: "abyssal-panel"
    WlrLayershell.layer: WlrLayer.Top

    anchors.top: edge !== "bottom"
    anchors.bottom: edge !== "top"
    anchors.left: edge !== "right"
    anchors.right: edge !== "left"
    implicitHeight: thickness + gap
    implicitWidth: thickness + gap
    exclusiveZone: config.visibility === "always" ? thickness + gap : 0
    color: "transparent"

    // While hidden only the thin edge strip takes input.
    mask: revealed ? null : hotRegion
    Region { id: hotRegion; item: hot }
    Item {
        id: hot
        x: panel.edge === "right" ? panel.width - panel.hotStrip : 0
        y: panel.edge === "bottom" ? panel.height - panel.hotStrip : 0
        width: panel.vertical ? panel.hotStrip : panel.width
        height: panel.vertical ? panel.height : panel.hotStrip
    }
    HoverHandler {
        onHoveredChanged: {
            if (hovered) { hideDelay.stop(); panel.hovered = true }
            else hideDelay.restart()
        }
    }
    Timer { id: hideDelay; interval: 450; onTriggered: panel.hovered = false }

    function contextFor(item, index) {
        return { output: panel.output, edge: panel.edge, vertical: panel.vertical,
                 thickness: panel.thickness, index: index, options: item,
                 leading: index === 0, trailing: index === config.items.length - 1 }
    }

    // ── Segments: groups of widgets split by spacers ────────────────────
    readonly property var segments: {
        const out = []
        let group = null
        config.items.forEach((item, i) => {
            if (item.id === "spacer") {
                group = null
                out.push({ kind: "spacer", index: i, gap: Math.max(0, Math.min(200, Number(item.gap ?? 10) || 0)) })
            } else {
                if (!group) { group = { kind: "group", items: [] }; out.push(group) }
                group.items.push({ item: item, index: i })
            }
        })
        return out
    }

    // Offsets and lengths along the edge, one per segment; recomputed in
    // relayout() whenever a size changes.
    property var pos: []
    property var lens: []
    property real boxStart: 0
    property real boxLen: 0

    function queueRelayout() { relayoutTimer.restart() }
    Timer { id: relayoutTimer; interval: 0; onTriggered: panel.relayout() }
    onWidthChanged: queueRelayout()
    onHeightChanged: queueRelayout()
    onSegmentsChanged: queueRelayout()
    onEditingChanged: queueRelayout()
    onConfigChanged: queueRelayout()

    function alignIn(space, size) {
        return config.align === "start" ? 0 : config.align === "end" ? space - size : (space - size) / 2
    }

    function relayout() {
        const n = segments.length
        const natural = []
        let groupsTotal = 0
        let spacers = 0
        for (let i = 0; i < n; i++) {
            const it = segs.itemAt(i)
            if (segments[i].kind === "spacer") { natural.push(0); spacers++; continue }
            const len = it ? (vertical ? it.implicitHeight : it.implicitWidth) : 0
            natural.push(len)
            groupsTotal += len
        }
        const minimums = segments.map(s => s.kind === "spacer" ? Math.max(editing ? 56 : 0, s.gap) : 0)
        const spacerTotal = minimums.reduce((a, b) => a + b, 0)
        const pad = islands ? 0 : 10
        const full = along - 2 * gap
        let box = mode === "fit" ? groupsTotal + spacerTotal + 2 * pad
                : mode === "custom" ? Math.max(groupsTotal + spacerTotal + 2 * pad, full * config.length / 100)
                : full
        box = Math.min(box, full)
        const start = gap + (mode === "fit" || mode === "custom" ? alignIn(full, box) : 0)
        const inner = box - 2 * pad
        const free = Math.max(0, inner - groupsTotal - spacerTotal)

        const out = natural.map((len, i) => segments[i].kind === "spacer"
            ? minimums[i] + (mode === "fit" ? 0 : free / Math.max(1, spacers)) : len)

        // left · spacer · middle · spacer · right: keep the middle centred.
        const kinds = segments.map(s => s.kind).join(",")
        if (mode !== "fit" && kinds === "group,spacer,group,spacer,group" && natural[2] > 0) {
            const rest = inner - natural[0] - natural[2] - natural[4]
            const left = Math.max(minimums[1], Math.min((inner - natural[2]) / 2 - natural[0], rest - minimums[3]))
            out[1] = left
            out[3] = rest - left
        }

        let cursor = start + pad + (spacers === 0 && mode !== "fit" ? alignIn(inner, groupsTotal) : 0)
        const p = []
        for (let i = 0; i < n; i++) { p.push(cursor); cursor += out[i] }
        pos = p
        lens = out
        boxStart = start
        boxLen = box
    }

    // ── Drag and drop (edit mode) ───────────────────────────────────────
    QtObject {
        id: drag
        property bool active: false
        property string label: ""
        property int from: -1
        property real px: 0
        property real py: 0
        property var target: null      // { index, at }
    }

    // Every item handle in order, with its span along the edge.
    function handles() {
        const out = []
        for (let i = 0; i < segs.count; i++) {
            const seg = segs.itemAt(i)
            if (!seg) continue
            if (seg.isSpacer) {
                const p = seg.mapToItem(content, 0, 0)
                out.push({ index: seg.modelData.index, start: vertical ? p.y : p.x, len: vertical ? seg.height : seg.width })
            } else {
                for (const c of seg.cells()) {
                    const p = c.mapToItem(content, 0, 0)
                    out.push({ index: c.index, start: vertical ? p.y : p.x, len: vertical ? c.height : c.width })
                }
            }
        }
        return out
    }

    function dropTarget(px, py) {
        const along = vertical ? py : px
        let index = 0
        let at = boxStart + 6
        for (const h of handles()) {
            if (h.index === drag.from) continue
            if (along > h.start + h.len / 2) { index++; at = h.start + h.len + 3 }
            else { at = h.start - 3; break }
        }
        return { index: index, at: at }
    }

    // Drag coordinates are measured in the content item.
    readonly property Item contentRoot: content

    function startDrag(index, label) {
        drag.from = index
        drag.label = label
        drag.active = true
    }
    function moveDrag(p) {
        drag.px = p.x
        drag.py = p.y
        drag.target = dropTarget(p.x, p.y)
    }
    function finishDrag() {
        const t = drag.target
        drag.active = false
        drag.target = null
        if (t) PanelLayout.moveItem(output, edge, drag.from, t.index)
    }

    // ── Content, slid off-screen while auto-hidden ──────────────────────
    Item {
        id: content
        width: panel.width
        height: panel.height
        x: panel.revealed ? 0 : (panel.edge === "left" ? -panel.width : panel.edge === "right" ? panel.width : 0)
        y: panel.revealed ? 0 : (panel.edge === "top" ? -panel.height : panel.edge === "bottom" ? panel.height : 0)
        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        // Clicks on the panel's empty space: select it (edit mode) or the
        // right-click menu.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton) {
                    if (panel.editing) Shell.selectPanel(panel.output, panel.edge)
                    return
                }
                menu.anchor.rect.x = mouse.x
                menu.anchor.rect.y = mouse.y
                menu.visible = true
            }
        }

        // One background for fill / fit / custom.
        Rectangle {
            visible: !panel.islands && panel.boxLen > 0
            x: panel.vertical ? panel.crossStart : panel.boxStart
            y: panel.vertical ? panel.boxStart : panel.crossStart
            width: panel.vertical ? panel.thickness : panel.boxLen
            height: panel.vertical ? panel.boxLen : panel.thickness
            radius: panel.radius
            color: panel.config.look === "solid" ? Theme.base : Theme.glass
            border.width: 1
            border.color: panel.config.floating ? Theme.hairline : "transparent"

            // Flush panels get a hairline on their inner edge only.
            Rectangle {
                visible: !panel.config.floating
                color: Theme.alpha(Theme.text, 0.10)
                width: panel.vertical ? 1 : parent.width
                height: panel.vertical ? parent.height : 1
                x: panel.edge === "left" ? parent.width - 1 : 0
                y: panel.edge === "top" ? parent.height - 1 : 0
            }
        }

        // Edit mode outline: solid on the selected panel.
        Rectangle {
            visible: panel.editing
            x: panel.vertical ? panel.crossStart - 3 : 3
            y: panel.vertical ? 3 : panel.crossStart - 3
            width: panel.vertical ? panel.thickness + 6 : panel.width - 6
            height: panel.vertical ? panel.height - 6 : panel.thickness + 6
            radius: panel.radius + 3
            color: "transparent"
            border.width: panel.selected ? 2 : 1
            border.color: Theme.alpha(Theme.cyan, panel.selected ? 0.9 : 0.35)
        }

        Repeater {
            id: segs
            model: panel.segments

            delegate: Item {
                id: seg
                required property var modelData
                required property int index
                readonly property bool isSpacer: modelData.kind === "spacer"
                readonly property int gpad: panel.islands ? 10 : 0
                readonly property bool empty: !isSpacer && (row.implicitWidth === 0 || row.implicitHeight === 0)

                function cells() {
                    const out = []
                    for (const c of row.children)
                        if (c.isCell && c.visible) out.push(c)
                    return out
                }

                implicitWidth: isSpacer || empty ? 0 : (panel.vertical ? panel.thickness : row.implicitWidth + gpad * 2)
                implicitHeight: isSpacer || empty ? 0 : (panel.vertical ? row.implicitHeight + gpad * 2 : panel.thickness)
                onImplicitWidthChanged: panel.queueRelayout()
                onImplicitHeightChanged: panel.queueRelayout()

                readonly property real len: panel.lens[index] ?? 0
                x: panel.vertical ? panel.crossStart : (panel.pos[index] ?? 0)
                y: panel.vertical ? (panel.pos[index] ?? 0) : panel.crossStart
                width: panel.vertical ? panel.thickness : (isSpacer ? len : implicitWidth)
                height: panel.vertical ? (isSpacer ? len : implicitHeight) : panel.thickness

                // Islands: one pill per group.
                Island {
                    visible: panel.islands && !seg.isSpacer && !seg.empty
                    anchors.centerIn: parent
                    width: panel.vertical ? panel.thickness - 8 : parent.width
                    height: panel.vertical ? parent.height : panel.thickness - 8
                    radius: Math.min(width, height) / 2
                    color: panel.config.look === "solid" ? Theme.base : Theme.glass
                }

                // A spacer shows itself only while editing.
                Rectangle {
                    visible: seg.isSpacer && panel.editing
                    anchors.centerIn: parent
                    width: panel.vertical ? 26 : parent.width - 8
                    height: panel.vertical ? parent.height - 8 : 26
                    radius: 13
                    color: Theme.alpha(Theme.cyan, 0.06)
                    border.width: 1
                    border.color: Theme.alpha(Theme.cyan, 0.45)
                    Text {
                        anchors.centerIn: parent
                        rotation: panel.vertical ? -90 : 0
                        text: "spacer"
                        color: Theme.cyan
                        font { family: Theme.font; pixelSize: 9 }
                    }
                    EditHandle {
                        anchors.fill: parent
                        panelRoot: panel
                        index: seg.isSpacer ? seg.modelData.index : -1
                        label: "Spacer"
                        drawOutline: false
                    }
                }

                Grid {
                    id: row
                    visible: !seg.isSpacer
                    anchors.centerIn: parent
                    rows: panel.vertical ? -1 : 1
                    columns: panel.vertical ? 1 : -1
                    // Negative spacing rides on the cells' own padding.
                    spacing: panel.editing ? Math.max(panel.config.spacing, panel.vertical ? 8 : 10)
                        : Math.max(0, panel.config.spacing)
                    verticalItemAlignment: Grid.AlignVCenter
                    horizontalItemAlignment: Grid.AlignHCenter

                    Repeater {
                        model: seg.isSpacer ? [] : seg.modelData.items
                        delegate: Item {
                            id: cell
                            required property var modelData
                            readonly property bool isCell: true
                            readonly property int index: modelData.index
                            readonly property var item: modelData.item
                            // Hidden right now (no battery, CPU not hot): a
                            // named chip in edit mode, nothing otherwise.
                            readonly property bool live: loader.status === Loader.Ready && loader.item !== null
                                                         && loader.item.shown !== false && item.enabled !== false && Widgets.available(item.id)
                            // Per-widget gap: pads both sides, so two neighbours
                            // get one padding each plus the panel spacing.
                            // Negative values pull neighbours together; each
                            // side pads itself so both widgets share the gap.
                            readonly property int ownGap: Math.max(-16, Math.min(16,
                                item.spacing !== undefined && Number.isFinite(Number(item.spacing)) ? Number(item.spacing) : 0))
                            readonly property real panelPad: panel.config.spacing < 0 ? panel.config.spacing / 2 : 0
                            readonly property real pad: panelPad + ownGap
                            readonly property real minimumContentWidth: loader.item && loader.item.minimumContentWidth !== undefined
                                ? loader.item.minimumContentWidth : loader.implicitWidth
                            readonly property real minimumContentHeight: loader.item && loader.item.minimumContentHeight !== undefined
                                ? loader.item.minimumContentHeight : loader.implicitHeight

                            visible: live || (panel.editing && item.id !== "")
                            // Negative padding shrinks the slot, including its
                            // input area. A child's original MouseArea must
                            // never reach over the neighbouring widget.
                            clip: !panel.editing
                            implicitWidth: live
                                ? Math.max(minimumContentWidth, loader.implicitWidth + (panel.vertical ? 0 : pad * 2))
                                : (panel.vertical ? 30 : chip.implicitWidth + 16)
                            implicitHeight: live
                                ? Math.max(minimumContentHeight, loader.implicitHeight + (panel.vertical ? pad * 2 : 0))
                                : (panel.vertical ? chip.implicitWidth + 16 : 24)
                            opacity: drag.active && drag.from === index ? 0.3 : 1

                            Loader {
                                id: loader
                                visible: cell.live
                                anchors.centerIn: parent
                                Component.onCompleted: {
                                    const url = Widgets.url(cell.item.id)
                                    if (url === "") {
                                        if (cell.item.id !== "") console.warn("abyssal: unknown widget", cell.item.id)
                                        return
                                    }
                                    setSource(url, { ctx: panel.contextFor(cell.item, cell.index) })
                                }
                            }

                            Rectangle {
                                visible: panel.editing && !cell.live
                                anchors.fill: parent
                                radius: 8
                                color: Theme.alpha(Theme.surface1, 0.7)
                                Text {
                                    id: chip
                                    anchors.centerIn: parent
                                    rotation: panel.vertical ? -90 : 0
                                    readonly property string full: Widgets.name(cell.item.id)
                                    text: full.length > 9 ? full.slice(0, 8) + "…" : full
                                    color: Theme.overlay
                                    font { family: Theme.font; pixelSize: 10 }
                                }
                            }

                            EditHandle {
                                visible: panel.editing
                                readonly property real shift: cell.live && loader.item
                                    && loader.item.visualOffsetX !== undefined ? loader.item.visualOffsetX : 0
                                anchors.fill: parent
                                anchors.leftMargin: -3 + shift
                                anchors.rightMargin: -3 - shift
                                anchors.topMargin: -3
                                anchors.bottomMargin: -3
                                panelRoot: panel
                                index: cell.index
                                label: Widgets.name(cell.item.id)
                                hasOptions: Widgets.options(cell.item.id).length > 0
                            }
                        }
                    }
                }
            }
        }

        // Drag ghost and drop indicator.
        Rectangle {
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
        Rectangle {
            visible: drag.active && drag.target !== null
            z: 99
            color: Theme.cyan
            radius: 1
            width: panel.vertical ? panel.thickness - 12 : 2
            height: panel.vertical ? 2 : panel.thickness - 12
            x: drag.target ? (panel.vertical ? panel.crossStart + 6 : drag.target.at - 1) : 0
            y: drag.target ? (panel.vertical ? drag.target.at - 1 : panel.crossStart + 6) : 0
        }
    }

    // ── Popups ──────────────────────────────────────────────────────────
    PanelSettings {
        panelWindow: panel
        config: panel.config
        output: panel.output
        visible: panel.selected && !Shell.pickingPosition
    }

    PopupWindow {
        id: menu
        anchor.window: panel
        anchor.rect.width: 1
        anchor.rect.height: 1
        anchor.gravity: (panel.edge === "bottom" ? Edges.Top : Edges.Bottom) | (panel.edge === "right" ? Edges.Left : Edges.Right)
        grabFocus: true
        color: "transparent"
        implicitWidth: 210
        implicitHeight: menuCol.implicitHeight + 12

        // Accept every button: Qt (6.8+) turns a click nothing accepted into a
        // context-menu event, and delivering that while the popup's items are
        // being torn down crashed in QQuickItem::mapToScene.
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

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
                    label: Shell.editing ? "Done editing" : "Edit panels"
                    onActivated: {
                        menu.visible = false
                        if (Shell.editing) Shell.setEditing(false)
                        else { Shell.setEditing(true); Shell.selectPanel(panel.output, panel.edge) }
                    }
                }
                MenuItem {
                    icon: "sliders"
                    label: "Quick settings"
                    onActivated: { menu.visible = false; Shell.toggleQuickSettings(panel.output, panel.edge) }
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
}
