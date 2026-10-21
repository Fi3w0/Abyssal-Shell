pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Claude Code and Codex plan usage (5-hour and weekly windows) and both
// services' status, from scripts/ai-usage: Claude Code's own status line
// data (scripts/claude-statusline saves it) and Codex's session logs, so no
// logins are touched. Rechecked every two minutes, and as soon as Claude
// Code writes new numbers.
Singleton {
    id: root

    property var data: ({ claude: null, codex: null, status: {} })
    readonly property var claude: data.claude
    readonly property var codex: data.codex
    readonly property var status: data.status || {}

    // The fuller 5-hour window of the two, for the bar.
    function used(src, name) {
        const w = src && src.windows ? src.windows.find(x => x.name === name) : null
        return w ? w.used : -1
    }
    readonly property real peak: Math.max(used(claude, "5 hours"), used(codex, "5 hours"))
    readonly property bool trouble: ["major", "critical"].includes((status.claude || {}).indicator)
        || ["major", "critical"].includes((status.openai || {}).indicator)

    function refresh() {
        if (!runner.running) runner.running = true
    }
    Process {
        id: runner
        command: [Quickshell.shellPath("scripts/ai-usage")]
        stdout: StdioCollector {
            onStreamFinished: { try { root.data = JSON.parse(text) } catch (e) {} }
        }
    }
    Timer { running: true; repeat: true; interval: 120000; triggeredOnStart: true; onTriggered: root.refresh() }

    FileView {
        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/abyssal/claude-usage.json"
        watchChanges: true
        printErrors: false
        onFileChanged: settle.restart()
    }
    Timer { id: settle; interval: 1500; onTriggered: root.refresh() }
}
