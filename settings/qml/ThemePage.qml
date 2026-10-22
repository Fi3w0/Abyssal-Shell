import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property string selectedRole: "accent"
    readonly property bool wide: width >= 760
    readonly property var roles: [
        {key:"crust",hint:"deepest · bars, edges",group:"SURFACES"}, {key:"base",hint:"window background",group:""},
        {key:"surface0",hint:"cards, popups",group:""}, {key:"surface1",hint:"hover, inputs",group:""}, {key:"overlay",hint:"muted icons",group:""},
        {key:"text",hint:"main text",group:"TEXT"}, {key:"subtext",hint:"hints, labels",group:""},
        {key:"accent",hint:"buttons, focus & glow",group:"ACCENTS"}, {key:"cyan",hint:"information",group:""}, {key:"rose",hint:"highlights",group:""},
        {key:"warn",hint:"warnings, caution",group:"STATES"}, {key:"danger",hint:"errors, delete",group:""}, {key:"success",hint:"saved, connected",group:""}]
    function roleColor(key) { return Theme.colors[key] || Theme[key] || Theme.text; }
    function luminance(color) {
        const c=Qt.color(color);
        function linear(v) { return v <= .04045 ? v/12.92 : Math.pow((v+.055)/1.055,2.4); }
        return .2126*linear(c.r)+.7152*linear(c.g)+.0722*linear(c.b);
    }
    function contrast(a,b) { const x=luminance(a),y=luminance(b); return (Math.max(x,y)+.05)/(Math.min(x,y)+.05); }
    spacing: 14
    Label { text: "Choose a theme or make it yours. Changes preview here before you save."; color: Theme.subtext; font.pixelSize: 11; wrapMode: Text.WordWrap; Layout.fillWidth: true }
    Flow {
        id: cards
        Layout.fillWidth: true
        spacing: 8
        Repeater {
            model: Store.themes
            ArchiveButton {
                id: themeCard
                required property var modelData
                objectName: "themeCard-" + modelData.id
                width: root.wide ? (cards.width-24)/4 : (cards.width-8)/2
                height: 65
                Accessible.name: "Load theme " + modelData.name
                checked: Theme.themeId === modelData.id
                onClicked: { Store.setValue("appearance", "theme", modelData.id); Store.setValue("appearance", "fromWallpaper", false); }
                contentItem: ColumnLayout {
                    spacing: 6
                    RowLayout {
                        Layout.fillWidth: true; spacing: 0
                        Repeater { model: ["crust","base","surface0","surface1","accent","cyan","rose"]; Rectangle { required property string modelData; Layout.fillWidth: true; height: 21; color: themeCard.modelData.colors[modelData] || Theme[modelData] } }
                    }
                    Label { text: (Theme.themeId === modelData.id ? "• " : "") + modelData.name; color: Theme.themeId === modelData.id ? Theme.glow : Theme.text; font.pixelSize: 10; Layout.fillWidth: true; elide: Text.ElideRight }
                }
            }
        }
    }
    PresetActions { kind: "theme"; Layout.fillWidth: true }
    GridLayout {
        Layout.fillWidth: true
        columns: root.wide ? 2 : 1
        columnSpacing: 14; rowSpacing: 14
        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.alignment: Qt.AlignTop
            spacing: 14
            SettingGroup {
                title: "Colour editor"
                ArchiveComboBox {
                    objectName: "colourRole"
                    Layout.fillWidth: true
                    model: root.roles
                    textRole: "key"; valueRole: "key"
                    currentIndex: model.findIndex(r => r.key === root.selectedRole)
                    Accessible.name: "Palette colour to edit"
                    onActivated: root.selectedRole = currentValue
                }
                Label { text: (root.roles.find(r => r.key === root.selectedRole) || {}).hint || ""; color: Theme.subtext; font.pixelSize: 10; Layout.topMargin: 5; Layout.bottomMargin: 8 }
                ColourEditor { Layout.fillWidth: true; valueColor: root.roleColor(root.selectedRole); onEdited: next => Store.setThemeColor(root.selectedRole, next.toString()) }
                Label { text: "Editing a shipped or wallpaper theme creates your own copy."; color: Theme.subtext; font.pixelSize: 10; wrapMode: Text.WordWrap; Layout.fillWidth: true; Layout.topMargin: 8 }
            }
            SettingGroup {
                title: "Palette"
                Label { text: Theme.theme.name || Theme.themeId; color: Theme.subtext; font.pixelSize: 10; Layout.fillWidth: true; elide: Text.ElideRight }
                Repeater {
                    model: ["SURFACES", "TEXT", "ACCENTS", "STATES"]
                    ColumnLayout {
                        required property string modelData
                        Layout.fillWidth: true
                        Layout.topMargin: 9
                        spacing: 5
                        Label { text: modelData; color: Theme.subtext; font.pixelSize: 9; font.letterSpacing: 1 }
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2; columnSpacing: 5; rowSpacing: 4
                            Repeater {
                                model: { let group=""; return root.roles.filter(r => { if (r.group) group=r.group; return group===modelData; }); }
                                ArchiveButton {
                                    required property var modelData
                                    objectName: "colourToken-" + modelData.key
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 1
                                    implicitHeight: 43
                                    padding: 5
                                    checked: root.selectedRole === modelData.key
                                    Accessible.name: "Edit " + modelData.key + " colour"
                                    onClicked: root.selectedRole = modelData.key
                                    contentItem: RowLayout {
                                        spacing: 7
                                        Rectangle { width: 21; height: 27; radius: 4; color: root.roleColor(modelData.key); border.color: Theme.edge }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            Label { text: modelData.key; color: Theme.text; font.pixelSize: 10 }
                                            Label { text: root.roleColor(modelData.key).toString(); color: Theme.subtext; font.pixelSize: 9 }
                                        }
                                    }
                                    ToolTip.visible: hovered
                                    ToolTip.text: modelData.hint
                                }
                            }
                        }
                    }
                }

            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.alignment: Qt.AlignTop
            spacing: 14
            ThemePreview { Layout.fillWidth: true }
            SettingGroup {
                title: "Contrast"
                Repeater {
                    model: [{label:"Text on background",fg:Theme.text,bg:Theme.base}, {label:"Hints on background",fg:Theme.subtext,bg:Theme.base}, {label:"Text on accent buttons",fg:Theme.crust,bg:Theme.accent}, {label:"Focus on cards",fg:Theme.accent,bg:Theme.surface0}]
                    RowLayout {
                        required property var modelData
                        readonly property real ratio: root.contrast(modelData.fg,modelData.bg)
                        Layout.fillWidth: true
                        Layout.topMargin: 6
                        Rectangle { width: 26; height: 19; radius: 3; color: modelData.bg; Label { anchors.centerIn: parent; text: "Aa"; color: modelData.fg; font.pixelSize: 10 } }
                        Label { text: modelData.label; color: Theme.subtext; font.pixelSize: 10; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                        Label { text: ratio.toFixed(1)+":1"; color: Theme.text; font.pixelSize: 10 }
                        Label { text: ratio>=7 ? "AAA" : ratio>=4.5 ? "AA" : "Low"; color: ratio>=4.5 ? Theme.success : Theme.warn; font.pixelSize: 10 }
                    }
                }
                Label { text: "AA ≥ 4.5:1 · AAA ≥ 7:1 for normal text"; color: Theme.subtext; font.pixelSize: 9; wrapMode: Text.WordWrap; Layout.fillWidth: true; Layout.topMargin: 10 }
            }
            SettingGroup {
                title: "Shape & surfaces"
                Field { title: "Shape"; kind: "choice"; value: { Theme.revision; return Store.value("theme:"+Theme.themeId,"shape","pill"); } choices: [{value:"pill",label:"Rounded"},{value:"square",label:"Square"}]; onEdited: next => Store.setThemeOption("shape",next) }
                Field { title: "Panel opacity"; kind: "slider"; minimum: 10; maximum: 100; unit: "%"; value: { Theme.revision; return Store.value("theme:"+Theme.themeId,"glass",.72)*100; } onEdited: next => Store.setThemeOption("glass",next/100) }
                Field { title: "Popup opacity"; kind: "slider"; minimum: 10; maximum: 100; unit: "%"; value: { Theme.revision; return Store.value("theme:"+Theme.themeId,"glassStrong",.88)*100; } onEdited: next => Store.setThemeOption("glassStrong",next/100) }
                Field { title: "Popup corners"; kind: "slider"; minimum: 0; maximum: 40; unit: " px"; value: { Theme.revision; return Store.value("theme:"+Theme.themeId,"radius.popup",22); } onEdited: next => Store.setThemeOption("radius.popup",next) }
                Field { title: "Control corners"; kind: "slider"; minimum: 0; maximum: 30; unit: " px"; value: { Theme.revision; return Store.value("theme:"+Theme.themeId,"radius.control",16); } onEdited: next => Store.setThemeOption("radius.control",next) }
                Field { title: "Colours from wallpaper"; kind: "bool"; value: { Theme.revision; return Store.value("appearance","fromWallpaper",false); } onEdited: next => Store.setValue("appearance","fromWallpaper",next) }
                Field { title: "Monochrome icons"; kind: "bool"; value: { Theme.revision; return Store.value("appearance","mono",false); } onEdited: next => Store.setValue("appearance","mono",next) }
            }
            Label { text: "Saving updates Abyssal, this app, the lock screen and TideWM’s included theme. GTK, Qt and terminal theme matching are still to be implemented."; color: Theme.subtext; font.pixelSize: 10; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        }
    }
}
