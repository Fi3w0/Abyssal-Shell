import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

ApplicationWindow {
    id: win
    visible: true
    width: 1180
    height: 780
    minimumWidth: 860
    minimumHeight: 560
    title: "Abyssal Settings"
    color: "transparent"
    palette {
        window: Theme.base
        windowText: Theme.text
        base: Theme.deep
        alternateBase: Theme.surface1
        text: Theme.text
        button: Theme.deep
        buttonText: Theme.text
        highlight: Theme.glow
        highlightedText: Theme.crust
        placeholderText: Theme.subtext
        mid: Theme.edge
        dark: Theme.crust
        light: Theme.glowEdge
    }
    font.family: Theme.fontFamily
    font.pixelSize: 12
    background: Atmosphere {
        active: win.active
        exposed: win.visible && win.visibility !== Window.Minimized
    }
    property int revision: 0
    property string page: initialPage === "tidewm" ? "windows" : initialPage
    property string query: ""
    property string themeId: Theme.themeId
    property string output: Store.outputs()[0] || "*"
    property var account: Store.account()
    property var caps: Store.capabilities()
    property var transitionProfiles: Store.transitions()
    property bool allowClose: false
    property bool closing: false
    // TideWM has no minimized window state. Keep this session available through
    // the existing launcher activation socket while its surface is hidden.
    property bool hideOnMinimize: false
    property bool hiddenByMinimize: false
    property bool restoreMaximized: false
    function minimizeWindow() {
        if (hideOnMinimize) {
            restoreMaximized = visibility === Window.Maximized;
            hiddenByMinimize = true;
            hide();
        } else {
            showMinimized();
        }
    }
    function restoreWindow() {
        if (hiddenByMinimize && restoreMaximized)
            showMaximized();
        else if (hiddenByMinimize || visibility === Window.Minimized)
            showNormal();
        else
            show();
        hiddenByMinimize = false;
        raise();
        requestActivate();
    }
    property string documentId: "layout"
    readonly property var sections: [
        {
            id: "appearance",
            title: "Colours & theme",
            group: "LOOK",
            words: "appearance palette fonts style"
        },
        { id: "appLook", title: "This app", group: "", words: "background glass glow shafts marine snow density font motion appearance" },
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
        { id: "windows", title: "Windows & workspaces", group: "DESKTOP", words: "layout gaps columns scroll ocean classic borders corners" },
        { id: "motion", title: "Motion & effects", group: "", words: "animations speed transition effects workspace viscosity" },
        { id: "input", title: "Keyboard & touchpad", group: "INPUT", words: "keyboard layouts language mouse focus tapping pointer scrolling repeat" },
        { id: "keybinds", title: "Shortcuts", group: "", words: "keyboard shortcuts commands binds" },
        {
            id: "autostart",
            title: "Startup apps",
            group: "SYSTEM",
            words: "login autostart applications"
        },
        {
            id: "updates",
            title: "Updates",
            group: "",
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
            group: "EXPERT",
            words: "json wave edit backup"
        }
    ]

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
        onAccepted: { if (key === "accent") Store.setAccent(selectedColor.toString()); else Store.setValue("theme:" + win.themeId, "colors." + key, selectedColor.toString()); }
    }
    function searchable(section) {
        const desktop = Store.desktopPages.find(p => p.id === section.id);
        return (section.title + " " + section.words + " " + (desktop ? desktop.groups.flatMap(g => g.rows.map(r => r.title + " " + (r.hint || ""))).join(" ") : "")).toLowerCase();
    }
    function openPage(target) { const page = target === "tidewm" ? "windows" : target; if (sections.some(s => s.id === page)) navigate(page); }
    property bool saveFailed: false
    property bool recording: false
    readonly property var currentSection: sections.find(s => s.id === page) || sections[0]
    readonly property string currentHall: {
        let hall = "settings";
        for (const section of sections) { if (section.group) hall = section.group.toLowerCase(); if (section.id === page) break; }
        return hall;
    }
    readonly property bool narrow: width < 1000
    property var history: []
    function navigate(target) {
        if (page === target) return;
        history = history.concat([page]);
        page = target;
    }
    Shortcut { enabled: !win.recording; sequence: "Ctrl+F"; onActivated: { search.forceActiveFocus(); search.selectAll(); } }
    Shortcut { enabled: !win.recording; sequence: "Ctrl+,"; onActivated: win.navigate("appLook") }
    Shortcut { enabled: !win.recording; sequence: "Alt+Left"; onActivated: { if (win.history.length) { const h = win.history.slice(); win.page = h.pop(); win.history = h; } } }
    header: Rectangle {
        height: 44
        color: Theme.bar
        Item {
            anchors.fill: parent
            anchors.leftMargin: 50
            anchors.rightMargin: 120
            DragHandler { target: null; onActiveChanged: if (active) win.startSystemMove() }
            TapHandler { onDoubleTapped: win.visibility === Window.Maximized ? win.showNormal() : win.showMaximized() }
        }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 8
            spacing: 8
            WindowButton { symbol: "back"; text: "Back"; enabled: win.history.length > 0; onClicked: { const h = win.history.slice(); win.page = h.pop(); win.history = h; } }
            Label { text: "abyssal"; color: Theme.text; font.bold: true; font.letterSpacing: 0.5 }
            Label { text: "· settings — " + win.currentSection.title.toLowerCase(); color: Theme.subtext; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
            WindowButton { objectName: "minimizeWindow"; symbol: "minimize"; text: win.hideOnMinimize ? "Minimize · reopen Settings to restore" : "Minimize"; onClicked: win.minimizeWindow() }
            WindowButton { symbol: win.visibility === Window.Maximized ? "restore" : "maximize"; text: win.visibility === Window.Maximized ? "Restore" : "Maximize"; onClicked: win.visibility === Window.Maximized ? win.showNormal() : win.showMaximized() }
            WindowButton { symbol: "close"; text: "Close"; destructive: true; onClicked: win.close() }
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.edge }
    }
    RowLayout {
        anchors.fill: parent
        spacing: 0
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: win.narrow ? 56 : 262
            color: Theme.side
            Rectangle { anchors.right: parent.right; height: parent.height; width: 1; color: Theme.edge }
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: win.narrow ? 5 : 12
                spacing: 10
                ArchiveButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 62
                    Accessible.name: "Account"
                    onClicked: win.navigate("account")
                    contentItem: RowLayout {
                        spacing: 10
                        Avatar {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            source: { const path = win.get("profile", "avatar", win.account.avatar); return path ? "file://" + path : ""; }
                            Label { anchors.centerIn: parent; visible: !parent.source.toString(); text: (win.account.login || "a").slice(0, 1).toUpperCase(); color: Theme.glow; font.bold: true }
                        }
                        ColumnLayout {
                            visible: !win.narrow
                            spacing: 3
                            Label { text: win.get("profile", "displayName", win.account.login); color: Theme.text; font.bold: true; Layout.fillWidth: true; elide: Text.ElideRight }
                            Label { text: "account · " + (Theme.theme.name || Theme.themeId); color: Theme.subtext; font.pixelSize: 10; Layout.fillWidth: true; elide: Text.ElideRight }
                        }
                    }
                }
                ArchiveTextField {
                    id: search
                    Layout.fillWidth: true
                    placeholderText: win.narrow ? "…" : "Search settings"
                    rightPadding: win.narrow ? 8 : 34
                    Label { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; visible: !win.narrow; text: "^F"; color: Theme.subtext; font.pixelSize: 10 }
                    Accessible.name: "Search settings"
                    onTextChanged: win.query = text.toLowerCase()
                    ToolTip.visible: hovered && win.narrow
                    ToolTip.text: "Search settings · Ctrl+F"
                }
                ScrollView {
                    id: navigation
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: availableWidth
                    clip: true
                    Column {
                        id: navColumn
                        width: navigation.availableWidth
                        spacing: 3
                        property Item selectedItem: null
                        Rectangle {
                            id: selection
                            parent: navColumn.parent
                            z: -1
                            visible: !!navColumn.selectedItem && navColumn.selectedItem.parent.visible
                            x: 0
                            y: navColumn.selectedItem ? navColumn.selectedItem.y + navColumn.selectedItem.parent.y : 0
                            width: navColumn.width
                            height: navColumn.selectedItem ? navColumn.selectedItem.height : 0
                            radius: Theme.radius
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: Theme.glowSoft }
                                GradientStop { position: 0.85; color: Theme.setting("selectionStyle", "edge") === "filled" ? Theme.glowSoft : "transparent" }
                            }
                            Rectangle {
                                width: Theme.setting("selectionStyle", "edge") === "underline" ? parent.width : 2
                                height: Theme.setting("selectionStyle", "edge") === "underline" ? 2 : parent.height
                                anchors.bottom: parent.bottom
                                color: Theme.glow
                            }
                            Behavior on y { enabled: !Theme.reduceMotion; NumberAnimation { duration: 220; easing.type: Easing.OutQuint } }
                        }
                        Repeater {
                            model: win.sections
                            Column {
                                id: navEntry
                                required property var modelData
                                width: parent.width
                                visible: !win.query || win.searchable(modelData).includes(win.query)
                                RowLayout {
                                    width: parent.width
                                    visible: modelData.group !== "" && !win.narrow
                                    spacing: 8
                                    Label { text: modelData.group; color: Theme.subtext; font.pixelSize: 10; font.letterSpacing: 2; topPadding: 16; bottomPadding: 6 }
                                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.edge; Layout.topMargin: 10 }
                                }
                                ArchiveButton {
                                    id: navButton
                                    width: parent.width
                                    height: Math.max(28, 28 * Theme.density)
                                    text: win.narrow ? modelData.title.slice(0, 2).toLowerCase() : modelData.title.toLowerCase()
                                    Accessible.name: modelData.title
                                    onClicked: win.navigate(modelData.id)
                                    function updateSelection() {
                                        if (win.page === modelData.id && navEntry.visible) navColumn.selectedItem = navButton;
                                    }
                                    Component.onCompleted: updateSelection()
                                    Connections { target: win; function onPageChanged() { navButton.updateSelection(); } function onQueryChanged() { Qt.callLater(navButton.updateSelection); } }
                                    contentItem: RowLayout {
                                        spacing: 10
                                        ArchiveIcon { symbol: modelData.id; tint: win.page === modelData.id ? Theme.glow : Theme.subtext; Layout.preferredWidth: 15; Layout.preferredHeight: 15; Layout.leftMargin: win.narrow ? 4 : 10 }
                                        Label { visible: !win.narrow; text: navButton.text; verticalAlignment: Text.AlignVCenter; color: win.page === modelData.id ? Theme.glow : navButton.hovered ? Theme.text : Theme.subtext; font.pixelSize: 11; font.bold: win.page === modelData.id; Layout.fillWidth: true; elide: Text.ElideRight }
                                    }
                                    background: Rectangle {
                                        color: navButton.hovered ? Theme.glass : "transparent"
                                        Rectangle { width: 1; height: parent.height; color: Theme.edge; visible: win.page !== modelData.id }
                                    }
                                    ToolTip.visible: hovered && win.narrow
                                    ToolTip.text: modelData.title
                                }
                            }
                        }
                    }
                }
                Label { visible: !win.narrow; text: win.account.login + " · " + win.account.host; color: Theme.subtext; font.pixelSize: 10; Layout.fillWidth: true; elide: Text.ElideRight }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0
            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: 22 * Theme.density
                spacing: 5
                Label { text: win.currentHall + " › " + win.currentSection.title.toLowerCase(); color: Theme.subtext; font.pixelSize: 11 }
                Label { text: win.currentSection.title; color: Theme.text; font.pixelSize: 26; font.weight: Font.ExtraBold; font.letterSpacing: -0.5; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                Label {
                    text: win.page === "appLook" ? "Shape the water, light and surfaces. One accent follows the whole desktop." : (Store.desktopPages.find(p => p.id === win.page) || {}).description || "Choose your preferences, then save your changes."
                    color: Theme.subtext
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
            RowLayout {
                visible: Store.externalChange
                Layout.fillWidth: true
                Layout.leftMargin: 22
                Layout.rightMargin: 22
                Label { text: "Settings changed in another app. Your unsaved changes are kept."; color: Theme.warn; font.pixelSize: 11; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                ArchiveButton { text: "Reload"; onClicked: { win.closing = false; discard.open(); } }
            }
            ScrollView {
                id: scroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: availableWidth
                Loader {
                    id: pageLoader
                    x: 22 * Theme.density
                    width: Math.max(0, scroll.availableWidth - 44 * Theme.density)
                    sourceComponent: ({ appearance: appearance, appLook: appLook, wallpaper: wallpaper, panels: panels, keybinds: keybinds, windows: desktopPage, motion: desktopPage, input: desktopPage, files: files, updates: updates, notifications: notifications, idle: idle, account: accountPage, autostart: autostart })[win.page] || appearance
                    onLoaded: { scroll.contentItem.contentY = 0; pageEnter.restart(); }
                    SequentialAnimation {
                        id: pageEnter
                        PropertyAction { target: pageLoader; property: "opacity"; value: 0 }
                        NumberAnimation { target: pageLoader; property: "opacity"; to: 1; duration: Theme.reduceMotion ? 80 : 180; easing.type: Easing.OutCubic }
                    }
                }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: win.saveFailed ? 64 : 52
                color: Theme.bar
                Rectangle { width: parent.width; height: 1; color: Theme.edge }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 22
                    anchors.rightMargin: 22
                    spacing: 12
                    Rectangle { width: 6; height: 6; radius: 3; color: win.saveFailed ? Theme.danger : Store.dirtyCount ? Theme.warn : Theme.success }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        Label { text: win.saveFailed ? "Couldn’t save changes" : Store.dirtyCount ? "Unsaved changes" : "Changes saved"; color: Theme.text; font.pixelSize: 11 }
                        Label { visible: win.saveFailed; text: Store.message; color: Theme.subtext; font.pixelSize: 10; Layout.fillWidth: true; elide: Text.ElideMiddle }
                    }
                    Label { visible: !Store.dirtyCount; text: "Ctrl+F  Search"; color: Theme.subtext; font.pixelSize: 10 }
                    ArchiveButton { text: "Discard"; visible: Store.dirtyCount > 0; onClicked: { win.closing = false; discard.open(); win.saveFailed = false; } }
                    ArchiveButton { objectName: "saveChanges"; text: "Save changes"; visible: Store.dirtyCount > 0; highlighted: true; onClicked: { if (win.activeFocusItem) win.activeFocusItem.focus = false; win.saveFailed = !Store.apply(); } }
                }
            }
        }
    }
    component Note: Label {
        color: Theme.subtext
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        font.pixelSize: 12
    }
    component PageBody: ColumnLayout {
        width: parent ? parent.width : 600
        spacing: 24
        Layout.fillWidth: true
    }
    Component { id: desktopPage; DesktopPage { pageId: win.page; query: win.query } }
    Component {
        id: appLook
        AppLook {}
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
                color: Theme.glow
                Layout.leftMargin: 0
            }
            Flow {
                Layout.fillWidth: true
                Layout.leftMargin: 0
                Layout.rightMargin: 0
                spacing: 12
                Repeater {
                    model: Store.themes
                    Rectangle {
                        required property var modelData
                        width: 218
                        height: 92
                        radius: 9
                        color: modelData.colors.base || Theme.base
                        border.width: 1
                        border.color: Theme.themeId === modelData.id ? Theme.glow : Theme.edge
                        Column {
                            anchors {
                                fill: parent
                                margins: 14
                            }
                            spacing: 13
                            Label {
                                text: modelData.name
                                color: modelData.colors.text || Theme.text
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
                                        color: modelData || Theme.overlay
                                    }
                                }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                                                Store.setValue("appearance", "theme", modelData.id);
                                Store.setValue("appearance", "fromWallpaper", false);
                            }
                        }
                    }
                }
            }
            JsonForm {
                Layout.fillWidth: true
                Layout.leftMargin: 0
                Layout.rightMargin: 0
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
                Layout.leftMargin: 0
                Layout.rightMargin: 0
                Layout.fillWidth: true
                Label {
                    text: "Custom palette"
                    color: Theme.glow
                    font.pixelSize: 16
                    Layout.fillWidth: true
                }
                ArchiveButton {
                    text: "Create editable copy"
                    onClicked: {
                        let id = Store.copyTheme(win.themeId);
                        if (id)
                            Store.setValue("appearance", "theme", id);
                    }
                }
            }
            Flow {
                Layout.fillWidth: true
                Layout.leftMargin: 0
                Layout.rightMargin: 0
                spacing: 10
                Repeater {
                    model: ["crust", "base", "surface0", "surface1", "overlay", "text", "subtext", "accent", "cyan", "rose", "warn", "danger", "success"]
                    ArchiveButton {
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
                                let c = Qt.color(win.get("theme:" + win.themeId, "colors." + parent.modelData, Theme.overlay));
                                return (c.r * 0.299 + c.g * 0.587 + c.b * 0.114) > 0.55 ? Theme.crust : Theme.text;
                            }
                        }
                        text: modelData
                        icon.name: ""
                        onClicked: {
                            colour.key = modelData;
                            colour.selectedColor = win.get("theme:" + win.themeId, "colors." + modelData, Theme.text);
                            colour.open();
                        }
                        background: Rectangle {
                            radius: 6
                            color: win.get("theme:" + win.themeId, "colors." + modelData, Theme.overlay)
                            border.width: 1
                            border.color: Theme.edge
                        }
                    }
                }
            }
            JsonForm {
                Layout.fillWidth: true
                Layout.leftMargin: 0
                Layout.rightMargin: 0
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
                Layout.leftMargin: 0
                Layout.rightMargin: 0
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
                Layout.leftMargin: 0
                Layout.rightMargin: 0
                Layout.fillWidth: true
                ArchiveComboBox {
                    model: Store.outputs().concat(["*"])
                    currentIndex: model.indexOf(win.output)
                    onActivated: win.output = currentText
                }
                ArchiveButton {
                    text: "Choose wallpaper…"
                    onClicked: imagePicker.open()
                }
                ArchiveButton {
                    text: "Open live picker"
                    onClicked: Store.launch("wallpapers")
                }
            }
            Image {
                Layout.leftMargin: 0
                Layout.rightMargin: 0
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
                Layout.leftMargin: 0
                Layout.rightMargin: 0
                text: {
                    let s = win.get("wallpaper", "screens", {});
                    let e = s[win.output] || s["*"] || {};
                    return e.video || e.image || "No wallpaper selected for this output.";
                }
            }
            JsonForm {
                Layout.fillWidth: true
                Layout.leftMargin: 0
                Layout.rightMargin: 0
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
    Component { id: panels; PanelsPage {} }
    Component {
        id: keybinds
        ShortcutsPage { query: win.query; onRecordingChanged: win.recording = recording }
    }
    Component {
        id: files
        ColumnLayout {
            width: parent.width
            spacing: 12
            ArchiveComboBox {
                id: doc
                readonly property var selectedDocument: model[currentIndex] || {}
                Layout.leftMargin: 0
                Layout.rightMargin: 0
                Layout.fillWidth: true
                model: Store.documents.filter(d => win.page !== "tidewm" || d.id.startsWith("wave:"))
                textRole: "label"
                valueRole: "id"
                currentIndex: Math.max(0, model.findIndex(d => d.id === win.documentId))
                onActivated: win.documentId = currentValue
            }
            Note {
                Layout.leftMargin: 0
                Layout.rightMargin: 0
                text: (doc.selectedDocument.path || "") + ((doc.selectedDocument.readOnly) ? " · Read only" : "")
            }
            TextArea {
                id: editor
                Layout.leftMargin: 0
                Layout.rightMargin: 0
                Layout.fillWidth: true
                Layout.preferredHeight: 440
                property string selectedId: doc.selectedDocument.id || ""
                text: {
                    win.revision;
                    return Store.text(selectedId);
                }
                readOnly: !doc.selectedDocument.id || !!doc.selectedDocument.readOnly
                font.family: "Monospace"
                font.pixelSize: 12
                selectByMouse: true
                wrapMode: TextEdit.NoWrap
                onTextChanged: if (activeFocus)
                    Store.setText(selectedId, text)
                background: Rectangle {
                    color: Theme.deep
                    radius: 8
                    border.width: 1
                    border.color: Theme.edge
                }
            }
            Note {
                Layout.leftMargin: 0
                Layout.rightMargin: 0
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
                Layout.leftMargin: 0
                Layout.rightMargin: 0
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
                Layout.leftMargin: 0
                Layout.rightMargin: 0
                text: "Fedora repository selection and package ignore/important rules are also preserved in updates.json."
            }
        }
    }
    Component {
        id: notifications
        JsonForm {
            width: parent.width
            documentId: "notifications"
            fields: [
                {
                    title: "Show notifications for",
                    key: "toastDuration",
                    kind: "slider",
                    min: 1,
                    max: 30,
                    step: 0.1,
                    scale: 0.001,
                    unit: " s",
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
                Layout.leftMargin: 0
                Layout.rightMargin: 0
                Layout.fillWidth: true
                Avatar {
                    Layout.preferredWidth: 72
                    Layout.preferredHeight: 72
                    source: { const p = win.get("profile", "avatar", win.account.avatar); return p ? "file://" + p : ""; }
                }
                ColumnLayout {
                    Label {
                        text: win.account.login
                        color: Theme.text
                        font.pixelSize: 20
                    }
                    Label {
                        text: win.account.host
                        color: Theme.subtext
                    }
                }
                Item {
                    Layout.fillWidth: true
                }
                ArchiveButton {
                    text: "Choose avatar…"
                    onClicked: avatarPicker.open()
                }
            }
            JsonForm {
                Layout.fillWidth: true
                Layout.leftMargin: 0
                Layout.rightMargin: 0
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
                Layout.leftMargin: 0
                Layout.rightMargin: 0
                text: "Home folder: " + win.account.home
            }
            ArchiveButton {
                Layout.leftMargin: 0
                text: "Change login password…"
                onClicked: Store.launch("password")
            }
        }
    }
    Component { id: autostart; StartupPage {} }
}
