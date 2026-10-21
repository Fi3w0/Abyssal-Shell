pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import QtQuick.Dialogs
import Quickshell.Io

// Shell-wide UI state: which overlay is open on which monitor.
Singleton {
    id: root

    // Output name the power menu is open on, "" when closed.
    property string powerOn: ""
    // Quick settings: { output, edge } of the panel it opened from, or null.
    property var quickSettings: null
    // App launcher: output it is open on, "" when closed.
    property string launcherOn: ""
    // Wallpaper picker: output it is open on (and changes), "" when closed.
    // Moving the pointer to another monitor moves it there.
    property string wallpaperOn: ""
    // Window switcher (panels/WindowSwitcher.qml): output it is open on.
    property string switcherOn: ""
    signal switcherStep(int dir)
    // Toplevels, most recently focused first (the switcher's order).
    property var recent: []
    Connections {
        target: ToplevelManager
        function onActiveToplevelChanged() {
            const t = ToplevelManager.activeToplevel
            if (!t) return
            root.recent = [t].concat(root.recent.filter(x => x !== t && ToplevelManager.toplevels.values.includes(x))).slice(0, 64)
        }
    }
    function windowsByRecent() {
        const all = ToplevelManager.toplevels.values
        const known = recent.filter(t => all.includes(t))
        return known.concat(all.filter(t => !known.includes(t)))
    }
    // Keeps the system awake (idle inhibitor) while true.
    property bool caffeine: false
    // Wi-Fi / Bluetooth / Sound popup opened from a bar widget, or null:
    // { output, edge, page: "wifi" | "bluetooth" | "sound", pos, inset }.
    // pos is the widget's centre along the panel edge, inset the panel's
    // thickness, so the popup sits right under the widget.
    property var detail: null

    // ── Edit mode ───────────────────────────────────────────────────────
    // Plasma-style: every panel on every monitor becomes editable; one
    // panel at a time is selected and gets the settings popup.
    property bool editing: false
    property var editTarget: null       // { output, edge }
    property var widgetTarget: null     // last clicked { output, edge, index, id }
    property bool pickingPosition: false
    property bool sidebarOpen: false
    // Last removed panel, for the undo pill: { output, panel }.
    property var removedPanel: null

    function isEditTarget(output, edge) {
        return editing && editTarget !== null && editTarget.output === output && editTarget.edge === edge
    }

    function setEditing(on) {
        quickSettings = null
        detail = null
        powerOn = ""
        launcherOn = ""
        pickingPosition = false
        sidebarOpen = false
        removedPanel = null
        widgetTarget = null
        if (on) {
            const out = targetOutput()
            const panels = PanelLayout.panelsFor(out)
            editTarget = panels.length ? { output: out, edge: panels[0].edge } : null
        } else {
            editTarget = null
        }
        editing = on
    }

    function selectPanel(output, edge) {
        pickingPosition = false
        if (!editTarget || editTarget.output !== output || editTarget.edge !== edge) widgetTarget = null
        editTarget = { output: output, edge: edge }
    }

    function selectWidget(output, edge, index, id) {
        selectPanel(output, edge)
        widgetTarget = { output: output, edge: edge, index: index, id: id }
    }

    function addWidget(id) {
        if (!editTarget) return
        const p = PanelLayout.panelsFor(editTarget.output).find(p => p.edge === editTarget.edge)
        if (!p) return
        const index = p.items.length
        PanelLayout.addItem(editTarget.output, editTarget.edge, id)
        selectWidget(editTarget.output, editTarget.edge, index, id)
        sidebarOpen = false
    }

    function widgetRemoved(output, edge, index) {
        const t = widgetTarget
        if (!t || t.output !== output || t.edge !== edge) return
        if (t.index === index) widgetTarget = null
        else if (t.index > index) widgetTarget = Object.assign({}, t, { index: t.index - 1 })
    }

    function widgetMoved(output, edge, from, to) {
        const t = widgetTarget
        if (!t || t.output !== output || t.edge !== edge) return
        let index = t.index
        if (index === from) index = to
        else if (from < index && index <= to) index--
        else if (to <= index && index < from) index++
        widgetTarget = Object.assign({}, t, { index: index })
    }

    function removeTarget() {
        if (!editTarget) return
        widgetTarget = null
        const removed = PanelLayout.removePanel(editTarget.output, editTarget.edge)
        if (removed) removedPanel = { output: editTarget.output, panel: removed }
        const rest = PanelLayout.panelsFor(editTarget.output)
        editTarget = rest.length ? { output: editTarget.output, edge: rest[0].edge } : null
    }

    function undoRemove() {
        if (!removedPanel) return
        PanelLayout.restorePanel(removedPanel.output, removedPanel.panel)
        editTarget = { output: removedPanel.output, edge: removedPanel.panel.edge }
        removedPanel = null
    }

    function moveTargetTo(output, edge) {
        if (!editTarget) return
        PanelLayout.movePanel(editTarget.output, editTarget.edge, output, edge)
        editTarget = { output: output, edge: edge }
        widgetTarget = null
        pickingPosition = false
    }

    // ── Other overlays ──────────────────────────────────────────────────
    function togglePower(output) {
        quickSettings = null
        detail = null
        launcherOn = ""
        powerOn = powerOn === output ? "" : output
    }

    function toggleQuickSettings(output, edge, pos = null, inset = null) {
        launcherOn = ""
        detail = null
        quickSettings = quickSettings && quickSettings.output === output ? null
            : { output: output, edge: edge, pos: pos, inset: inset }
    }

    // A popup page (wifi, clipboard, updates…) centred on the first panel of
    // the monitor you are working on: for keybinds and the launcher.
    function openPage(page) {
        const out = targetOutput()
        const panel = PanelLayout.panelsFor(out)[0]
        const screen = Quickshell.screens.find(s => s.name === out)
        if (!panel || !screen) return
        const vertical = panel.edge === "left" || panel.edge === "right"
        toggleDetail(out, panel.edge, page, (vertical ? screen.height : screen.width) / 2, panel.size)
    }

    function toggleWallpaperPicker(output) {
        quickSettings = null
        detail = null
        launcherOn = ""
        wallpaperOn = wallpaperOn !== "" ? "" : output
    }

    function toggleLauncher(output) {
        wallpaperOn = ""
        quickSettings = null
        detail = null
        launcherOn = launcherOn === output ? "" : output
    }

    function toggleDetail(output, edge, page, pos, inset) {
        quickSettings = null
        launcherOn = ""
        powerOn = ""
        detail = detail && detail.output === output && detail.page === page ? null
               : { output: output, edge: edge, page: page, pos: pos, inset: inset }
    }

    // Volume / mic mute / keyboard layout popup ("volume" | "mic" |
    // "layout"): shown on `osdOutput` until the timer runs out.
    property string osdOutput: ""
    property string osdKind: "volume"
    property real   osdValue: 0
    property bool   osdMuted: false

    function showOsd(kind, value, muted) {
        osdKind = kind
        osdValue = value
        osdMuted = muted
        osdOutput = targetOutput()
        osdTimer.restart()
    }
    Timer { id: osdTimer; interval: 1300; onTriggered: root.osdOutput = "" }

    // The lock screen is its own Quickshell instance (lock/shell.qml): a
    // crashed lock client ends the TideWM session, and the main shell
    // hot-reloads on every edit, so the lock must not live in it.
    function lock() {
        powerOn = ""
        quickSettings = null
        detail = null
        launcherOn = ""
        // Never a second lock instance (manual lock, then the idle lock):
        // TideWM ends the session when a lock client fails.
        Quickshell.execDetached(["sh", "-c", 'pgrep -f -- "-p $1$" >/dev/null || exec qs -n -p "$1"',
                                 "sh", Quickshell.shellPath("lock")])
    }

    // Keybinds land on the monitor you are working on.
    function targetOutput() {
        return Tide.focusedOutput !== "" ? Tide.focusedOutput : (Quickshell.screens[0]?.name ?? "")
    }

    // "Open file" dialogs go through the desktop portal (scripts/
    // abyssal-session sets QT_QPA_PLATFORMTHEME=xdgdesktopportal for Abyssal
    // only); this picks the portal's file chooser to match the file manager
    // once.
    Component.onCompleted: Quickshell.execDetached([Quickshell.shellPath("scripts/portal-filechooser")])

    // scripts/abyssal-session restarted the shell after a crash: say so once
    // the toasts are up.
    Timer {
        running: (Quickshell.env("ABYSSAL_RECOVERED") ?? "") !== ""
        interval: 1500
        onTriggered: {
            const code = parseInt(Quickshell.env("ABYSSAL_RECOVERED"))
            const how = code > 128 ? "signal " + (code - 128) : "exit code " + code
            const state = Quickshell.env("XDG_STATE_HOME") || "~/.local/state"
            Notifications.push("Abyssal", "Shell restarted after a crash",
                "It stopped with " + how + ". Log: " + state + "/abyssal/last-crash.log", "", null)
        }
    }

    // Picks an image for the quick menu header. The menu closes first: its
    // layer surfaces sit above normal windows and would cover the dialog.
    function pickHeaderIcon() {
        quickSettings = null
        headerIconDialog.open()
    }
    function settings() {
        quickSettings = null
        detail = null
        launcherOn = ""
        Quickshell.execDetached([Quickshell.shellPath("scripts/abyssal-settings")])
    }
    FileDialog {
        id: headerIconDialog
        title: "Quick menu icon"
        nameFilters: ["Images (*.svg *.png *.jpg *.jpeg *.webp *.gif *.bmp *.ico)", "All files (*)"]
        onAccepted: {
            const path = decodeURIComponent(selectedFile.toString().replace(/^file:\/\//, ""))
            Profile.setAvatar(path)
            PanelLayout.setQuickMenuField("header", "icon", "file:" + path)
        }
    }

    // qs -c abyssal ipc call power toggle
    IpcHandler {
        target: "power"
        function toggle(): void { root.togglePower(root.targetOutput()) }
        function close(): void { root.powerOn = "" }
    }

    // qs -c abyssal ipc call shell edit | done | lock | launcher | restart
    IpcHandler {
        target: "shell"
        // A fresh process; scripts/abyssal-session starts it again at once.
        function restart(): void { Qt.exit(75) }
        function edit(): void { root.setEditing(true) }
        function done(): void { root.setEditing(false) }
        function lock(): void { root.lock() }
        function launcher(): void { root.toggleLauncher(root.targetOutput()) }
        function wallpapers(): void { root.toggleWallpaperPicker(root.targetOutput()) }
        function settings(): void { root.settings() }
        // Alt+Tab: opens the switcher, or moves to the next window in it.
        function switcher(): void {
            if (root.switcherOn !== "") root.switcherStep(1)
            else root.switcherOn = root.targetOutput()
        }
        function switcherCancel(): void { root.switcherOn = "" }
        function widgets(): void { if (root.editing) root.sidebarOpen = true }
        // classic | rice | topbar, on the monitor you are working on
        function preset(name: string): void { PanelLayout.applyPreset(root.targetOutput(), name) }
        // Quick menu next to the first panel of the monitor you are working on
        function quick(): void {
            const out = root.targetOutput()
            const panel = PanelLayout.panelsFor(out)[0]
            root.toggleQuickSettings(out, panel ? panel.edge : "top")
        }
        // wifi | bluetooth | sound, centred on the first panel of the
        // monitor you are working on (for keybinds; widgets open their own)
        function open(page: string): void { root.openPage(page) }
    }
}
