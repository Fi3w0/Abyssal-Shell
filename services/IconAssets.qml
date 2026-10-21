pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var rasters: ({})
    Process {
        running: true
        command: ["python3", Quickshell.shellPath("scripts/icon-assets.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.rasters = JSON.parse(text) } catch (e) { root.rasters = ({}) }
            }
        }
    }
}
