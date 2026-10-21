import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Wayland
import Quickshell.Widgets
import "../components"
import "../services"

// Quick settings, opened from a bar on this monitor. Sits next to that bar
// (the right end of a horizontal bar, the top of a vertical one); bars'
// exclusive zones keep it clear of them. Click outside to close.
//
// The main view is a free 4-column grid (PanelLayout.quickMenu): toggle
// tiles (1×1 or 2×1), sliders (2×1 or 4×1), the header and the media
// player, packed densely in their saved order. The header's sliders
// button turns it into an editor: drag to move, ⤡ cycles an item's sizes,
// × removes it, the catalog adds items back. Tiles with a › slide in their
// detail page. Click the header icon to pick an image (right click resets).
Scope {
    id: root

    required property var screen
    readonly property var qs: Shell.quickSettings
    readonly property bool open: qs !== null && screen && qs.output === screen.name
    // Edge of the panel it last opened from, kept while it animates out.
    property string lastEdge: "top"
    onQsChanged: if (open) lastEdge = qs.edge
    readonly property string edge: lastEdge
    // The window stays up until the closing animation is done; the page and
    // edit mode reset only then, so closing doesn't jump back first.
    property bool shown: false
    // Detail page slid in over the main view: "", "wifi", "bluetooth", "sound".
    property string page: ""
    property bool editing: false
    onOpenChanged: if (open) shown = true
    onShownChanged: if (!shown) { page = ""; editing = false; dragFrom = -1 }

    readonly property int gap: 6
    readonly property int rowHeight: 58

    readonly property var catalog: ({
        header:    { label: "Header",          icon: "user",        sizes: [[4, 1]] },
        wifi:      { label: "Wi-Fi",           icon: "wifi",        sizes: [[2, 1], [1, 1]] },
        bluetooth: { label: "Bluetooth",       icon: "bluetooth",   sizes: [[2, 1], [1, 1]] },
        dnd:       { label: "Do not disturb",  icon: "bell-off",    sizes: [[1, 1], [2, 1]] },
        caffeine:  { label: "Caffeine",        icon: "coffee",      sizes: [[1, 1], [2, 1]] },
        mic:       { label: "Mic mute",        icon: "mic",         sizes: [[1, 1], [2, 1]] },
        layout:    { label: "Keyboard layout", icon: "keyboard",    sizes: [[1, 1], [2, 1]] },
        output:    { label: "Output device",   icon: "speaker",     sizes: [[2, 1], [1, 1]] },
        volume:    { label: "Volume",          icon: "volume-high", sizes: [[4, 1], [2, 1]] },
        micvolume: { label: "Mic volume",      icon: "mic",         sizes: [[4, 1], [2, 1]] },
        media:     { label: "Media player",    icon: "play",        sizes: [[4, 2], [2, 2]] }
    })
    // Ids this version doesn't know (an older or newer file) are skipped;
    // unavailable tiles too when hidden (never while editing).
    readonly property var allItems: PanelLayout.quickMenu.filter(i => catalog[i.id])
    readonly property var items: editing || !PanelLayout.quickMenuHideUnavailable ? allItems
        : allItems.filter(i => tileInfo(i.id).available !== false)
    readonly property var unused: Object.keys(catalog).filter(id => !allItems.some(i => i.id === id))

    // ── Editing ─────────────────────────────────────────────────────────
    function removeAt(i) {
        const list = items.slice()
        list.splice(i, 1)
        PanelLayout.setQuickMenu(list)
    }
    function cycleSize(i) {
        const list = items.map(x => Object.assign({}, x))
        const sizes = catalog[list[i].id].sizes
        const k = sizes.findIndex(s => s[0] === list[i].w && s[1] === list[i].h)
        const next = sizes[(k + 1) % sizes.length]
        list[i].w = next[0]
        list[i].h = next[1]
        PanelLayout.setQuickMenu(list)
    }
    function add(id) {
        const s = catalog[id].sizes[0]
        PanelLayout.setQuickMenu(items.concat([{ id: id, w: s[0], h: s[1] }]))
    }
    function moveItem(from, to) {
        if (from < 0 || to < 0 || from === to) return
        const list = items.slice()
        const moved = list.splice(from, 1)[0]
        list.splice(to, 0, moved)
        PanelLayout.setQuickMenu(list)
    }

    // While dragging, the other items reflow as if the dragged one were
    // already at `dragTo` (its index once removed and reinserted).
    property int dragFrom: -1
    property int dragTo: -1
    readonly property var order: {
        const o = items.map((_, i) => i)
        if (dragFrom < 0 || dragTo < 0) return o
        o.splice(dragFrom, 1)
        o.splice(dragTo, 0, dragFrom)
        return o
    }
    // Dense packing: each item takes the first free spot that fits it.
    readonly property var packed: {
        const taken = []
        const pos = []
        let rows = 0
        const fits = (r, c, w, h) => {
            if (c + w > 4) return false
            for (let y = r; y < r + h; y++)
                for (let x = c; x < c + w; x++)
                    if (taken[y] && taken[y][x]) return false
            return true
        }
        for (const i of order) {
            const w = Math.min(4, items[i].w), h = items[i].h
            let done = false
            for (let r = 0; !done; r++) {
                for (let c = 0; c <= 4 - w && !done; c++) {
                    if (!fits(r, c, w, h)) continue
                    for (let y = r; y < r + h; y++) {
                        taken[y] = taken[y] || []
                        for (let x = c; x < c + w; x++) taken[y][x] = true
                    }
                    pos[i] = { c: c, r: r, w: w, h: h }
                    rows = Math.max(rows, r + h)
                    done = true
                }
            }
        }
        return { pos: pos, rows: rows }
    }

    // What a toggle tile shows and does.
    function tileInfo(id) {
        switch (id) {
        case "wifi": {
            const on = Networking.wifiEnabled
            const net = SystemInfo.wifiNetwork
            return { icon: on ? "wifi" : "wifi-off", title: "Wi-Fi", on: on, accent: Theme.accent, page: "wifi",
                     detail: !on ? "Off" : net ? net.name : "Not connected",
                     action: () => Networking.wifiEnabled = !on }
        }
        case "bluetooth": {
            const a = Bluetooth.defaultAdapter
            const on = a !== null && a.enabled
            const n = a ? a.devices.values.filter(d => d.connected).length : 0
            return { icon: "bluetooth", title: "Bluetooth", on: on, accent: Theme.cyan, page: a ? "bluetooth" : "", available: a !== null,
                     detail: !a ? "No adapter" : !on ? "Off" : n ? n + " connected" : "On",
                     action: () => { if (a) a.enabled = !a.enabled } }
        }
        case "dnd":
            return { icon: Notifications.dnd ? "bell-off" : "bell", title: "Do not disturb", short: "Silence", on: Notifications.dnd,
                     accent: Theme.rose, detail: Notifications.dnd ? "Toasts hidden" : "Off",
                     action: () => Notifications.dnd = !Notifications.dnd }
        case "caffeine": {
            // Without anything that idles, the tile offers to set up
            // Abyssal's idle timer instead of doing nothing.
            const usable = Idle.configured || SystemInfo.idleDaemon
            return { icon: "coffee", title: "Caffeine", on: Shell.caffeine && usable, accent: Theme.warn,
                     available: usable, page: "idle", setup: !usable,
                     detail: !usable ? "Set up idle…" : Shell.caffeine ? "Staying awake" : "Off",
                     action: () => { if (usable) Shell.caffeine = !Shell.caffeine; else root.page = "idle" } }
        }
        case "mic":
            return { icon: Audio.micMuted ? "mic-off" : "mic", title: "Microphone", short: "Mic", on: Audio.micMuted, accent: Theme.rose,
                     detail: Audio.micMuted ? "Muted" : "Live", action: () => Audio.toggleMicMute() }
        case "layout": {
            const k = Tide.keyboardLayout
            const i = k ? k.current_idx : 0
            return { glyph: k && k.codes ? String(k.codes[i]).toUpperCase() : "··", title: "Layout", on: false,
                     accent: Theme.accent, detail: k && k.names ? k.names[i] : "Keyboard",
                     action: () => Tide.cycleLayout(true) }
        }
        case "output":
            return { icon: /head(set|phone)/i.test(Audio.sinkName) ? "headphones" : "speaker", title: "Output",
                     on: false, accent: Theme.accent, page: "sound",
                     detail: Audio.sink ? (Audio.sink.nickname || Audio.sinkName) : "None",
                     action: () => root.page = "sound" }
        }
        return { icon: "square", title: id, detail: "", on: false, accent: Theme.accent }
    }

    // Full-screen click catcher under the panel.
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
            onClicked: Shell.quickSettings = null
        }
    }

    PanelWindow {
        id: panel
        screen: root.screen
        visible: root.shown
        WlrLayershell.namespace: "abyssal-quick-settings"
        WlrLayershell.layer: WlrLayer.Overlay
        // The Wi-Fi page's password field needs the keyboard.
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        anchors.top: root.edge !== "bottom"
        anchors.bottom: root.edge === "bottom"
        anchors.left: root.edge === "left"
        anchors.right: root.edge !== "left"
        margins { top: 8; bottom: 8; left: 8; right: 8 }
        exclusiveZone: 0
        color: "transparent"
        implicitWidth: 380
        implicitHeight: card.implicitHeight

        onVisibleChanged: if (visible) SystemInfo.refreshUptime()

        Rectangle {
            id: card
            anchors.fill: parent
            implicitHeight: (root.page ? sub.implicitHeight : col.implicitHeight) + 32
            clip: true
            focus: true
            // Grows in from the bar's side and fades; closing reverses it.
            property real t: root.open ? 1 : 0
            Behavior on t { NumberAnimation { duration: root.open ? 220 : 150; easing.type: Easing.OutCubic } }
            onTChanged: if (t === 0 && !root.open) root.shown = false
            opacity: t
            scale: 0.95 + 0.05 * t
            transformOrigin: root.edge === "bottom" ? Item.BottomRight : root.edge === "left" ? Item.TopLeft : Item.TopRight

            Keys.onEscapePressed: {
                if (root.page) root.page = ""
                else if (root.editing) root.editing = false
                else Shell.quickSettings = null
            }
            radius: Theme.popupRadius
            color: Theme.glassStrong
            border.width: 1
            border.color: Theme.hairline

            ColumnLayout {
                id: col
                x: root.page ? -card.width + 16 : 16
                y: 16
                width: card.width - 32
                spacing: 12
                Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.InOutCubic } }

                // ── Grid ────────────────────────────────────────────────
                Item {
                    id: grid
                    Layout.fillWidth: true
                    implicitHeight: Math.max(root.rowHeight, root.packed.rows * (root.rowHeight + root.gap) - root.gap)
                    readonly property real cellWidth: (width - 3 * root.gap) / 4
                    Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                    // Item index whose slot is under (x, y), as an insert
                    // position among the others (after it on its right half).
                    function slotAt(x, y, self) {
                        const others = root.items.map((_, i) => i).filter(i => i !== self)
                        for (let k = 0; k < others.length; k++) {
                            const p = root.packed.pos[others[k]]
                            if (!p) continue
                            const left = p.c * (cellWidth + root.gap), top = p.r * (root.rowHeight + root.gap)
                            const w = p.w * cellWidth + (p.w - 1) * root.gap, h = p.h * root.rowHeight + (p.h - 1) * root.gap
                            if (x >= left && x < left + w && y >= top && y < top + h)
                                return x > left + w / 2 ? k + 1 : k
                        }
                        return -1
                    }

                    // Empty slots, as a guide while editing.
                    Repeater {
                        model: root.editing ? (root.packed.rows + 1) * 4 : 0
                        Rectangle {
                            required property int index
                            x: (index % 4) * (grid.cellWidth + root.gap)
                            y: Math.floor(index / 4) * (root.rowHeight + root.gap)
                            width: grid.cellWidth
                            height: root.rowHeight
                            radius: 13
                            color: Theme.alpha(Theme.text, 0.02)
                            visible: y < grid.height
                        }
                    }

                    Repeater {
                        model: root.items.length

                        delegate: Item {
                            id: cell
                            required property int index
                            readonly property var it: root.items[index] || ({ id: "", w: 1, h: 1 })
                            readonly property var p: root.packed.pos[index] || ({ c: 0, r: 0, w: 1, h: 1 })
                            readonly property bool dragged: root.dragFrom === index
                            property real dragX: 0
                            property real dragY: 0

                            x: dragged ? dragX : p.c * (grid.cellWidth + root.gap)
                            y: dragged ? dragY : p.r * (root.rowHeight + root.gap)
                            width: p.w * grid.cellWidth + (p.w - 1) * root.gap
                            height: p.h * root.rowHeight + (p.h - 1) * root.gap
                            z: dragged ? 5 : 1
                            scale: dragged ? 1.03 : 1
                            opacity: dragged ? 0.9 : 1
                            Behavior on x { enabled: !cell.dragged; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            Behavior on y { enabled: !cell.dragged; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            Behavior on scale { NumberAnimation { duration: 120 } }

                            Loader {
                                anchors.fill: parent
                                sourceComponent: cell.it.id === "header" ? headerTile
                                               : cell.it.id === "media" ? mediaTile
                                               : cell.it.id === "volume" || cell.it.id === "micvolume" ? sliderTile
                                               : toggleTile
                            }

                            // Editing: the whole item drags; handles on top.
                            Rectangle {
                                visible: root.editing
                                anchors.fill: parent
                                radius: 13
                                color: "transparent"
                                border.width: 1
                                border.color: dragArea.containsMouse || cell.dragged ? Theme.alpha(Theme.cyan, 0.6) : Theme.alpha(Theme.accent, 0.4)
                            }
                            MouseArea {
                                id: dragArea
                                visible: root.editing
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                                property point grab
                                onPressed: mouse => {
                                    grab = Qt.point(mouse.x, mouse.y)
                                    cell.dragX = cell.x
                                    cell.dragY = cell.y
                                    root.dragTo = cell.index
                                    root.dragFrom = cell.index
                                }
                                onPositionChanged: mouse => {
                                    if (!pressed) return
                                    const pt = mapToItem(grid, mouse.x, mouse.y)
                                    cell.dragX = pt.x - grab.x
                                    cell.dragY = pt.y - grab.y
                                    const slot = grid.slotAt(pt.x, pt.y, cell.index)
                                    if (slot >= 0) root.dragTo = slot
                                }
                                onReleased: {
                                    const from = root.dragFrom, to = root.dragTo
                                    root.dragFrom = -1
                                    root.dragTo = -1
                                    root.moveItem(from, to)
                                }
                            }
                            Handle {
                                visible: root.editing && !cell.dragged
                                x: -6; y: -6
                                icon: "x"
                                hoverColor: Theme.danger
                                onClicked: root.removeAt(cell.index)
                            }
                            Handle {
                                visible: root.editing && !cell.dragged && root.catalog[cell.it.id].sizes.length > 1
                                x: cell.width - 12; y: cell.height - 12
                                icon: "resize"
                                hoverColor: Theme.cyan
                                onClicked: root.cycleSize(cell.index)
                            }

                            // ── Item kinds (declared here so they see `cell`) ─
                            Component {
                                id: toggleTile
                                Rectangle {
                                    id: tile
                                    readonly property var info: root.tileInfo(cell.it.id)
                                    readonly property bool small: cell.p.w === 1
                                    readonly property bool usable: info.available !== false || info.setup === true
                                    readonly property color tint: info.on ? info.accent : Theme.subtext
                                    opacity: info.available !== false ? 1 : info.setup ? 0.7 : 0.4
                                    radius: 13
                                    color: tileArea.containsMouse ? Theme.alpha(Theme.text, 0.045) : Theme.alpha(Theme.text, 0.025)
                                    border.width: 1
                                    border.color: info.on ? Theme.alpha(info.accent, 0.3) : Theme.alpha(Theme.text, 0.07)
                                    Behavior on border.color { ColorAnimation { duration: Theme.anim } }

                                    // Soft light from the icon side when on.
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: parent.radius
                                        opacity: tile.info.on ? 1 : 0
                                        Behavior on opacity { NumberAnimation { duration: Theme.anim } }
                                        gradient: Gradient {
                                            orientation: Gradient.Horizontal
                                            GradientStop { position: 0; color: Theme.alpha(tile.info.accent, 0.14) }
                                            GradientStop { position: 0.75; color: "transparent" }
                                        }
                                    }

                                    MouseArea {
                                        id: tileArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: tile.usable ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: if (tile.usable && tile.info.action) tile.info.action()
                                    }

                                    // 1×1: icon over a small label.
                                    Column {
                                        visible: tile.small
                                        anchors.centerIn: parent
                                        spacing: 5
                                        Item {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: 18; height: 18
                                            Icon { anchors.centerIn: parent; visible: !tile.info.glyph; name: tile.info.icon || "square"; size: 17; stroke: 1.7; color: tile.tint }
                                            Text { anchors.centerIn: parent; visible: !!tile.info.glyph; text: tile.info.glyph || ""; color: tile.tint; font { family: Theme.font; pixelSize: 11; weight: Font.DemiBold; letterSpacing: 0.6 } }
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: Math.min(implicitWidth, tile.width - 8)
                                            text: tile.info.short || tile.info.title
                                            color: tile.info.on ? tile.info.accent : Theme.subtext
                                            elide: Text.ElideRight
                                            font { family: Theme.font; pixelSize: 10 }
                                        }
                                    }

                                    // 2×1: icon, title and state, optional ›.
                                    RowLayout {
                                        visible: !tile.small
                                        anchors { fill: parent; leftMargin: 13; rightMargin: tile.info.page ? 0 : 12 }
                                        spacing: 11
                                        Item {
                                            implicitWidth: 18; implicitHeight: 18
                                            Icon { anchors.centerIn: parent; visible: !tile.info.glyph; name: tile.info.icon || "square"; size: 17; stroke: 1.7; color: tile.tint }
                                            Text { anchors.centerIn: parent; visible: !!tile.info.glyph; text: tile.info.glyph || ""; color: tile.tint; font { family: Theme.font; pixelSize: 11; weight: Font.DemiBold; letterSpacing: 0.6 } }
                                        }
                                        ColumnLayout {
                                            spacing: 0
                                            Layout.fillWidth: true
                                            Text {
                                                text: tile.info.title
                                                color: Theme.text
                                                elide: Text.ElideRight
                                                font { family: Theme.font; pixelSize: 12 }
                                                Layout.fillWidth: true
                                            }
                                            Text {
                                                text: tile.info.detail
                                                color: tile.info.on ? Theme.alpha(tile.info.accent, 0.75) : Theme.overlay
                                                elide: Text.ElideRight
                                                font { family: Theme.font; pixelSize: 10 }
                                                Layout.fillWidth: true
                                            }
                                        }
                                        Item {
                                            visible: !!tile.info.page
                                            Layout.fillHeight: true
                                            implicitWidth: 34
                                            Rectangle {
                                                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                                                width: 1
                                                height: parent.height - 24
                                                color: Theme.alpha(Theme.text, 0.07)
                                            }
                                            Icon {
                                                anchors.centerIn: parent
                                                name: "chevron-right"
                                                size: 13
                                                color: chevArea.containsMouse ? Theme.text : Theme.overlay
                                            }
                                            MouseArea {
                                                id: chevArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.page = tile.info.page
                                            }
                                        }
                                    }
                                }
                            }

                            Component {
                                id: sliderTile
                                Rectangle {
                                    id: sl
                                    readonly property bool mic: cell.it.id === "micvolume"
                                    readonly property bool wide: cell.p.w >= 4
                                    readonly property real value: mic ? (Audio.micMuted ? 0 : Audio.micVolume) : (Audio.muted ? 0 : Audio.volume)
                                    radius: 13
                                    color: Theme.alpha(Theme.text, 0.025)
                                    border.width: 1
                                    border.color: Theme.alpha(Theme.text, 0.07)

                                    Text {
                                        x: 46; y: 8
                                        width: parent.width - 100
                                        text: sl.mic ? "Microphone" : (Audio.sink ? (Audio.sink.nickname || Audio.sinkName) : "No output")
                                        color: Theme.overlay
                                        elide: Text.ElideRight
                                        font { family: Theme.font; pixelSize: 10 }
                                    }
                                    RowLayout {
                                        anchors { fill: parent; leftMargin: 8; rightMargin: sl.wide && !sl.mic ? 2 : 12; topMargin: 12 }
                                        spacing: 8
                                        BarButton {
                                            implicitWidth: 30; implicitHeight: 30
                                            icon: sl.mic ? (Audio.micMuted ? "mic-off" : "mic")
                                                : Audio.muted || Audio.volume === 0 ? "volume-mute" : Audio.volume < 0.5 ? "volume-low" : "volume-high"
                                            iconSize: 16
                                            iconColor: Theme.subtext
                                            onClicked: sl.mic ? Audio.toggleMicMute() : Audio.toggleMute()
                                        }
                                        ThinSlider {
                                            Layout.fillWidth: true
                                            value: sl.value
                                            onMoved: v => sl.mic ? Audio.setMicVolume(v) : Audio.setVolume(v)
                                        }
                                        Text {
                                            visible: sl.wide
                                            text: Math.round(sl.value * 100)
                                            color: Theme.overlay
                                            horizontalAlignment: Text.AlignRight
                                            font { family: Theme.font; pixelSize: 10 }
                                            Layout.preferredWidth: 24
                                        }
                                        BarButton {
                                            visible: sl.wide && !sl.mic
                                            implicitWidth: 28; implicitHeight: 28
                                            icon: "chevron-right"
                                            iconSize: 13
                                            iconColor: Theme.overlay
                                            onClicked: root.page = "sound"
                                        }
                                    }
                                }
                            }

                            Component {
                                id: headerTile
                                RowLayout {
                                    spacing: 12
                                    // Click (any time) to pick an image; right click
                                    // goes back to the Abyssal mark.
                                    Rectangle {
                                        implicitWidth: 38
                                        implicitHeight: 38
                                        radius: 19
                                        color: Theme.alpha(Theme.cyan, 0.08)
                                        border.width: 1
                                        border.color: avatarArea.containsMouse ? Theme.alpha(Theme.cyan, 0.6) : Theme.alpha(Theme.text, 0.12)
                                        id: avatar
                                        readonly property string spec: cell.it.icon || "builtin:logo"
                                        readonly property bool image: spec.startsWith("file:")
                                        // An imported image fills the circle, cropped to fit.
                                        ClippingRectangle {
                                            visible: avatar.image
                                            anchors.fill: parent
                                            radius: width / 2
                                            color: "transparent"
                                            Image {
                                                anchors.fill: parent
                                                source: avatar.image ? "file://" + avatar.spec.slice(5).split("/").map(encodeURIComponent).join("/") : ""
                                                sourceSize.width: 96
                                                sourceSize.height: 96
                                                fillMode: Image.PreserveAspectCrop
                                                asynchronous: true
                                                smooth: true
                                                mipmap: true
                                            }
                                        }
                                        // The ring again, over the image.
                                        Rectangle {
                                            visible: avatar.image
                                            anchors.fill: parent
                                            radius: width / 2
                                            color: "transparent"
                                            border.width: 1
                                            border.color: avatar.border.color
                                        }
                                        CustomIcon {
                                            visible: !avatar.image
                                            anchors.centerIn: parent
                                            spec: avatar.spec
                                            size: 22
                                            tint: Theme.cyan
                                        }
                                        Rectangle {
                                            visible: avatarArea.containsMouse
                                            anchors { right: parent.right; bottom: parent.bottom; margins: -2 }
                                            width: 14; height: 14; radius: 7
                                            color: Theme.base
                                            border.width: 1
                                            border.color: Theme.alpha(Theme.text, 0.18)
                                            Icon { anchors.centerIn: parent; name: "pencil"; size: 8; color: Theme.text }
                                        }
                                        MouseArea {
                                            id: avatarArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: mouse => {
                                                if (mouse.button === Qt.RightButton) PanelLayout.setQuickMenuField("header", "icon", "")
                                                else Shell.pickHeaderIcon()
                                            }
                                        }
                                    }
                                    ColumnLayout {
                                        spacing: 0
                                        Layout.fillWidth: true
                                        Text {
                                            text: Quickshell.env("USER")
                                            color: Theme.text
                                            font { family: Theme.font; pixelSize: 13; weight: Font.Medium }
                                        }
                                        Text {
                                            readonly property int mins: Math.floor(SystemInfo.uptimeSec / 60)
                                            text: "up " + (mins >= 60 ? Math.floor(mins / 60) + "h " : "") + (mins % 60) + "m · TideWM"
                                            color: Theme.overlay
                                            font { family: Theme.font; pixelSize: 11 }
                                        }
                                    }
                                    BarButton { implicitWidth: 30; implicitHeight: 30; icon: "lock"; iconSize: 14; onClicked: Shell.lock() }
                                    BarButton { implicitWidth: 30; implicitHeight: 30; icon: "sliders"; iconSize: 14; active: root.editing; onClicked: root.editing = !root.editing }
                                    BarButton { implicitWidth: 30; implicitHeight: 30; icon: "power"; iconSize: 14; iconColor: Theme.danger; onClicked: Shell.togglePower(root.screen.name) }
                                }
                            }

                            Component {
                                id: mediaTile
                                Rectangle {
                                    radius: 13
                                    color: Theme.alpha(Theme.text, 0.025)
                                    border.width: 1
                                    border.color: Theme.alpha(Theme.text, 0.07)
                                    MediaTile {
                                        anchors.fill: parent
                                        compact: cell.p.w < 4
                                        active: root.open && !root.page
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Editing options and catalog ─────────────────────────
                RowLayout {
                    visible: root.editing
                    spacing: 10
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    Text {
                        text: "Hide unavailable tiles"
                        color: Theme.subtext
                        font { family: Theme.font; pixelSize: 11 }
                        Layout.fillWidth: true
                    }
                    Switch {
                        checked: PanelLayout.quickMenuHideUnavailable
                        onToggled: PanelLayout.setQuickMenuHideUnavailable(!checked)
                    }
                }
                SectionLabel {
                    visible: root.editing
                    text: root.unused.length ? "Add" : "Everything is in the menu"
                }
                Flow {
                    visible: root.editing && root.unused.length > 0
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: root.unused
                        TextButton {
                            required property string modelData
                            text: root.catalog[modelData].label
                            icon: "plus"
                            onClicked: root.add(modelData)
                        }
                    }
                }

                // ── Footer ──────────────────────────────────────────────
                RowLayout {
                    spacing: 8
                    Layout.fillWidth: true
                    TextButton {
                        visible: !root.editing
                        text: "Edit panels"
                        icon: "pencil"
                        onClicked: Shell.setEditing(true)
                    }
                    TextButton {
                        visible: root.editing
                        text: "Reset"
                        onClicked: PanelLayout.setQuickMenu(null)
                    }
                    Item { Layout.fillWidth: true }
                    TextButton {
                        visible: root.editing
                        text: "Done"
                        accent: true
                        onClicked: root.editing = false
                    }
                }
            }

            // The page slides in from the right; its back button returns.
            Loader {
                id: sub
                x: root.page ? 16 : card.width + 16
                y: 16
                width: card.width - 32
                active: root.page !== ""
                source: root.page === "wifi" ? "WifiPage.qml"
                      : root.page === "bluetooth" ? "BluetoothPage.qml"
                      : root.page === "sound" ? "SoundPage.qml"
                      : root.page === "idle" ? "IdlePage.qml" : ""
                Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.InOutCubic } }
                onLoaded: {
                    item.showBack = true
                    item.active = Qt.binding(() => root.open && root.page !== "")
                    item.back.connect(() => root.page = "")
                }
            }
        }
    }

    // Small round edit handle (remove, resize).
    component Handle: Rectangle {
        id: h
        property string icon: "x"
        property color hoverColor: Theme.accent
        signal clicked()
        z: 6
        width: 18
        height: 18
        radius: 9
        color: Theme.base
        border.width: 1
        border.color: ha.containsMouse ? hoverColor : Theme.alpha(Theme.text, 0.18)
        Icon { anchors.centerIn: parent; name: h.icon; size: 10; color: ha.containsMouse ? h.hoverColor : Theme.subtext }
        MouseArea {
            id: ha
            anchors.fill: parent
            anchors.margins: -3
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: h.clicked()
        }
    }
}
