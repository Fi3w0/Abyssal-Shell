import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

ApplicationWindow {
    id: win
    visible: true
    width: 1080
    height: 750
    minimumWidth: 840
    minimumHeight: 560
    title: "Abyssal Settings"
    color: "#100d18"
    palette {
        window: "#100d18"
        windowText: "#ece5f4"
        base: "#15111f"
        alternateBase: "#211a2e"
        text: "#ece5f4"
        button: "#2a2038"
        buttonText: "#ece5f4"
        highlight: "#b8a0df"
        highlightedText: "#100d18"
        placeholderText: "#9b88ad"
        mid: "#493959"
        dark: "#20192b"
        light: "#493959"
    }
    font.family: "Sans Serif"
    font.pixelSize: 13
    property int revision: 0
    property string page: initialPage
    property string query: ""
    property string themeId: "trench-violet"
    property string output: Store.outputs()[0] || "*"
    property var account: Store.account()
    property var caps: Store.capabilities()
    property var transitionProfiles: Store.transitions()
    property bool allowClose: false
    property bool closing: false
    property string documentId: "layout"
    readonly property var sections: [
        {
            id: "appearance",
            title: "Theme & colours",
            group: "PERSONALISE",
            words: "appearance palette fonts style"
        },
        {
            id: "wallpaper",
            title: "Wallpapers",
            group: "",
            words: "background video transition animation"
        },
        {
            id: "panels",
            title: "Panels & widgets",
            group: "",
            words: "rice bar dock layout"
        },
        {
            id: "keybinds",
            title: "Keybinds",
            group: "DESKTOP",
            words: "keyboard shortcuts commands"
        },
        {
            id: "tidewm",
            title: "TideWM",
            group: "",
            words: "compositor windows displays input borders shadows animation"
        },
        {
            id: "autostart",
            title: "Startup apps",
            group: "",
            words: "login autostart applications"
        },
        {
            id: "updates",
            title: "Updates",
            group: "SYSTEM",
            words: "packages manager aur flatpak repositories"
        },
        {
            id: "notifications",
            title: "Notifications",
            group: "",
            words: "alerts toast silence do not disturb"
        },
        {
            id: "idle",
            title: "Power & idle",
            group: "",
            words: "session lock screen blank sleep"
        },
        {
            id: "account",
            title: "Account",
            group: "",
            words: "user avatar profile password"
        },
        {
            id: "files",
            title: "Config files",
            group: "ADVANCED",
            words: "json wave edit backup"
        }
    ]
    Component.onCompleted: themeId = get("appearance", "theme", "trench-violet")
    Connections {
        target: Store
        function onChanged() {
            win.revision++;
        }
    }
    function get(id, key, fallback) {
        revision;
        return Store.value(id, key, fallback);
    }
    function startup() {
        return get("autostart", "apps", []).slice();
    }
    onClosing: event => {
        if (activeFocusItem)
            activeFocusItem.focus = false;
        if (!allowClose && Store.dirtyCount) {
            event.accepted = false;
            closing = true;
            discard.open();
        }
    }
    Dialog {
        id: discard
        anchors.centerIn: parent
        title: closing ? "Close with unsaved changes?" : "Discard unsaved changes?"
        modal: true
        standardButtons: Dialog.Discard | Dialog.Cancel
        onDiscarded: {
            if (win.closing) {
                win.allowClose = true;
                win.close();
            } else
                Store.reload();
        }
        onRejected: win.closing = false
        Label {
            text: "Your saved configuration will stay as it is."
        }
    }
    FileDialog {
        id: imagePicker
        nameFilters: ["Images and videos (*.png *.jpg *.jpeg *.webp *.avif *.gif *.mp4 *.mkv *.webm)"]
        onAccepted: {
            let path = decodeURIComponent(selectedFile.toString().replace(/^file:\/\//, ""));
            let screens = win.get("wallpaper", "screens", {});
            let entry = Object.assign({}, screens[win.output] || screens["*"] || {});
            delete entry.video;
            delete entry.image;
            entry[/\.(mp4|mkv|webm|gif)$/i.test(path) ? "video" : "image"] = path;
            screens[win.output] = entry;
            Store.setValue("wallpaper", "screens", screens);
        }
    }
    FileDialog {
        id: avatarPicker
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp *.svg)"]
        onAccepted: Store.setValue("profile", "avatar", decodeURIComponent(selectedFile.toString().replace(/^file:\/\//, "")))
    }
    ColorDialog {
        id: colour
        property string key
        onAccepted: Store.setValue("theme:" + win.themeId, "colors." + key, selectedColor.toString())
    }
    RowLayout {
        anchors {
            fill: parent
            bottomMargin: 76
        }
        spacing: 0
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 228
            color: "#17121f"
            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 18
                }
                spacing: 8
                RowLayout {
                    spacing: 10
                    Layout.bottomMargin: 20
                    Image {
                        source: "file://" + Store.shellRoot + "/assets/abyssal.svg"
                        sourceSize: Qt.size(34, 34)
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                    }
                    ColumnLayout {
                        spacing: 2
                        Label {
                            text: "ABYSSAL"
                            font {
                                pixelSize: 15
                                weight: Font.DemiBold
                                letterSpacing: 2
                            }
                            color: "#e5d8f2"
                        }
                        Label {
                            text: "Settings"
                            color: "#a696b8"
                            font.pixelSize: 11
                        }
                    }
                }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "Search settings"
                    onTextChanged: win.query = text.toLowerCase()
                }
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    Column {
                        width: parent.width
                        spacing: 3
                        Repeater {
                            model: win.sections
                            Column {
                                required property var modelData
                                width: parent.width
                                visible: !win.query || (modelData.title + " " + modelData.words).toLowerCase().includes(win.query)
                                Label {
                                    visible: modelData.group !== ""
                                    text: modelData.group
                                    color: "#8c7b9f"
                                    font {
                                        pixelSize: 9
                                        letterSpacing: 1
                                    }
                                    topPadding: 18
                                    bottomPadding: 8
                                }
                                Button {
                                    width: parent.width
                                    height: 39
                                    text: modelData.title
                                    onClicked: win.page = modelData.id
                                    contentItem: Label {
                                        text: parent.text
                                        verticalAlignment: Text.AlignVCenter
                                        leftPadding: 12
                                        color: win.page === modelData.id ? "#e9dafc" : "#b6a7c7"
                                    }
                                    background: Rectangle {
                                        radius: 7
                                        color: win.page === modelData.id ? "#382744" : parent.hovered ? "#221a2e" : "transparent"
                                    }
                                }
                            }
                        }
                    }
                }
                Label {
                    text: win.account.login + " · " + win.account.host
                    color: "#8c7b9f"
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0
            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: 30
                spacing: 8
                Label {
                    text: (win.sections.find(s => s.id === win.page) || {}).title || "Settings"
                    font {
                        pixelSize: 25
                        weight: Font.Medium
                    }
                    color: "#eee7f6"
                }
                Label {
                    text: win.page === "tidewm" ? "Edit TideWM and its included files. Syntax is checked before saving." : "Changes are saved together when you apply them."
                    color: "#a696b8"
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
            ScrollView {
                id: scroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: availableWidth
                Loader {
                    width: scroll.availableWidth
                    sourceComponent: ({
                            appearance: appearance,
                            wallpaper: wallpaper,
                            panels: panels,
                            keybinds: keybinds,
                            tidewm: files,
                            files: files,
                            updates: updates,
                            notifications: notifications,
                            idle: idle,
                            account: accountPage,
                            autostart: autostart
                        })[win.page]
                }
            }
        }
    }
    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 76
        color: "#1c1626"
        RowLayout {
            anchors {
                fill: parent
                leftMargin: 22
                rightMargin: 22
            }
            spacing: 12
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Label {
                    text: Store.dirtyCount ? Store.dirtyCount + " file(s) with unsaved changes" : "All changes saved"
                    font.weight: Font.Medium
                    color: "#e7dbf3"
                }
                Label {
                    text: Store.message
                    color: "#a797b9"
                    font.pixelSize: 10
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }
            }
            Button {
                text: "Reload"
                onClicked: {
                    if (Store.dirtyCount) {
                        win.closing = false;
                        discard.open();
                    } else
                        Store.reload();
                }
            }
            Button {
                text: "Apply changes"
                highlighted: true
                enabled: Store.dirtyCount > 0
                onClicked: Store.apply()
            }
        }
    }
    component Note: Label {
        color: "#a696b8"
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        font.pixelSize: 12
    }
    component PageBody: ColumnLayout {
        width: parent ? parent.width : 600
        spacing: 24
        Layout.fillWidth: true
    }
    Component {
        id: appearance
        ColumnLayout {
            width: parent.width
            spacing: 22
            anchors.margins: 30
            Label {
                text: "Palette"
                font.pixelSize: 16
                color: "#dfd1ed"
                Layout.leftMargin: 30
            }
            Flow {
                Layout.fillWidth: true
                Layout.leftMargin: 30
                Layout.rightMargin: 30
                spacing: 12
                Repeater {
                    model: Store.themes
                    Rectangle {
                        required property var modelData
                        width: 218
                        height: 92
                        radius: 9
                        color: modelData.colors.base || "#21182c"
                        border.width: 1
                        border.color: win.get("appearance", "theme", "trench-violet") === modelData.id ? "#c7aae8" : "#42334f"
                        Column {
                            anchors {
                                fill: parent
                                margins: 14
                            }
                            spacing: 13
                            Label {
                                text: modelData.name
                                color: modelData.colors.text || "white"
                                font.pixelSize: 12
                                width: parent.width
                                elide: Text.ElideRight
                            }
                            Row {
                                spacing: 6
                                Repeater {
                                    model: [modelData.colors.accent, modelData.colors.cyan, modelData.colors.rose, modelData.colors.surface1]
                                    Rectangle {
                                        required property var modelData
                                        width: 23
                                        height: 9
                                        radius: 3
                                        color: modelData || "#444"
                                    }
                                }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                win.themeId = modelData.id;
                                Store.setValue("appearance", "theme", modelData.id);
                                Store.setValue("appearance", "fromWallpaper", false);
                            }
                        }
                    }
                }
            }
            JsonForm {
                Layout.fillWidth: true
                Layout.leftMargin: 30
                Layout.rightMargin: 30
                documentId: "appearance"
                fields: [
                    {
                        title: "Colours from wallpaper",
                        key: "fromWallpaper",
                        kind: "bool",
                        fallback: false
                    },
                    {
                        title: "Monochrome icons",
                        key: "mono",
                        kind: "bool",
                        fallback: false
                    }
                ]
            }
            RowLayout {
                Layout.leftMargin: 30
                Layout.rightMargin: 30
                Layout.fillWidth: true
                Label {
                    text: "Custom palette"
                    color: "#dfd1ed"
                    font.pixelSize: 16
                    Layout.fillWidth: true
                }
                Button {
                    text: "Create editable copy"
                    onClicked: {
                        let id = Store.copyTheme(win.themeId);
                        if (id)
                            win.themeId = id;
                    }
                }
            }
            Flow {
                Layout.fillWidth: true
                Layout.leftMargin: 30
                Layout.rightMargin: 30
                spacing: 10
                Repeater {
                    model: ["crust", "base", "surface0", "surface1", "text", "subtext", "accent", "cyan", "rose", "warn", "danger", "success"]
                    Button {
                        required property string modelData
                        width: 145
                        height: 42
                        enabled: !(Store.themes.find(t => t.id === win.themeId) || {
                                readOnly: true
                            }).readOnly
                        contentItem: Label {
                            text: parent.modelData
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: {
                                let c = Qt.color(win.get("theme:" + win.themeId, "colors." + parent.modelData, "#444444"));
                                return (c.r * 0.299 + c.g * 0.587 + c.b * 0.114) > 0.55 ? "#15101e" : "#eee5f7";
                            }
                        }
                        text: modelData
                        icon.name: ""
                        onClicked: {
                            colour.key = modelData;
                            colour.selectedColor = win.get("theme:" + win.themeId, "colors." + modelData, "#ffffff");
                            colour.open();
                        }
                        background: Rectangle {
                            radius: 6
                            color: win.get("theme:" + win.themeId, "colors." + modelData, "#444444")
                            border.width: 1
                            border.color: "#89749d"
                        }
                    }
                }
            }
            JsonForm {
                Layout.fillWidth: true
                Layout.leftMargin: 30
                Layout.rightMargin: 30
                enabled: !(Store.themes.find(t => t.id === win.themeId) || {
                        readOnly: true
                    }).readOnly
                documentId: "theme:" + win.themeId
                fields: [
                    {
                        title: "Panel opacity",
                        key: "glass",
                        kind: "real",
                        min: 0.1,
                        max: 1,
                        fallback: 0.94
                    },
                    {
                        title: "Popup opacity",
                        key: "glassStrong",
                        kind: "real",
                        min: 0.1,
                        max: 1,
                        fallback: 0.98
                    },
                    {
                        title: "Popup corner radius",
                        key: "radius.popup",
                        kind: "number",
                        min: 0,
                        max: 40,
                        fallback: 12
                    },
                    {
                        title: "Control corner radius",
                        key: "radius.control",
                        kind: "number",
                        min: 0,
                        max: 30,
                        fallback: 8
                    }
                ]
            }
            Note {
                Layout.leftMargin: 30
                Layout.rightMargin: 30
                text: "Shipped themes stay intact. Create a copy to edit colours and shape."
            }
        }
    }
    Component {
        id: wallpaper
        ColumnLayout {
            width: parent.width
            spacing: 24
            RowLayout {
                Layout.leftMargin: 30
                Layout.rightMargin: 30
                Layout.fillWidth: true
                ComboBox {
                    model: Store.outputs().concat(["*"])
                    currentIndex: model.indexOf(win.output)
                    onActivated: win.output = currentText
                }
                Button {
                    text: "Choose wallpaper…"
                    onClicked: imagePicker.open()
                }
                Button {
                    text: "Open live picker"
                    onClicked: Store.launch("wallpapers")
                }
            }
            Image {
                Layout.leftMargin: 30
                Layout.rightMargin: 30
                Layout.fillWidth: true
                Layout.preferredHeight: 210
                fillMode: Image.PreserveAspectCrop
                source: {
                    let s = win.get("wallpaper", "screens", {});
                    let e = s[win.output] || s["*"] || {};
                    return e.image ? "file://" + e.image : "";
                }
                visible: source.toString() !== ""
                asynchronous: true
            }
            Note {
                Layout.leftMargin: 30
                Layout.rightMargin: 30
                text: {
                    let s = win.get("wallpaper", "screens", {});
                    let e = s[win.output] || s["*"] || {};
                    return e.video || e.image || "No wallpaper selected for this output.";
                }
            }
            JsonForm {
                Layout.fillWidth: true
                Layout.leftMargin: 30
                Layout.rightMargin: 30
                documentId: "wallpaper"
                fields: [
                    {
                        title: "Image renderer",
                        key: "imageBackend",
                        kind: "choice",
                        fallback: "auto",
                        choices: [
                            {
                                value: "auto",
                                label: "Automatic (awww)"
                            },
                            {
                                value: "native",
                                label: "Native"
                            }
                        ]
                    },
                    {
                        title: "Transition preset",
                        key: "transitionPreset",
                        kind: "choice",
                        fallback: "",
                        choices: [
                            {
                                value: "",
                                label: "Custom"
                            }
                        ].concat(Object.keys(win.transitionProfiles).map(id => ({
                                    value: id,
                                    label: win.transitionProfiles[id].name
                                })))
                    },
                    {
                        title: "Transition",
                        key: "transition",
                        kind: "choice",
                        fallback: "fade",
                        choices: ["none", "fade", "wave", "wipe", "grow", "outer", "left", "right", "random"].map(v => ({
                                    value: v,
                                    label: v
                                }))
                    },
                    {
                        title: "Duration (seconds)",
                        key: "transitionDuration",
                        hint: "Decimals such as 0.6 are supported.",
                        kind: "real",
                        min: 0,
                        max: 3,
                        fallback: 0.6
                    }
                ]
            }
        }
    }
    Component {
        id: panels
        ColumnLayout {
            width: parent.width
            spacing: 20
            Note {
                Layout.leftMargin: 30
                Layout.rightMargin: 30
                text: "The live editor selects widgets directly on your panels. Every widget keeps its own settings, spacing and monitor layout."
            }
            Button {
                Layout.leftMargin: 30
                text: "Edit panels and widgets"
                onClicked: Store.launch("panels")
            }
            Repeater {
                model: Object.keys(win.get("layout", "monitors", {}))
                ColumnLayout {
                    required property string modelData
                    Layout.leftMargin: 30
                    Layout.rightMargin: 30
                    Layout.fillWidth: true
                    spacing: 8
                    Label {
                        text: modelData === "*" ? "Shared monitor layout" : modelData
                        color: "#c7b1e3"
                        font.pixelSize: 15
                    }
                    Repeater {
                        model: win.get("layout", "monitors", {})[modelData].panels || []
                        Label {
                            required property var modelData
                            text: modelData.edge + " · " + modelData.size + " px · " + (modelData.items || []).length + " widgets · " + modelData.visibility
                            color: "#b4a5c6"
                        }
                    }
                }
            }
            Button {
                Layout.leftMargin: 30
                text: "Edit layout configuration"
                onClicked: {
                    win.documentId = "layout";
                    win.page = "files";
                }
            }
        }
    }
    Component {
        id: keybinds
        ColumnLayout {
            width: parent.width
            spacing: 12
            Note {
                Layout.leftMargin: 30
                Layout.rightMargin: 30
                text: "Shortcuts from config.wave and its includes. Save a row to the draft, then Apply changes. Complex multi-line bindings remain editable in TideWM."
            }
            RowLayout {
                Layout.leftMargin: 30
                Layout.rightMargin: 30
                Layout.fillWidth: true
                TextField {
                    id: newChord
                    placeholderText: "Super+Shift+X"
                    Layout.preferredWidth: 190
                }
                TextField {
                    id: newAction
                    placeholderText: "TideWM action, e.g. spawn:kitty"
                    Layout.fillWidth: true
                }
                Button {
                    text: "Add shortcut"
                    enabled: newChord.text !== "" && newAction.text !== ""
                    onClicked: {
                        let d = Store.documents.find(d => d.id.startsWith("wave:") && d.label === "config.wave");
                        if (d && Store.setBinding(d.id, -1, newChord.text, newAction.text)) {
                            newChord.clear();
                            newAction.clear();
                        }
                    }
                }
            }
            Repeater {
                model: Store.bindings
                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.leftMargin: 30
                    Layout.rightMargin: 30
                    spacing: 8
                    TextField {
                        id: chord
                        text: modelData.chord
                        placeholderText: modelData.file
                        Layout.preferredWidth: 200
                        selectByMouse: true
                    }
                    TextField {
                        id: action
                        text: modelData.action
                        Layout.fillWidth: true
                        selectByMouse: true
                    }
                    Button {
                        text: "Save row"
                        enabled: !modelData.readOnly
                        onClicked: Store.setBinding(modelData.id, modelData.line, chord.text, action.text)
                    }
                }
            }
        }
    }
    Component {
        id: files
        ColumnLayout {
            width: parent.width
            spacing: 12
            ComboBox {
                id: doc
                Layout.leftMargin: 30
                Layout.rightMargin: 30
                Layout.fillWidth: true
                model: Store.documents.filter(d => win.page !== "tidewm" || d.id.startsWith("wave:"))
                textRole: "label"
                valueRole: "id"
                currentIndex: Math.max(0, model.findIndex(d => d.id === win.documentId))
                onActivated: win.documentId = currentValue
            }
            Note {
                Layout.leftMargin: 30
                Layout.rightMargin: 30
                text: (doc.currentIndex >= 0 ? doc.model[doc.currentIndex].path : "") + ((doc.currentIndex >= 0 && doc.model[doc.currentIndex].readOnly) ? " · Read only" : "")
            }
            TextArea {
                id: editor
                Layout.leftMargin: 30
                Layout.rightMargin: 30
                Layout.fillWidth: true
                Layout.preferredHeight: 440
                property string selectedId: doc.currentIndex >= 0 ? doc.model[doc.currentIndex].id : ""
                text: {
                    win.revision;
                    return Store.text(selectedId);
                }
                readOnly: doc.currentIndex < 0 || doc.model[doc.currentIndex].readOnly
                font.family: "Monospace"
                font.pixelSize: 12
                selectByMouse: true
                wrapMode: TextEdit.NoWrap
                onTextChanged: if (activeFocus)
                    Store.setText(selectedId, text)
                background: Rectangle {
                    color: "#17121f"
                    radius: 8
                    border.width: 1
                    border.color: "#3a2c48"
                }
            }
            Note {
                Layout.leftMargin: 30
                Layout.rightMargin: 30
                text: "Unknown keys and comments are retained. Apply checks JSON and Wave syntax, creates backups and refuses to overwrite files changed by another app."
            }
        }
    }
    Component {
        id: updates
        ColumnLayout {
            width: parent.width
            spacing: 22
            JsonForm {
                Layout.fillWidth: true
                Layout.leftMargin: 30
                Layout.rightMargin: 30
                documentId: "updates"
                fields: [
                    {
                        title: "Check every (minutes)",
                        hint: "0 disables automatic checks.",
                        key: "intervalMinutes",
                        kind: "number",
                        fallback: 60,
                        max: 10080
                    },
                    {
                        title: "Check at login",
                        key: "onStartup",
                        kind: "bool",
                        fallback: true
                    },
                    {
                        title: "Check after installs",
                        key: "afterTransactions",
                        kind: "bool",
                        fallback: true
                    },
                    {
                        title: "Package manager",
                        key: "manager",
                        kind: "choice",
                        fallback: "auto",
                        choices: [
                            {
                                value: "auto",
                                label: "Automatic"
                            }
                        ].concat((win.caps.managers || []).map(m => ({
                                    value: m,
                                    label: m
                                })), [
                            {
                                value: "none",
                                label: "No system packages"
                            }
                        ])
                    },
                    {
                        title: "Flatpak updates",
                        key: "flatpak",
                        kind: "bool",
                        fallback: true
                    },
                    {
                        title: "Include AUR packages",
                        hint: "Applies to pacman, paru and yay.",
                        key: "includeAur",
                        kind: "bool",
                        fallback: true
                    },
                    {
                        title: "AUR helper",
                        key: "aurHelper",
                        kind: "choice",
                        fallback: "auto",
                        choices: ["auto", "paru", "yay"].map(v => ({
                                    value: v,
                                    label: v
                                }))
                    }
                ]
            }
            Note {
                Layout.leftMargin: 30
                Layout.rightMargin: 30
                text: "Fedora repository selection and package ignore/important rules are also preserved in updates.json."
            }
        }
    }
    Component {
        id: notifications
        JsonForm {
            width: parent.width
            Layout.leftMargin: 30
            Layout.rightMargin: 30
            documentId: "notifications"
            fields: [
                {
                    title: "Notification duration (ms)",
                    key: "toastDuration",
                    kind: "number",
                    min: 1000,
                    max: 30000,
                    fallback: 4200
                },
                {
                    title: "Maximum visible notifications",
                    key: "maxToasts",
                    kind: "number",
                    min: 1,
                    max: 10,
                    fallback: 5
                },
                {
                    title: "Start in Do Not Disturb",
                    key: "dnd",
                    kind: "bool",
                    fallback: false
                }
            ]
        }
    }
    Component {
        id: idle
        JsonForm {
            width: parent.width
            Layout.leftMargin: 30
            Layout.rightMargin: 30
            documentId: "idle"
            fields: [
                {
                    title: "Blank screen after (minutes)",
                    hint: "0 means never. Screen blanking does not power off the display.",
                    key: "blank",
                    kind: "number",
                    fallback: 0,
                    max: 1440
                },
                {
                    title: "Lock after (minutes)",
                    hint: "0 means never. Caffeine pauses the idle timers.",
                    key: "lock",
                    kind: "number",
                    fallback: 0,
                    max: 1440
                }
            ]
        }
    }
    Component {
        id: accountPage
        ColumnLayout {
            width: parent.width
            spacing: 24
            RowLayout {
                Layout.leftMargin: 30
                Layout.rightMargin: 30
                Layout.fillWidth: true
                Image {
                    Layout.preferredWidth: 72
                    Layout.preferredHeight: 72
                    fillMode: Image.PreserveAspectCrop
                    source: {
                        let p = win.get("profile", "avatar", win.account.avatar);
                        return p ? "file://" + p : "";
                    }
                    sourceSize: Qt.size(144, 144)
                }
                ColumnLayout {
                    Label {
                        text: win.account.login
                        color: "#ecdef7"
                        font.pixelSize: 20
                    }
                    Label {
                        text: win.account.host
                        color: "#a696b8"
                    }
                }
                Item {
                    Layout.fillWidth: true
                }
                Button {
                    text: "Choose avatar…"
                    onClicked: avatarPicker.open()
                }
            }
            JsonForm {
                Layout.fillWidth: true
                Layout.leftMargin: 30
                Layout.rightMargin: 30
                documentId: "profile"
                fields: [
                    {
                        title: "Display name",
                        hint: "Shown in the Abyssal quick menu. Your system login stays unchanged.",
                        key: "displayName",
                        fallback: win.account.login
                    }
                ]
            }
            Note {
                Layout.leftMargin: 30
                Layout.rightMargin: 30
                text: "Home folder: " + win.account.home
            }
            Button {
                Layout.leftMargin: 30
                text: "Change login password…"
                onClicked: Store.launch("password")
            }
        }
    }
    Component {
        id: autostart
        ColumnLayout {
            width: parent.width
            spacing: 18
            Note {
                Layout.leftMargin: 30
                Layout.rightMargin: 30
                text: "Additional apps to launch when you log into TideWM. Existing startup commands stay in config.wave. Applying this list does not launch anything immediately."
            }
            Repeater {
                model: win.startup()
                RowLayout {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.leftMargin: 30
                    Layout.rightMargin: 30
                    Switch {
                        checked: modelData.enabled !== false
                        onToggled: {
                            let a = win.startup();
                            a[index].enabled = checked;
                            Store.setAutostart(a);
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        Label {
                            text: modelData.name || modelData.command
                            color: "#e5d6f1"
                        }
                        Label {
                            text: modelData.command
                            color: "#a08cae"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                    Button {
                        text: "Remove"
                        onClicked: {
                            let a = win.startup();
                            a.splice(index, 1);
                            Store.setAutostart(a);
                        }
                    }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 30
                Layout.rightMargin: 30
                spacing: 8
                TextField {
                    id: startupName
                    Layout.fillWidth: true
                    placeholderText: "App name"
                }
                TextField {
                    id: startupCommand
                    Layout.fillWidth: true
                    placeholderText: "Command, for example: firefox"
                }
                Button {
                    text: "Add startup app"
                    enabled: startupCommand.text.trim() !== ""
                    onClicked: {
                        let a = win.startup();
                        a.push({
                            name: startupName.text.trim(),
                            command: startupCommand.text.trim(),
                            enabled: true
                        });
                        Store.setAutostart(a);
                        startupName.clear();
                        startupCommand.clear();
                    }
                }
            }
        }
    }
}
