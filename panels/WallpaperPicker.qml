import QtQuick
import QtQuick.Dialogs
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../components"
import "../services"

// Wallpaper picker: a looping depth carousel on one monitor, and only that
// monitor changes. It opens where you are working; moving the pointer onto
// another monitor moves it there (an invisible layer on the other monitors
// notices the pointer, which TideWM doesn't report otherwise). The selected card faces you (videos
// play in it), the others turn away and sink; behind it all, the selected
// wallpaper, blurred.
//   ← → / A D   move; hold to spin faster, let go and it coasts to a stop
//   Enter       apply and close (click the selected card too)
//   W           theme from wallpaper on/off: the shell's colours follow the
//               wallpaper (previewed here while you browse)
//   /           search; Esc leaves the search, then closes
PanelWindow {
    id: root

    required property string output
    readonly property bool open: Shell.wallpaperOn === output
    property bool shown: false
    onOpenChanged: {
        if (open) {
            shown = true
            query = ""
            searching = false
            Wallpaper.scan()
            jumpToCurrent()
        }
    }

    WlrLayershell.namespace: "abyssal-wallpaper"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: -1
    color: "transparent"
    visible: shown

    // ── What is listed ──────────────────────────────────────────────────
    property string filter: "all"
    property string query: ""
    property bool searching: false
    readonly property var list: Wallpaper.index.filter(w =>
        (filter === "all" || (filter === "videos") === (w.kind === "video"))
        && (!query || w.name.toLowerCase().includes(query.toLowerCase())))
    readonly property int n: list.length
    onListChanged: { if (!open) return; pos = 0; target = 0; mode = "idle"; jumpToCurrent() }

    readonly property string current: Wallpaper.currentFor(output)
    function jumpToCurrent() {
        const i = list.findIndex(w => w.path === current)
        if (i >= 0) { pos = i; target = i; mode = "idle" }
    }

    function wrap(i) { return n ? ((i % n) + n) % n : 0 }
    readonly property int index: wrap(Math.round(pos))
    readonly property var focused: n ? list[index] : null

    // ── Motion: taps step one card, holding spins up, letting go coasts ─
    property real pos: 0          // continuous card position
    property real target: 0
    property real vel: 0          // cards per second
    property real decel: 0
    property int held: 0          // -1 / 0 / 1
    property real holdTime: 0
    property string mode: "idle"  // idle | snap | spin | coast
    readonly property real spinAfter: 0.3
    readonly property real maxSpeed: 22

    function stepBy(dir) {
        if (!n) return
        target = Math.round(mode === "snap" ? target : pos) + dir
        mode = "snap"
    }
    function goTo(i) {
        // Shortest way round the loop.
        let d = wrap(i - Math.round(pos))
        if (d > n / 2) d -= n
        target = Math.round(pos) + d
        mode = "snap"
    }
    function press(dir) {
        held = dir
        holdTime = 0
        stepBy(dir)
    }
    function release(dir) {
        if (held !== dir) return
        held = 0
        if (mode === "spin") {
            // The faster it spun, the longer it coasts: up to ~2.5 s.
            const t = 0.6 + 1.9 * Math.min(1, Math.abs(vel) / maxSpeed)
            decel = Math.abs(vel) / t
            mode = "coast"
        }
    }
    function step(dt) {
        dt = Math.min(dt, 0.05)
        if (held) {
            holdTime += dt
            if (holdTime > spinAfter && mode !== "spin") { mode = "spin"; vel = held * 6 }
        }
        if (mode === "spin") {
            vel = Math.max(-maxSpeed, Math.min(maxSpeed, vel + held * 16 * dt))
            pos += vel * dt
        } else if (mode === "coast") {
            const s = Math.sign(vel)
            vel -= s * decel * dt
            if (Math.sign(vel) !== s || Math.abs(vel) < 2) {
                target = s > 0 ? Math.ceil(pos) : Math.floor(pos)
                mode = "snap"
            } else {
                pos += vel * dt
            }
        } else if (mode === "snap") {
            const d = target - pos
            pos += Math.sign(d) * Math.min(Math.abs(d), Math.max(Math.abs(d) * 14 * dt, 1.2 * dt))
            if (Math.abs(target - pos) < 0.001) {
                pos = target = wrap(target)
                mode = "idle"
            }
        }
    }
    FrameAnimation {
        running: root.shown && (root.mode !== "idle" || root.held !== 0)
        onTriggered: root.step(frameTime)
    }
    // Settled on a card for a moment: start its video preview.
    property bool settled: false
    onIndexChanged: { settled = false; settle.restart() }
    onModeChanged: if (mode !== "idle") settled = false; else settle.restart()
    Timer { id: settle; interval: 380; onTriggered: root.settled = root.mode === "idle" }

    // ── Theme from wallpaper ────────────────────────────────────────────
    // While it is on, the picker wears the selected card's palette, so you
    // see the theme before applying.
    readonly property bool themed: Appearance.fromWallpaper
    readonly property var pal: themed && focused && focused.palette ? focused.palette : null
    property color cAccent: pal ? pal.accent : Theme.accent
    property color cCyan: pal ? pal.cyan : Theme.cyan
    property color cText: pal ? pal.text : Theme.text
    property color cSub: pal ? pal.subtext : Theme.subtext
    property color cBase: pal ? pal.base : Theme.base
    property color cCrust: pal ? pal.crust : Theme.crust
    Behavior on cAccent { ColorAnimation { duration: 260 } }
    Behavior on cCyan { ColorAnimation { duration: 260 } }
    Behavior on cText { ColorAnimation { duration: 260 } }
    Behavior on cSub { ColorAnimation { duration: 260 } }
    Behavior on cBase { ColorAnimation { duration: 260 } }
    Behavior on cCrust { ColorAnimation { duration: 260 } }

    function themeFrom(w) {
        const base = Themes.themes[Appearance.theme] || {}
        const t = { name: "From wallpaper", source: w.path, shape: base.shape || "pill", colors: w.palette }
        for (const k of ["mono", "glass", "glassStrong", "radius"]) if (base[k] !== undefined) t[k] = base[k]
        return t
    }
    function toggleTheme() {
        const on = !Appearance.fromWallpaper
        if (on) {
            // Start from what is on this monitor now.
            const w = Wallpaper.index.find(x => x.path === current) || focused
            if (w && w.palette) Themes.save("wallpaper", themeFrom(w))
        }
        Appearance.set("fromWallpaper", on)
    }
    function apply() {
        const w = focused
        if (!w) return
        Wallpaper.apply(output, w.path, w.kind)
        if (Appearance.fromWallpaper && w.palette) Themes.save("wallpaper", themeFrom(w))
        close()
    }

    function close() { Shell.wallpaperOn = "" }

    FileDialog {
        id: browse
        title: "Choose a wallpaper"
        nameFilters: ["Images and videos (*.jpg *.jpeg *.png *.webp *.gif *.avif *.mp4 *.mkv *.webm *.mov)", "All files (*)"]
        onAccepted: {
            const path = decodeURIComponent(selectedFile.toString().replace(/^file:\/\//, ""))
            const video = /\.(mp4|mkv|webm|mov|avi|m4v|gif)$/i.test(path)
            Wallpaper.apply(root.output, path, video ? "video" : "image")
            Wallpaper.addFolder(path.replace(/\/[^/]*$/, ""))
        }
    }

    // ── Look ────────────────────────────────────────────────────────────
    readonly property int cardW: Math.round(Math.min(width * 0.32, height * 0.52))
    readonly property int cardH: Math.round(cardW * 9 / 16)

    Item {
        id: stage
        anchors.fill: parent
        focus: true

        property real t: root.open ? 1 : 0
        Behavior on t { NumberAnimation { duration: root.open ? 280 : 180; easing.type: Easing.OutCubic } }
        onTChanged: if (t === 0 && !root.open) root.shown = false
        opacity: t

        Keys.onPressed: e => {
            if (root.searching) {
                if (e.key === Qt.Key_Escape) { root.searching = false; stage.forceActiveFocus(); e.accepted = true }
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { root.apply(); e.accepted = true }
                return
            }
            const left = e.key === Qt.Key_Left || e.key === Qt.Key_A
            const right = e.key === Qt.Key_Right || e.key === Qt.Key_D
            if (left || right) { if (!e.isAutoRepeat) root.press(left ? -1 : 1); e.accepted = true }
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { root.apply(); e.accepted = true }
            else if (e.key === Qt.Key_W) { root.toggleTheme(); e.accepted = true }
            else if (e.key === Qt.Key_Slash || (e.key === Qt.Key_F && (e.modifiers & Qt.ControlModifier))) {
                root.searching = true; search.forceActiveFocus(); e.accepted = true
            }
            else if (e.key === Qt.Key_Escape) { root.close(); e.accepted = true }
        }
        Keys.onReleased: e => {
            if (e.isAutoRepeat) return
            if (e.key === Qt.Key_Left || e.key === Qt.Key_A) root.release(-1)
            else if (e.key === Qt.Key_Right || e.key === Qt.Key_D) root.release(1)
        }
        Connections {
            target: root
            function onOpenChanged() { if (root.open) stage.forceActiveFocus() }
        }

        // Behind everything: the selected wallpaper, blurred and sunk.
        Rectangle { anchors.fill: parent; color: root.cCrust }
        Image {
            id: backdrop
            anchors.fill: parent
            source: root.focused && root.focused.thumb ? "file://" + root.focused.thumb : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: backdrop
            blurEnabled: true
            blur: 1.0
            blurMax: 64
            saturation: 0.1
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.alpha(root.cCrust, 0.55) }
                GradientStop { position: 0.5; color: Theme.alpha(root.cCrust, 0.35) }
                GradientStop { position: 1.0; color: Theme.alpha(root.cCrust, 0.92) }
            }
        }

        // Click on the empty backdrop closes; the wheel moves.
        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
            onWheel: w => root.stepBy(w.angleDelta.y + w.angleDelta.x > 0 ? -1 : 1)
        }

        // ── Header ──────────────────────────────────────────────────────
        Column {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: carousel.top; bottomMargin: root.cardH * 0.18 }
            spacing: 6
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "WALLPAPER · " + root.output
                color: root.cCyan
                font { family: Theme.font; pixelSize: 11; bold: true; letterSpacing: 1.6 }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(implicitWidth, root.width * 0.7)
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: root.focused ? root.focused.name : Wallpaper.scanning ? "Looking for wallpapers…" : "No wallpapers found"
                color: root.cText
                font { family: Theme.font; pixelSize: 24; bold: true }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: {
                    const w = root.focused
                    if (!w) return root.query ? "Nothing matches “" + root.query + "”" : "Add some to " + Wallpaper.picturesDir + "/wallpapers or press Browse"
                    const parts = [w.kind === "video" ? "Video" : "Image"]
                    if (w.width) parts.push(w.width + "×" + w.height)
                    if (w.kind === "video" && w.duration) parts.push(Math.floor(w.duration / 60) + ":" + String(Math.round(w.duration % 60)).padStart(2, "0") + " loop")
                    return parts.join(" · ")
                }
                color: root.cSub
                font { family: Theme.monoFont; pixelSize: 12 }
            }
        }

        // ── Carousel ────────────────────────────────────────────────────
        Item {
            id: carousel
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(parent.height * 0.47 - root.cardH / 2 + (1 - stage.t) * 40)
            width: root.cardW
            height: root.cardH

            // Glow under the selected card.
            RectangularShadow {
                anchors.fill: parent
                anchors.margins: 10
                radius: 18
                blur: 70
                spread: 4
                offset: Qt.vector2d(0, 26)
                color: Theme.alpha(root.cAccent, 0.38)
                visible: root.n > 0
            }

            Repeater {
                // Slots around the selected card; each shows the wallpaper
                // its place in the loop lands on.
                model: 9
                delegate: Item {
                    id: card
                    required property int index
                    readonly property int slot: index - 4
                    readonly property int at: Math.round(root.pos) + slot
                    readonly property var w: root.n ? (root.list[root.wrap(at)] || null) : null
                    readonly property real d: at - root.pos
                    readonly property real a: Math.abs(d)
                    readonly property bool centre: a < 0.5
                    // Fewer wallpapers than slots: don't show one twice.
                    visible: w !== null && a < 4.4
                        && (Math.abs(slot) <= Math.floor((root.n - 1) / 2) || (root.n % 2 === 0 && slot === root.n / 2))

                    width: root.cardW
                    height: root.cardH
                    z: 10 - a
                    x: Math.sign(d) * (Math.min(a, 1) * root.cardW * 0.62 + Math.max(a - 1, 0) * root.cardW * 0.24)
                    scale: 1 - 0.16 * Math.min(a, 3)
                    opacity: a <= 3 ? 1 - 0.18 * a : Math.max(0, (4.4 - a) / 1.4 * 0.46)
                    transform: Rotation {
                        origin.x: card.width / 2
                        origin.y: card.height / 2
                        axis { x: 0; y: 1; z: 0 }
                        angle: -Math.max(-1, Math.min(1, card.d)) * 46
                    }

                    ClippingRectangle {
                        anchors.fill: parent
                        radius: 18
                        color: root.cBase
                        border.width: card.centre ? 2 : 1
                        border.color: card.centre ? root.cAccent : Theme.alpha(root.cText, 0.1)

                        Text {
                            anchors.centerIn: parent
                            width: parent.width - 32
                            visible: !card.w || !card.w.thumb
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                            text: card.w ? card.w.name : ""
                            color: root.cSub
                            font { family: Theme.font; pixelSize: 13 }
                        }
                        Image {
                            anchors.fill: parent
                            source: card.w && card.w.thumb ? "file://" + card.w.thumb : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize.width: 480
                        }
                        Loader {
                            anchors.fill: parent
                            active: card.centre && root.settled && root.open && card.w !== null && card.w.kind === "video"
                            source: "WallpaperVideo.qml"
                            // The small preview clip when there is one.
                            onLoaded: item.path = Qt.binding(() => card.w ? (card.w.preview || card.w.path) : "")
                        }
                        // Turned-away cards sink into the dark.
                        Rectangle {
                            anchors.fill: parent
                            color: root.cCrust
                            opacity: Math.min(0.62, card.a * 0.3)
                        }

                        Rectangle {
                            visible: card.w !== null && card.w.kind === "video"
                            anchors { left: parent.left; bottom: parent.bottom; margins: 12 }
                            width: videoRow.implicitWidth + 16
                            height: 22
                            radius: 11
                            color: Theme.alpha(root.cCrust, 0.72)
                            Row {
                                id: videoRow
                                anchors.centerIn: parent
                                spacing: 5
                                Icon { name: "play"; size: 10; color: root.cText; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "VIDEO"; color: root.cText; font { family: Theme.font; pixelSize: 9; bold: true } }
                            }
                        }
                        Rectangle {
                            visible: card.w !== null && card.w.path === root.current
                            anchors { right: parent.right; top: parent.top; margins: 12 }
                            width: inUse.implicitWidth + 14
                            height: 20
                            radius: 8
                            color: root.cAccent
                            Text {
                                id: inUse
                                anchors.centerIn: parent
                                text: "IN USE"
                                color: root.cCrust
                                font { family: Theme.font; pixelSize: 9; bold: true; letterSpacing: 0.6 }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.centre ? root.apply() : root.goTo(card.at)
                    }
                }
            }
        }

        // ── Where you are in the folder ─────────────────────────────────
        Item {
            anchors { horizontalCenter: parent.horizontalCenter; top: carousel.bottom; topMargin: root.cardH * 0.22 }
            width: dots.visible ? dots.implicitWidth : counter.implicitWidth
            height: 14
            Row {
                id: dots
                visible: root.n > 1 && root.n <= 24
                anchors.centerIn: parent
                spacing: 6
                Repeater {
                    model: dots.visible ? root.n : 0
                    delegate: Rectangle {
                        required property int index
                        width: index === root.index ? 22 : 6
                        height: 4
                        radius: 2
                        color: index === root.index ? root.cAccent : Theme.alpha(root.cText, 0.18)
                        Behavior on width { NumberAnimation { duration: 200 } }
                    }
                }
            }
            Text {
                id: counter
                visible: root.n > 24
                anchors.centerIn: parent
                text: (root.index + 1) + " / " + root.n
                color: root.cSub
                font { family: Theme.monoFont; pixelSize: 12; bold: true }
            }
        }

        // ── Controls ────────────────────────────────────────────────────
        Column {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Math.round(root.height * 0.06) }
            spacing: 12

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: controls.implicitWidth + 12
                height: 44
                radius: 16
                color: Theme.alpha(root.cBase, 0.86)
                border.width: 1
                border.color: Theme.alpha(root.cText, 0.08)

                Row {
                    id: controls
                    anchors.centerIn: parent
                    spacing: 6

                    Repeater {
                        model: [["all", "All"], ["videos", "Videos"], ["images", "Images"]]
                        delegate: Chip {
                            required property var modelData
                            picker: root
                            label: modelData[1]
                            on: root.filter === modelData[0]
                            onClicked: root.filter = modelData[0]
                        }
                    }
                    Rectangle { width: 1; height: 18; color: Theme.alpha(root.cText, 0.1); anchors.verticalCenter: parent.verticalCenter }

                    // Search: / to start, Esc to leave.
                    Rectangle {
                        width: 190
                        height: 32
                        radius: 11
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.alpha(root.cCrust, 0.5)
                        border.width: root.searching ? 1 : 0
                        border.color: root.cAccent
                        Row {
                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            spacing: 8
                            Icon { name: "search"; size: 14; color: root.cSub; anchors.verticalCenter: parent.verticalCenter }
                            Item {
                                width: parent.width - 22
                                height: parent.height
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: search.text === ""
                                    text: root.searching ? "Search" : "Press / to search"
                                    color: Theme.alpha(root.cSub, 0.7)
                                    font { family: Theme.font; pixelSize: 12 }
                                }
                                TextInput {
                                    id: search
                                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                                    color: root.cText
                                    selectionColor: root.cAccent
                                    font { family: Theme.font; pixelSize: 12 }
                                    clip: true
                                    onTextChanged: root.query = text
                                    onActiveFocusChanged: if (activeFocus) root.searching = true
                                    Connections {
                                        target: root
                                        function onQueryChanged() { if (search.text !== root.query) search.text = root.query }
                                    }
                                }
                            }
                        }
                    }

                    Chip {
                        picker: root
                        icon: "palette"
                        label: "Theme from wallpaper"
                        key: "W"
                        on: root.themed
                        onClicked: root.toggleTheme()
                    }
                    Chip {
                        picker: root
                        label: "Browse…"
                        onClicked: { root.close(); browse.open() }
                    }
                    Chip {
                        picker: root
                        label: "Apply"
                        solid: true
                        onClicked: root.apply()
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "← →  A D move · hold to spin · Enter apply · W theme · / search · Esc close"
                color: Theme.alpha(root.cSub, 0.75)
                font { family: Theme.font; pixelSize: 11 }
            }
        }
    }

    // While the picker is open on another monitor: an invisible layer here
    // that moves it here when the pointer arrives (or clicks).
    PanelWindow {
        screen: root.screen
        visible: Shell.wallpaperOn !== "" && !root.open
        WlrLayershell.namespace: "abyssal-wallpaper-follow"
        WlrLayershell.layer: WlrLayer.Overlay
        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: -1
        color: "transparent"
        Item {
            anchors.fill: parent
            HoverHandler { onHoveredChanged: if (hovered && Shell.wallpaperOn !== "") Shell.wallpaperOn = root.output }
            TapHandler { onTapped: if (Shell.wallpaperOn !== "") Shell.wallpaperOn = root.output }
        }
    }

    component Chip: Rectangle {
        id: chip
        // Inline components can't see the window's id.
        required property var picker
        property string label: ""
        property string icon: ""
        property string key: ""
        property bool on: false
        property bool solid: false
        signal clicked()

        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        width: chipRow.implicitWidth + 26
        height: 32
        radius: 11
        color: solid ? picker.cAccent : on ? Theme.alpha(picker.cAccent, 0.2) : chipArea.containsMouse ? Theme.alpha(picker.cText, 0.07) : "transparent"
        Behavior on color { ColorAnimation { duration: 140 } }

        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: 7
            Icon {
                visible: chip.icon !== ""
                name: chip.icon || "square"
                size: 14
                color: chip.on ? picker.cAccent : picker.cSub
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: chip.label
                color: chip.solid ? picker.cCrust : chip.on ? picker.cAccent : picker.cSub
                font { family: Theme.font; pixelSize: 12; bold: true }
            }
            Rectangle {
                visible: chip.key !== ""
                anchors.verticalCenter: parent.verticalCenter
                width: 18
                height: 18
                radius: 5
                color: Theme.alpha(picker.cText, 0.08)
                Text {
                    anchors.centerIn: parent
                    text: chip.key
                    color: picker.cSub
                    font { family: Theme.monoFont; pixelSize: 10; bold: true }
                }
            }
        }
        MouseArea {
            id: chipArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.clicked()
        }
    }
}
