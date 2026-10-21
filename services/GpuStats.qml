pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var samples: []
    property var devices: []
    readonly property var choices: [{ value: "auto", label: "Automatic" }].concat(
        devices.map(d => ({ value: d.id, label: d.name + " · " + d.pci })))

    function device(id) {
        if (!id || id === "auto")
            return samples.find(d => d.usage !== null && !d.suspended) || samples[0] || null
        return samples.find(d => d.id === id) || null
    }

    Process {
        id: probe
        command: ["python3", Quickshell.shellPath("scripts/gpu-stats.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    if (!Array.isArray(data)) return
                    const metadata = data.map(d => ({ id: d.id, name: d.name, pci: d.pci }))
                    if (JSON.stringify(metadata) !== JSON.stringify(root.devices)) root.devices = metadata
                    root.samples = data
                } catch (e) { root.samples = [] }
            }
        }
        onExited: code => { if (code !== 0) root.samples = [] }
    }
    Timer {
        interval: 3000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: if (!probe.running) probe.running = true
    }
}
