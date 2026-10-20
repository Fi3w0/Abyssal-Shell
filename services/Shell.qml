pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Shell-wide UI state: which overlay is open on which monitor.
Singleton {
    id: root

    // Output name the power menu is open on, "" when closed.
    property string powerOn: ""
    // Quick settings: { output, edge } of the bar it opened from, or null.
    property var quickSettings: null
    // Plasma-style bar edit mode, on every monitor at once.
    property bool editing: false
    // Keeps the system awake (idle inhibitor) while true.
    property bool caffeine: false

    // Volume/brightness popup: shown on `osdOutput` until the timer runs out.
    property string osdOutput: ""
    property string osdKind: "volume"
    property real   osdValue: 0
    property bool   osdMuted: false

    function togglePower(output) {
        quickSettings = null
        powerOn = powerOn === output ? "" : output
    }

    function toggleQuickSettings(output, edge) {
        quickSettings = quickSettings && quickSettings.output === output ? null : { output: output, edge: edge }
    }

    function setEditing(on) {
        quickSettings = null
        powerOn = ""
        editing = on
    }

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

    // qs -c abyssal ipc call shell edit | done | lock
    IpcHandler {
        target: "shell"
        function edit(): void { root.setEditing(true) }
        function done(): void { root.setEditing(false) }
        function lock(): void { root.lock() }
    }
}
