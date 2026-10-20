import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam

// Abyssal lock screen, a separate Quickshell instance started by
// Shell.lock() (`qs -n -p .../lock`). TideWM ends the session if a lock
// client dies while locked, so this instance stays small, never
// hot-reloads, and exits on its own after unlocking.
ShellRoot {
    id: root

    property string error: ""
    property string pending: ""
    readonly property bool busy: pam.active

    function submit(password) {
        if (pam.active || password === "") return
        pending = password
        error = ""
        pam.start()
    }

    Component.onCompleted: Quickshell.watchFiles = false

    PamContext {
        id: pam
        configDirectory: Quickshell.shellDir + "/pam"
        config: "password"

        onPamMessage: {
            if (responseRequired) {
                respond(root.pending)
                root.pending = ""
            }
        }
        onCompleted: result => {
            if (result === PamResult.Success) {
                lock.locked = false
            } else {
                root.error = result === PamResult.MaxTries ? "Too many tries, wait a moment" : "Wrong password"
            }
        }
    }

    WlSessionLock {
        id: lock
        locked: true
        onLockedChanged: if (!locked) quit.start()

        WlSessionLockSurface {
            color: "#080b17"
            LockSurface { anchors.fill: parent; lockRoot: root }
        }
    }

    // Give the compositor the unlock before the process goes away.
    Timer { id: quit; interval: 400; onTriggered: Qt.quit() }
}
