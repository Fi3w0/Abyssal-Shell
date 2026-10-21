pragma Singleton
import QtQml

QtObject {
    property bool wifi: true
    property bool bluetooth: true
    property bool quiet: false
    property bool awake: false
    property real volume: 64
    property real microphone: 42
    property int workspace: 0
    property string query: ""
    property int selected: 0
    property bool notification: true
    property bool launcher: true
    property bool controls: true
    property bool menu: true
    property bool pinned: true
    property bool muted: false
    property bool micMuted: false
    property string feedback: "Sample data · No system actions"
    readonly property var apps: [
        {
            name: "Firefox",
            detail: "Web browser",
            image: "file:///usr/share/pixmaps/firefox-bin.png"
        },
        {
            name: "Dolphin",
            detail: "File manager",
            image: "file:///usr/share/icons/hicolor/scalable/apps/org.kde.dolphin.svg"
        },
        {
            name: "Kitty",
            detail: "Terminal",
            image: "file:///usr/share/icons/hicolor/scalable/apps/kitty.svg"
        },
        {
            name: "System Settings",
            detail: "Desktop preferences",
            image: "file:///usr/share/icons/breeze/apps/48/systemsettings.svg"
        }
    ]
    readonly property var matches: apps.filter(a => (a.name + " " + a.detail).toLowerCase().includes(query.toLowerCase()))
    readonly property var current: matches[selected] || null
    function pick(index) {
        selected = index;
        if (current)
            feedback = "Selected " + current.name + " · Preview only";
    }
    function reset() {
        launcher = true;
        controls = true;
        menu = true;
        pinned = true;
        muted = false;
        micMuted = false;
        query = "";
        selected = 0;
        notification = true;
        wifi = true;
        bluetooth = true;
        quiet = false;
        awake = false;
        volume = 64;
        microphone = 42;
        workspace = 0;
        feedback = "Sample data · No system actions";
    }
}
