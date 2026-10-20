pragma Singleton

import QtQuick
import Quickshell
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
    // Keeps the system awake (idle inhibitor) while true.
    property bool caffeine: false

    // ── Edit mode ───────────────────────────────────────────────────────
    // Plasma-style: every panel on every monitor becomes editable; one
    // panel at a time is selected and gets the settings popup.
    property bool editing: false
    property var editTarget: null       // { output, edge }
    property bool pickingPosition: false
    property bool sidebarOpen: false
    // Last removed panel, for the undo pill: { output, panel }.
    property var removedPanel: null

    function isEditTarget(output, edge) {
        return editing && editTarget !== null && editTarget.output === output && editTarget.edge === edge
    }

    function setEditing(on) {
        quickSettings = null
        powerOn = ""
        launcherOn = ""
        pickingPosition = false
        sidebarOpen = false
        removedPanel = null
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
        editTarget = { output: output, edge: edge }
    }

    function removeTarget() {
        if (!editTarget) return
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
        pickingPosition = false
    }

    // ── Other overlays ──────────────────────────────────────────────────
    function togglePower(output) {
        quickSettings = null
        launcherOn = ""
        powerOn = powerOn === output ? "" : output
    }

    function toggleQuickSettings(output, edge) {
        launcherOn = ""
        quickSettings = quickSettings && quickSettings.output === output ? null : { output: output, edge: edge }
    }

    function toggleLauncher(output) {
        quickSettings = null
        launcherOn = launcherOn === output ? "" : output
    }

    // Volume/brightness popup: shown on `osdOutput` until the timer runs out.
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
        launcherOn = ""
        Quickshell.execDetached(["qs", "-n", "-p", Quickshell.shellPath("lock")])
    }

    // Keybinds land on the monitor you are working on.
    function targetOutput() {
        return Tide.focusedOutput !== "" ? Tide.focusedOutput : (Quickshell.screens[0]?.name ?? "")
    }

    // qs -c abyssal ipc call power toggle
    IpcHandler {
        target: "power"
        function toggle(): void { root.togglePower(root.targetOutput()) }
        function close(): void { root.powerOn = "" }
    }

    // qs -c abyssal ipc call shell edit | done | lock | launcher
    IpcHandler {
        target: "shell"
        function edit(): void { root.setEditing(true) }
        function done(): void { root.setEditing(false) }
        function lock(): void { root.lock() }
        function launcher(): void { root.toggleLauncher(root.targetOutput()) }
        function widgets(): void { if (root.editing) root.sidebarOpen = true }
        // classic | rice | topbar, on the monitor you are working on
        function preset(name: string): void { PanelLayout.applyPreset(root.targetOutput(), name) }
    }
}
