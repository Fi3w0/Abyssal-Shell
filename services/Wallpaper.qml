pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import QtQml.Models

// Animated wallpaper per monitor, started with the shell so it follows
// TideWM's session instead of a separate launcher script.
//
// ~/.config/abyssal/wallpaper.json:
// {
//   "screens": {
//     "DP-4":     { "video": "/path/to/video.mp4", "hwdec": "nvdec-copy" },
//     "HDMI-A-2": { "video": "/path/to/video.mp4" },
//     "*":        { "video": "/path/to/fallback.mp4" }
//   }
// }
//
// `video` and `image` are both accepted (mpvpaper plays either); `hwdec`
// defaults to `auto`, and `options` appends raw mpv options. Outputs are
// matched by name at runtime, so hotplug and other monitors work without
// editing code.
Singleton {
    id: root

    readonly property string dir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/abyssal"
    readonly property string path: dir + "/wallpaper.json"
    readonly property string socketDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"

    property var config: ({})
    // A fresh shell must not add to players left by a previous one: stop the
    // old ones first, then start one per output.
    property bool ready: false

    readonly property var entries: {
        const configured = root.config && root.config.screens ? root.config.screens : ({})
        const out = []
        for (const screen of Quickshell.screens) {
            const entry = configured[screen.name] || configured["*"]
            if (!entry) continue
            const source = entry.video || entry.image || ""
            if (!source) continue
            out.push({
                output: screen.name,
                source: source,
                hwdec: entry.hwdec || "auto",
                options: entry.options || ""
            })
        }
        return out
    }

    FileView {
        id: file
        preload: false
        blockLoading: true
        path: root.path
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.config = JSON.parse(text())
            } catch (e) {
                console.warn("abyssal: wallpaper.json is not valid JSON, keeping the running wallpapers:", e)
            }
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) root.config = ({})
        }
    }

    Component.onCompleted: file.text()

    // One player per output. Recreating a delegate destroys its Process,
    // which Quickshell terminates, so config changes and hotplug restart
    // only the affected output.
    Process {
        id: cleanup
        command: ["pkill", "-f", "input-ipc-server=.*/abyssal-wallpaper-"]
        running: true
        onExited: root.ready = true
    }

    Instantiator {
        model: root.ready ? root.entries : []
        delegate: Component {
        QtObject {
            id: player
            required property var modelData

            readonly property string socket: root.socketDir + "/abyssal-wallpaper-" + modelData.output + ".sock"

            property Process process: Process {
                running: false
                command: [
                    "mpvpaper", "-p", "-o",
                    "hwdec=" + player.modelData.hwdec
                        + " loop-file=inf no-audio terminal=no cache=no demuxer-readahead-secs=0"
                        + (player.modelData.options ? " " + player.modelData.options : "")
                        + " input-ipc-server=" + player.socket,
                    player.modelData.output, player.modelData.source
                ]
            }

            // modelData is assigned after creation; start once it is there.
            property Timer starter: Timer {
                interval: 0
                running: true
                onTriggered: player.process.running = true
            }
        }
        }
    }

}
