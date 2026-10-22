import QtQuick
import QtQuick.Layouts

SettingGroup {
    id: root
    property string documentId
    property var fields: []
    property int revision: 0
    Connections {
        target: Store
        function onChanged() {
            root.revision++;
        }
    }
    title: documentId.startsWith("theme:") ? "Surfaces & shape" : ({settings: "This app", appearance: "Theme behaviour", wallpaper: "Transitions", updates: "Update checks", notifications: "Notifications", idle: "Idle & lock", profile: "Your profile"})[documentId] || "Preferences"
    configSection: documentId
    Repeater {
        model: root.fields
        Field {
            required property var modelData
            objectName: modelData.key
            title: modelData.title
            hint: modelData.hint || ""
            kind: modelData.kind || "text"
            minimum: modelData.min === undefined ? 0 : modelData.min
            maximum: modelData.max === undefined ? 100 : modelData.max
            step: modelData.step || 1
            unit: modelData.unit || ""
            choices: modelData.choices || []
            value: {
                root.revision;
                const fallback = modelData.fallback === undefined ? "" : modelData.fallback;
                const v = root.documentId === "settings" ? Theme.setting(modelData.key, fallback) : Store.value(root.documentId, modelData.key, fallback);
                return modelData.scale ? v * modelData.scale : v;
            }
            onEdited: next => {
                Store.setValue(root.documentId, modelData.key, modelData.scale ? Math.round(next / modelData.scale) : next);
                if (root.documentId === "wallpaper") {
                    if (modelData.key === "transitionPreset" && next) {
                        const recipe = Store.transitions()[next];
                        if (recipe) {
                            Store.setValue("wallpaper", "transition", recipe.type);
                            Store.setValue("wallpaper", "transitionDuration", recipe.duration);
                        }
                    } else if (modelData.key === "transition")
                        Store.setValue("wallpaper", "transitionPreset", "");
                }
            }
        }
    }
}
