import QtQuick
import QtQuick.Controls

ArchiveButton {
    id: root
    objectName: "shortcutRecorder"
    property string chord: ""
    property bool recording: false
    signal recorded(string next)
    text: recording ? "Press your shortcut…" : chord || "Record shortcut"
    checked: recording
    Accessible.name: recording ? "Press keys. Escape cancels." : "Record shortcut " + chord
    onClicked: { recording = true; forceActiveFocus(); }
    onActiveFocusChanged: if (!activeFocus) recording = false
    Keys.onPressed: event => {
        if (!recording) return;
        event.accepted = true;
        if (event.key === Qt.Key_Escape) { recording = false; return; }
        const name = Store.shortcutName(event.key, event.modifiers);
        if (name) { chord = name; recorded(name); recording = false; }
    }
}
